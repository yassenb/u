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
    else
      throw Error 'Compiler error: Unrecognised node type, ' + node[0]
