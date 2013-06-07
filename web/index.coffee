_ = require 'lib/underscore'

{parse} = require 'src/peg-parser/u-grammar'
{tokenize} = require 'src/lexer'
{compile, exec} = require 'src/compiler'

jQuery ($) ->

  # Autofocus fallback, see http://diveintohtml5.info/forms.html
  if 'autofocus' not of document.createElement 'input'
    $('#inp').focus()

  $('#inp')
    .inputHistory
      enter: ->
        inputLine = $('#inp').val()
        if not inputLine then return
        if m = inputLine.match /^\s*(\.\w+)\s+(.*)$/
          [_0, command, uCode] = m
        else
          [command, uCode] = ['', inputLine]
        $('#outp').append $('<div class="inputLine"/>').text '>>> ' + inputLine
        try
          switch command
            when ''
              $('#outp').append $('<div class="result"/>').text repr exec uCode
            when '.t'
              tokenStream = tokenize uCode
              $('#outp').append $('<div class="tokens"/>').text """
                Tokens for #{JSON.stringify uCode}:
                  type      value               startLine:startCol-endLine:endCol
                  ----      -----               ---------------------------------
                  #{
                    (
                      while (t = tokenStream.next()).type isnt 'eof'
                        pad(10, t.type) +
                          pad(20, JSON.stringify t.value) +
                          t.startLine + ':' + t.startCol + '-' +
                          t.endLine + ':' + t.endCol
                    ).join '\n  '
                  }
              """
            when '.a'
              $('#outp').append $('<div class="ast"/>').text """
                AST for #{JSON.stringify uCode}:
                #{renderAST parse uCode}
              """
            when '.c'
              $('#outp').append $('<div class="js"/>').text """
                Compiled JavaScript for #{JSON.stringify uCode}:
                #{compile uCode}
              """
            else
              $('#outp').append $('<div class="error"/>').text 'Unrecognised command, ' + repr command
        catch e
          $('#outp').append $('<div class="error"/>').text e.stack
        $(window).scrollTop $(document).height()

renderAST = (node, indent = '') ->
  indent +
    if typeof node is 'string'
      JSON.stringify node
    else if node instanceof Array
      nodes = _(node).map (n) ->
        renderAST n, indent + '  '
      """
        [
        #{nodes.join '\n'}
        #{indent}]
      """
    else
      result = for k, v of node
        """
          #{k}:
          #{renderAST(v, indent + '  ')}
        """
      result.join('\n' + indent)

# repr(x) gives a string representation of U's data structures.
# Function objects are rendered as "@{...}"
# Some distinguished constants are rendered as their names.
repr = (x) ->
  if x instanceof Array then "[#{(for y in x then repr y).join ';'}]" # TODO: use underscore.js
  else if typeof x is 'number'
    if x is Infinity then '$pinf'
    else if x is -Infinity then '$ninf'
    else '' + x
  else if typeof x is 'boolean' then '$' + 'ft'[+x]
  else if typeof x is 'function' then '@{...}'
  else if typeof x is 'string'
    h = '\n': "'n", '\t': "'t", ')': "')", "'": "''"
    "'(#{x.replace /[\n\t\)']/g, (x) -> h[x]})"
  else if x is null then '$'
  else '' + x # TODO: strings and figures

# Helper functions to format tabular data
pad = (width, s) -> s + repeat ' ', Math.max 0, width - s.length
repeat = (s, n) -> Array(n + 1).join s
