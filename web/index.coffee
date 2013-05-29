_ = require 'lib/underscore'

{parse} = require 'src/peg-parser/u-grammar'
{tokenize} = require 'src/lexer'
{compile, exec} = require 'src/compiler'

jQuery ($) ->
  $('#inp')
    .focus()
    .keypress (event) ->
      if String.fromCharCode(event.which) is "\r"
        uCode = $('#inp').val()
        if not uCode then return false
        $('#outp').text $('#outp').text() + '\n' + (
          try
            if /^\.t\b/.test uCode
              uCode = uCode[3...]
              tokenStream = tokenize uCode
              """
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
              repr exec uCode
          catch e
            e.stack
        )
        $(window).scrollTop $(document).height()
        false
      true

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
