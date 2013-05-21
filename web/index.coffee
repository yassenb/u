{parse} = require 'parser'
{tokenize} = require 'lexer'
{compile, exec} = require 'compiler'

jQuery ($) ->
  $('#inp')
    .focus()
    .keypress (event) ->
      if event.keyCode is 13
        uCode = $('#inp').val()
        if not uCode then return false
        $('#outp').text $('#outp').text() + '\n' + (
          try
            if /^\.t\b/.test uCode
              uCode = uCode[3...]
              tokenStream = tokenize uCode
              "Tokens for #{JSON.stringify uCode}:\n  #{
                (
                  while (t = tokenStream.next()).type isnt 'eof'
                    JSON.stringify t
                ).join '\n  '
              }"
            else if /^\.a\b/.test uCode
              uCode = uCode[3...]
              "AST for #{JSON.stringify uCode}:\n#{
                renderAST parse uCode
              }"
            else if /^\.c\b/.test uCode
              uCode = uCode[3...]
              "Compiled JavaScript for #{JSON.stringify uCode}:\n#{
                compile uCode
              }"
            else
              exec uCode
          catch e
            e.stack
        )
        $(window).scrollTop $(document).height()
        false
      true

renderAST = (node, indent = '  ') ->
  if node.length is 2 and typeof node[1] is 'string'
    indent + node[0] + ' ' + JSON.stringify node[1]
  else
    indent + node[0] + '\n' + (
      for child in node[1...]
        renderAST child, indent + '  '
    ).join '\n'
