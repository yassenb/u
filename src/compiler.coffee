{parse} = require './parser'

@compile = (uCode) ->
  renderJS parse code

@exec = (uCode) ->
  (new Function "return #{compile uCode};")()

renderJS (node) ->
  switch node[0]
    when 'number'
      node[1]
    when 'name'
      node[1].replace /[^a-z0-9\$]/i, (x) ->
        ('000' + x.charCodeAt(0).toString(16))[-4...]
    when 'expr'
      r = renderJS node[1]
      i = 2
      while i < node.length
        r = "(#{renderJS node[i]})([#{r}].concat(#{renderJS node[i + 1]}))"
      r
