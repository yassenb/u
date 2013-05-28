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
      # [x;y]==[1;2]; x+y   ->   3
      # a==1; a             ->   1
      # a==2+1; a           ->   3
      renderPatternJS node[1], renderJS node[2]
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
      r += if alternative then renderJS alternative else 'null'
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
      # @{x :: x+y ++ y==1} . 2         ->   3
      # TODO a missing pattern or guard must default to the previous clause
      # TODO a missing result must default to the next clause
      body = ''
      for [_0, pattern, guard, result] in node[1...-1]
        if pattern
          # TODO use renderPatternJS() to compile the pattern
          if pattern[0] isnt 'name'
            throw Error 'Only the simplest form of patterns are supported---names'
          body += nameToJS(pattern[1]) + ' = arg;\n'
        returnStatement = "return #{if result then renderJS result else 'null'};"
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
      local = node[node.length - 1]
      r = """
        helpers.createLambda(ctx, function (arg, ctx) {
            #{if local then renderJS local else ''}
            #{body}
            return null;
        })
      """
    when 'local'
      # TODO use renderPatternJS() to compile the patterns
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
    when 'dollarConstant'
      switch node[1]
        when '$'     then 'null'
        when '$f'    then 'false'
        when '$t'    then 'true'
        when '$pinf' then 'Infinity'
        when '$ninf' then '(-Infinity)'
        when '$e'    then 'Math.E'
        when '$pi'   then 'Math.PI'
        when '$np'   then throw Error '$np is not implemented' # TODO
        else throw Error 'Unrecognised constant, ' + JSON.stringify node[1]
    else
      throw Error 'Compiler error: Unrecognised node type, ' + node[0]

nameToJS = (name) ->
  if /^[a-z_\$][a-z0-9_\$]*$/i.test name
    "ctx.#{name}"
  else
    "ctx[#{JSON.stringify name}]"

# renderPatternJS() builds a JavaScript expression that evaluates to true when
# the pattern is matched.  As a side effect during its evaluation, the
# expression may associate names with values in the current context.
renderPatternJS = (node, valueJS) ->
  if node[0] is '_'
    # _==1; $   ->   $
    'true'
  else if node[0] is 'name'
    # a==1; a+a   ->   2
    "#{nameToJS node[1]}=(#{valueJS}),true"
  else if node[0] in ['number', 'string', 'dollarConstant']
    # [a;1]==[2;1]; a      ->   2
    # ['a;a]==['a;'b]; a   ->   'b
    # [$t;$f;$pinf;$;a]==[$t;$f;$pinf;$;[1;2;3]]; a   ->   [1;2;3]
    "#{valueJS}===(#{renderJS node})"
  else if !/^[a-z][a-z\d\.]*(\[\d+\])*$/i.test valueJS
    # The rest of our node type options use valueJS at least twice in the
    # compiled code.  So, unless valueJS is really simple, we wrap the code in
    # a closure to prevent double computation.
    """
      (function (v) {
        return #{renderPatternJS node, 'v'};
      }(#{valueJS}))
    """
  else if node[0] is 'sequence'
    # [x;[y;z]]==[1;[2;3]]; x+y+z   ->   6
    r = "#{valueJS} instanceof Array"
    r += " && #{valueJS}.length===#{node.length - 1}"
    for child, i in node[1...]
      r += " && (#{renderPatternJS child, "#{valueJS}[#{i}]"})"
    r
  else if node[0] is 'expression'
    if node.length % 2
      # x / y z == [1;2;3]   ->   error 'number of items'
      throw Error 'Invalid pattern, expressions must consist of an odd number of items'
    else if node.length is 2
      renderPatternJS node[1], valueJS
    else
      # We apply only the last operation and invoke renderPatternJS recursively.
      leftArgNode  = node[...-2]
      opNode       = node[node.length - 2]
      rightArgNode = node[node.length - 1]
      if opNode[0] isnt 'name'
        # x (_/_) y == [1;2;3]   ->   error 'simple functions'
        throw Error 'Invalid pattern, only simple functions are allowed'
      switch opNode[1]
        when '\\'
          # x\y==[1;2;3]; x           ->   1
          # x\y==[1;2;3]; y           ->   [2;3]
          # x\(y\z)==[1;2;3]; x       ->   1
          # x\(y\z)==[1;2;3]; y       ->   2
          # x\(y\z)==[1;2;3]; z       ->   [3]
          # x\y\z==[[1;2];3]; x       ->   1
          # x\y\z==[[1;2];3]; y       ->   [2]
          # x\y\z==[[1;2];3]; z       ->   [3]
          # x\y==[1]; x               ->   1
          # x\y==[1]; y               ->   []
          """
            #{valueJS} instanceof Array &&
            #{valueJS}.length &&
            (#{renderPatternJS leftArgNode, valueJS + '[0]'}) &&
            (#{renderPatternJS rightArgNode, valueJS + '.slice(1)'})
          """
        when '/'
          # x/y==[1;2]; x       ->   [1]
          # x/y==[1;2]; y       ->   2
          # x/y/z==[1;2;3]; x   ->   [1]
          # x/y/z==[1;2;3]; y   ->   2
          # x/y/z==[1;2;3]; z   ->   3
          # x\y/z==[1;2;3]; x   ->   1
          # x\y/z==[1;2;3]; y   ->   [2]
          # x\y/z==[1;2;3]; z   ->   3
          """
            #{valueJS} instanceof Array &&
            #{valueJS}.length &&
            (#{renderPatternJS leftArgNode, valueJS + '.slice(0,-1)'}) &&
            (#{renderPatternJS rightArgNode, "#{valueJS}[#{valueJS}.length - 1]"})
          """
        else
          # x+y==3   ->   error 'obverse'
          throw Error "Invalid pattern, we don't know how to compile the obverse of #{JSON.stringify node[1]}"
  else
    # ?{x::y;z}==123   ->   error 'Invalid pattern'
    throw Error "Invalid pattern, encountered node of type #{JSON.stringify node[0]}"
