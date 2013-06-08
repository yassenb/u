_ = require '../lib/underscore'

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
  ['-',              /\s+/]          # whitespace
  ['-',              /"[^a-z\{].*/i] # line comment
  ['-',              /^#!.*/i]       # line comment
  ['-',              ///             # block comment
                       "\{.*
                       (?: \s* (?: " | "[^\}].* | [^"].* ) [\n\r]+ )*
                       "\}.*         # TODO block comments can be nested
                     ///]
  ['number',         /~?\d+(?:\.\d+)?/]
  ['string',         /'\(('[^]|[^'\)])*\)/]
  ['string',         /'[^\(]/]
  ['string',         /"[a-z][a-z0-9]*/i]
  ['',               ///(?:
                           ==
                         | \?\{
                         | @\{
                         | ::
                         | \+\+
                         | [\(\)\[\]\{\};_]
                     )///]
  ['dollarConstant', /\$[a-z]*/i]
  ['name',           /[a-z][a-z0-9]*/i]
  ['name',           ///(?:
                           <:
                         | >:
                         | \|:
                         | =>
                         | \|\|
                         | <=
                         | >=
                         | <>
                         | ,,
                         | >>
                         | <<
                         | %%
                     )///]
  ['name',           /[\+\-\*:\^=<>\/\\\.\#!%~\|,&]/]
  ['name',           /@+/]
]

# All regexes must match at the beginning of a string.
do ->
  for d in tokenDefs
    re = d[1]
    d[1] = new RegExp '^' + re.source, if re.ignoreCase then 'i'

# Converts source code into a token stream with look ahead capabilities. A token has:
#   type - string, number, etc.,
#   value - the piece of source code the token represents
#   startLine, startCol, endLine, endCol - the position of the token in the source file
@tokenize = (code, opts = {}) ->
  position = { line: 1, col: 1, code: code }

  # get the next token
  next: ->
    loop
      if position.code is ''
        return {
          type: 'eof', value: '',
          startLine: position.line, startCol: position.col, endLine: position.line, endCol: position.col
        }

      startLine = position.line
      startCol = position.col

      type = null
      for [t, re] in tokenDefs
        if match = position.code.match re
          type = t or match[0]
          break
      if not type
        throw Error "Syntax error: unrecognized token at #{position.line}:#{position.col} " + position.code,
          file: opts.file
          line: position.line
          col: position.col
          code: opts.code

      match = match[0]
      lines = match.split '\n'
      position.line += lines.length - 1
      position.col = (if lines.length is 1 then position.col else 1) + _(lines).last().length
      position.code = position.code.substr match.length
      if type isnt '-'
        return {
          type, value: match,
          startLine, startCol, endLine: position.line, endCol: position.col - 1
        }

  # returns the stream to the state of the call to `getPosition()' by which `pos' was obtained
  rollback: (pos) ->
    position.line = pos.line
    position.col  = pos.col
    position.code = pos.code

  # returns a position - something you can pass to `rollback(pos)' to restore to that position in the stream
  getPosition: ->
    line: position.line
    col:  position.col
    code: position.code
