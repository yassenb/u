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
    when 'name'
      # a   ->   a
      nameToJS node[1]
    when 'expression'
      # 2 + 3 4               ->   error 'Invalid expression'
      if node.length % 2 != 0
        throw Error 'Invalid expression'
      # 2 + 3 + 4             ->   9
      # 2 + 3 @{ x :: 7 } 4   ->   7
      r = renderJS node[1]
      i = 2
      while i < node.length
        r = "(#{renderJS node[i]})([#{r},#{renderJS node[i + 1]}])"
        i += 2
      r
    when 'sequence'
      # + . [1;2]   ->   3
      "[#{node[1...].map(renderJS).join(',')}]"
    when 'conditional'
      # ?{1::2;3}   ->   2
      # ?{0::2;3}   ->   3
      # ?{0::2}     ->   $
      # TODO negative test cases
      r = ''
      for [tokenType, condition, consequence] in node[1...-2]
        if tokenType isnt '::'
          throw Error 'Compiler error: expected "::" token as a child of "conditional", but found ' +
            JSON.stringify tokenType
        r += "(#{renderJS condition})?(#{renderJS consequence}):"
      [alternative, local] = node[-2...]
      r += if alternative then renderJS alternative else nameToJS '$'

      if local
        throw Error 'Not implemented: local clause within conditional'

      r
    when 'function'
      # (@{a (1) :: a+2}).3         ->   5
      # (@{a :: a+2}).3             ->   5
      # (@{(1) :: 123}).3           ->   123
      # (@{1 :: 123}).3             ->   error ''
      # (@{:: 123}).3               ->   123
      # @{a}                        ->   error ''
      # (@{a (0) :: a+2; :: 6}).3   ->   6
      body = ''
      for [_0, pattern, guard, result] in node[1...-1]
        if pattern
          if pattern[0] isnt 'name'
            throw Error 'Only the simplest form of patterns are supported---names'
          body += nameToJS(pattern[0][1]) + ' = arg;\n'
        returnStatement = "return #{if result then renderJS result else nameToJS '$'};"
        if guard
          returnStatement = "if (#{renderJS guard}) {\n#{returnStatement}\n}"
        body += returnStatement
      if local
        throw Error 'Not implemented: local clause within function'
      r = "helpers.createLambda(ctx, function (arg, ctx) {\n
        #{body}\n
        return #{nameToJS '$'};\n
      })"
    else
      throw Error 'Compiler error: Unrecognised node type, ' + node[0]

nameToJS = (name) ->
  if /^[a-z_\$][a-z0-9_\$]*$/i.test name
    "ctx.#{name}"
  else
    "ctx[#{JSON.stringify name}]"
