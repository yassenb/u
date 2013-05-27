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
  ['-',         /^\s+/]          # whitespace
  ['-',         /^"[^a-z\{].*/i] # line comment
  ['-',         ///^             # block comment
                  "\{.*
                  (?: \s* (?: " | "[^\}].* | [^"].* ) [\n\r]+ )*
                  "\}.*          # TODO block comments can be nested
                ///]
  ['number',    /^\d+/]          # TODO floating point numbers
  ['string',    /^'\(('[^]|[^'\)])*\)/]
  ['string',    /^'[^\(]/]
  ['string',    /^"[a-z][a-z0-9]*/i]
  ['',          ///^(?:
                      ==
                    | \?\{
                    | @\{
                    | ::
                    | \+\+
                    | [\(\)\[\]\{\};_]
                )///]
  ['dollarConstant', /^\$(f|t|pinf|ninf|e|pi|np)?/]
  ['name',      /^[a-z][a-z0-9]*/i]
  ['name',      ///^(?:
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
  ['name',      /^[\+\-\*:\^=<>\/\\\.\#!%~\|,&]/]
]

# `line' and `col' point to where we are in the source code.
# A sentry 'eof' token is generated at the end.
@tokenize = (code, opts = {}) ->
  line = col = 1
  next: ->
    loop
      if not code then return {
        type: 'eof', value: '',
        startLine: line, startCol: col, endLine: line, endCol: col
      }
      startLine = line
      startCol = col
      type = null
      for [t, re] in tokenDefs when m = code.match re
        type = t or m[0]
        break
      if not type
        throw Error "Syntax error: unrecognized token at #{line}:#{col} " + code,
          file: opts.file
          line: line
          col: col
          code: opts.code
      a = m[0].split '\n'
      line += a.length - 1
      col = (if a.length is 1 then col else 1) + a[a.length - 1].length
      code = code.substring m[0].length
      if type isnt '-' then return {
        type, value: m[0],
        startLine, startCol, endLine: line, endCol: col
      }
