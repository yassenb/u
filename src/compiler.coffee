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
      '(' + (for child in node[1...] then '(' + renderJS(child) + ')').join(',') + ')'
    when '=='
      if node[1][0] isnt 'name'
        # [x;y]==[0;1]   ->   error 'Destructuring'
        throw Error 'Compiler error: Destructuring assignment is not implemented.'
      # a==1; a   ->   1
      nameToJS(node[1][1]) + '=' + renderJS node[2]
    when 'number'
      node[1]
    when 'name'
      nameToJS node[1]
    when 'expression'
      r = renderJS node[1]
      i = 2
      while i < node.length
        r = "(#{renderJS node[i]})([#{r},#{renderJS node[i + 1]}])"
        i += 2
      r
    when 'sequence'
      '[' + (for child in node[1...] then renderJS child).join(',') + ']'
    when 'conditional'
      # ?{1::2;3}   ->   2
      # ?{0::2;3}   ->   3
      # ?{0::2}     ->   $
      r = ''
      for [tokenType, condition, consequence] in node[1...-2]
        if tokenType isnt '::'
          throw Error 'Compiler error: expected "::" token as a child of "conditional", but found ' + JSON.stringify tokenType
        r += "(#{renderJS condition})?(#{renderJS consequence}):"
      [alternative, local] = node[-2...]
      r += if alternative then renderJS alternative else nameToJS '$'
      if local
        throw Error 'Not implemented: local clause within conditional'
      r
    else
      throw Error 'Compiler error: Unrecognised node type, ' + node[0]

nameToJS = (name) ->
  if /^[a-z_\$][a-z0-9_\$]*$/i.test name
    "ctx.#{name}"
  else
    "ctx[#{JSON.stringify name}]"
