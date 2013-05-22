{parse} = require './parser'

@exec = (uCode) ->
  (new Function "return #{compile uCode};")()

@compile = compile = (uCode) ->
  renderJS parse uCode

renderJS = (node) ->
  switch node[0]
    when 'number'
      node[1]
    when 'name'
      node[1].replace /[^a-z0-9\$]/i, (x) ->
        '_' + ('000' + x.charCodeAt(0).toString(16))[-4...] # render as four hex digits
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
