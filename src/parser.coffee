#!/usr/bin/env coffee

lexer = require './lexer'

# The parser builds an AST from a stream of tokens.
#
# A node in the AST is a JavaScript array whose first item is a string
# indicating the type of node.  The rest of the items are either the children
# or they represent the content of a node.
#
# U's grammar is:
#
#     program = { ( expr | def ) ';' }
#     def = assignment | '{' { assignment ';' } local '}'
#     assignment = pattern '==' expr
#     expr = { value value }
#     value = name | const | '_' | row | '(' expr ')' | closure
#     row = '[' [{ expr ';' }] ']'
#     closure = parametric | conditional | function
#     parametric = '{' expr local '}'
#     conditional = '?{' { expr '::' expr ';' } [ ';' expr ] [ local ] '}'
#     function = '@{' { clause ';' } [ local ] '}'
#     clause = [ pattern ] ['(' expr ')'] '::' [ expr ]
#     local = '++' { def ';' }
#     const = number | string | funname | '$' | '$f' | '$t' | $pinf | $ninf | $e | $pi | $np
#     funname = '+' | '-' | '*' | ':' | '^' | '=' | '<' | '>' | '/' | '\' | '.' | '#'
#     | '!' | '%' | '~' | '|' | ',' | '&' | '<:' | '>:' | '|:'
#     | '=>' | '||' | '<=' | '>=' | '<>' | ',,' | '>>' | '<<' | '%%'
@parse = (code, opts = {}) ->
  tokenStream = lexer.tokenize code

  # A single-token lookahead is used.  Variable `token` stores the upcoming
  # token.
  token = tokenStream.next()

  # `consume(tt)` consumes the upcoming token and returns a truthy value only
  # if its type matches `tt`.  A space-separated value of `tt` matches any of
  # a set of token types.
  consume = (tt) ->
    if token.type in tt.split ' ' then token = tokenStream.next()

  # `demand(tt)` is like `consume(tt)` but intolerant to a mismatch.
  demand = (tt) ->
    if token.type isnt tt
      parserError "Expected token of type '#{tt}' but got '#{token.type}'"
    token = tokenStream.next()
    return

  parserError = (message) ->
    throw Error "Parser error: #{message} at #{token.startLine}:#{token.startCol}",
      file: opts.file
      line: token.startLine
      col: token.startCol
      code: code

  # The parser is a recursive descent parser.  Various `parseXXX()` functions
  # roughly correspond to the set of non-terminals.

  parseProgram = ->
    parseExpr() # todo

  parseExpr = ->
    r = ['expression', parseValue()].concat(
      while token.type not in [')', ']', '}', ';', '==', '::', '++', 'eof']
        parseValue()
    )
    if r.length is 2 then return r[1] else r

  parseValue = ->
    t = token
    if consume 'number string name _' then [t.type, t.value]
    else if consume '(' then (r = parseExpr(); demand ')'; r)
    else if consume '['
      r = ['sequence']
      if token.type isnt ']'
        r.push parseValue()
        while consume ';'
          r.push parseValue()
      demand ']'
      r
    else if consume '{'
      r = ['parametric', parseExpr(), parseLocal()]
      demand '}'
      r
    else if consume '?{'
      throw Error 'Not implemented'
    else if consume '@{'
      throw Error 'Not implemented'
    else
      parserError "Expected value but found #{t.type}"

  result = parseProgram()
  demand 'eof'
  result



if module is require.main then do =>
  console.info @parse '4*(1+2+3)-5+[6;7;[8];[];9]'
