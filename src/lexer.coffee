_ = require '../lib/underscore'

# TODO do we want unicode support?
# The lexer transforms source code into a stream of tokens.
#
# It does so by trying to match regular expressions at the current source
# position and forming a token from the first one that succeeds.
#
# Some token types are special:
#
#   * '-' is used for ignored tokens—comments and whitespace
#
#   * '' means that the token's type should be the same as its value
tokenDefs = [
  ['-',              ///
                          \s+          # whitespace
                        | "[^a-z\{].*  # line comment
                        | \#!.*        # line comment
                        |              # block comment
                           "\{.*
                           (?: \s* (?: " | "[^\}].* | [^"].* ) [\n\r]+ )*
                           "\}.*       # TODO block comments can be nested
                     ///i]
  ['number',         /~?\d+(?:\.\d+)?/]
  ['string',         ///
                          '\(('[^]|[^'\)])*\)
                        | '[^\(]
                        | "[a-z][a-z0-9]*
                     ///i]
  ['',               ///
                           ==
                         | \?\{
                         | @\{
                         | ::
                         | \+\+
                         | [\(\)\[\]\{\};_]
                     ///]
  ['dollarConstant', /\$[a-z]*/i]
  ['name',           ///
                          [a-z][a-z0-9]*
                         | <: | >: | \|: | => | \|\| | <= | >= | <> | ,, | >> | << | %%
                         | [\+\-\*:\^=<>\/\\\.\#!%~\|,&]
                         | @+
                     ///i]
]

# All regexes must match at the beginning of a string.
do ->
  for d in tokenDefs
    re = d[1]
    d[1] = new RegExp "^(?:#{re.source})", if re.ignoreCase then 'i'

# Converts source code into a token stream with look ahead capabilities. A token has:
#   type - string, number, etc.,
#   value - the piece of source code the token represents
#   startLine, startCol, endLine, endCol - the position of the token in the source file
@tokenize = (code, opts = {}) ->
  line = col = 1
  tokens = []
  while code isnt ''
    startLine = line
    startCol = col

    type = null
    for [t, re] in tokenDefs
      if match = code.match re
        type = t or match[0]
        break
    unless type
      throw Error "Syntax error: unrecognized token at #{line}:#{col} " + code,
        file: opts.file
        line: line
        col: col
        code: opts.code

    match = match[0]
    lines = match.split '\n'
    line += lines.length - 1
    col = (if lines.length is 1 then col else 1) + _(lines).last().length
    code = code.substr match.length
    if type isnt '-'
      tokens.push {
        type, value: match,
        startLine, startCol, endLine: line, endCol: col - 1
      }

  tokens.push {
    type: 'eof', value: '',
    startLine: line, startCol: col, endLine: line, endCol: col
  }

  i = 0

  {
    # get the next token
    next: ->
      tokens[i++]

    # returns the stream to the state of the call to `getPosition()' by which `pos' was obtained
    rollback: (pos) ->
      i = pos

    # returns a position - something you can pass to `rollback(pos)' to restore to that position in the stream
    getPosition: ->
      i
  }
