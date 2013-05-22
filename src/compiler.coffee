{parse} = require './parser'
stdlib = require './stdlib'

@exec = (uCode) ->
  (new Function """
    var ctx = arguments[0];
    return #{compile uCode};
  """) stdlib

@compile = compile = (uCode) ->
  renderJS parse uCode

renderJS = (node) ->
  switch node[0]
    when 'number'
      node[1]
    when 'name'
      name = node[1]
      if /^[a-z_\$][a-z0-9_\$]*$/i.test name
        "ctx.#{name}"
      else
        "ctx[#{JSON.stringify name}]"
    when 'expression'
      r = renderJS node[1]
      i = 2
      while i < node.length
        r = "(#{renderJS node[i]})([#{r}].concat(#{renderJS node[i + 1]}))"
        i += 2
      r
    when 'sequence'
      '[' + (for child in node[1...] then renderJS child).join(',') + ']'
    when 'conditional'
      r = ''
      for [tokenType, condition, consequence] in node[1...-2]
        if tokenType isnt '::'
          throw Error 'Compiler error: expected "::" token as a child of "conditional", but found ' + JSON.stringify tokenType
        r += "(#{renderJS condition})?(#{renderJS consequence}):"
      [alternative, local] = node[-2...]
      r += if alternative then renderJS alternative else '$'
      if local
        throw Error 'Not implemented: local clause within conditional'
      r
    else
      throw Error 'Compiler error: Unrecognised node type, ' + node[0]
