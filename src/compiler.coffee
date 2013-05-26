_ = require '../lib/underscore'

{parse} = require './parser'
stdlib = require './stdlib'
helpers = require './helpers'

@exec = (uCode) ->
  (new Function """
    var ctx     = arguments[0],
        helpers = arguments[1];
    return #{compile uCode};
  """) stdlib, helpers

@compile = compile = (uCode) ->
  renderJS parse uCode

renderJS = (node) ->
  switch node[0]
    when 'program'
      # 1;2;3   ->   3
      statements = _(node[1...]).map (child) ->
        "(#{renderJS(child)})"
      "(#{statements.join(',')})"
    when '=='
      # [x;y]==[0;1]   ->   error 'Destructuring'
      if node[1][0] isnt 'name'
        # TODO left hand side can be a complex expression that is not a pattern, a different error should be produced
        # in such case
        throw Error 'Compiler error: Destructuring assignment is not implemented.'
      # a==1; a     ->   1
      # a==2+1; a   ->   3
      nameToJS(node[1][1]) + '=' + renderJS node[2]
    when 'number'
      # 5   ->   5
      node[1]
    when 'string'
      s = node[1]
      JSON.stringify(
        if /^'\(/.test s
          # '(')rock''n'roll)   ->   '(')rock''n'roll)
          # '(()                ->   '(()
          h = n: '\n', t: '\t', ')': ')', "'": "'", '\n': ''
          s[2...-1].replace /'['tn\n]/g, (x) -> h[x[1]]
        else
          # 'a                  ->   '(a)
          # "Toledo             ->   '(Toledo)
          s[1...]
      )
    when 'name'
      # a   ->   a
      nameToJS node[1]
    when 'expression'
      # 2 + 3 4               ->   error 'Invalid expression'
      if node.length % 2 != 0
        throw Error 'Invalid expression'

      # 2 + 3 + 4             ->   9
      # 2 + 3 @{ x :: 7 } 4   ->   7
      if node[1][0] is '_'
        # Initial "_" must be treated differently from subsequent "_"-s.
        # The first three children of our node will be knit together using curryRight().
        if node.length is 2
          throw Error 'A single underscore cannot be used as an expression.'
        if node[3][0] is '_'
          # _+_   ->   +
          r = renderJS node[2] # currying on both sides returns the function itself
        else
          # (_+1).2   ->   3
          r = "helpers.curryRight(#{renderJS node[2]},#{renderJS node[3]})"
        i = 4
      else
        r = renderJS node[1]
        i = 2

      while i < node.length
        if node[i + 1][0] is '_'
          # (1+_).2   ->   3
          r = "helpers.curryLeft(#{renderJS node[i]}, #{r})"
        else
          r = "(#{renderJS node[i]})([#{r},#{renderJS node[i + 1]}])"
        i += 2
      r
    when 'sequence'
      # + . [1;2]   ->   3
      "[#{_(node[1...]).map(renderJS).join(',')}]"
    when 'conditional'
      # ?{1::2;3}   ->   2
      # ?{0::2;3}   ->   3
      # ?{0::2}     ->   $
      # TODO negative test cases
      # ?{$f::2;$t::3;4}   ->   3
      # ?{x::2;y::3;4 ++ x==$f; y==$t}   ->   3
      r = ''
      for [tokenType, condition, consequence] in node[1...-2]
        if tokenType isnt '::'
          throw Error 'Compiler error: expected "::" token as a child of "conditional", but found ' +
            JSON.stringify tokenType
        r += "(#{renderJS condition})?(#{renderJS consequence}):"
      [alternative, local] = node[-2...]
      r += if alternative then renderJS alternative else nameToJS '$'
      if local
        """
          helpers.createLambda(ctx, function (_ignored, ctx) {
            #{renderJS local}
            return #{r};
          })()
        """
      else
        r
    when 'function'
      # @{:: 123} . 3                   ->   123
      # @{a :: a+2} . 3                 ->   5
      # x==5; @{:: x} . $               ->   5
      # x==5; f==@{:: x}; x==6; f . x   ->   6
      # TODO test that creating a new function creates a new context
      # @{1 :: 123} . 3                 ->   error 'Only the simplest form of patterns are supported'
      body = ''
      for [_0, pattern, guard, result] in node[1...-1]
        if pattern
          if pattern[0] isnt 'name'
            throw Error 'Only the simplest form of patterns are supported---names'
          body += nameToJS(pattern[1]) + ' = arg;\n'
        returnStatement = "return #{if result then renderJS result else nameToJS '$'};"
        if guard
          # @{a (1) :: a+2} . 3         ->   5
          # @{(1) :: 123} . 3           ->   123
          # @{a (0) :: a+2; :: 6} . 3   ->   6
          returnStatement = """
            if (#{renderJS guard}) {
                #{returnStatement}
            }
          """
        body += returnStatement
      if local
        throw Error 'Not implemented: local clause within function'
      r = """
        helpers.createLambda(ctx, function (arg, ctx) {
            #{body}
            return #{nameToJS '$'};
        })
      """
    when 'local'
      (
        for child in node[1...]
          if child[0] isnt '=='
            throw Error 'Compiler error: Only "==" nodes (assignments) are supported inside a local.'
          pattern = child[1]
          if pattern[0] isnt 'name'
            throw Error 'Only the simplest form of patterns are supported---names'
          name = pattern[1]
          expr = child[2]
          "#{nameToJS name} = #{renderJS expr};\n"
      ).join ''
    when '_'
      # 1 _ 1   ->   error 'currying'
      throw Error 'Invalid currying'
    else
      throw Error 'Compiler error: Unrecognised node type, ' + node[0]

nameToJS = (name) ->
  if /^[a-z_\$][a-z0-9_\$]*$/i.test name
    "ctx.#{name}"
  else
    "ctx[#{JSON.stringify name}]"
