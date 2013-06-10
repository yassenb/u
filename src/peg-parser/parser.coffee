_ = require '../../lib/underscore'

{tokenize} = require '../lexer'

class @Peg
  constructor: ->
    @grammar = @getGrammar()

  parse: (code) ->
    @tokenStream = tokenize code
    do @seq @grammar.start, 'eof'

  node = (key, value) ->
    result = {}
    result[key] = if value is true then null else value
    result

  ref: (rule, alias = null) ->
    =>
      parsed = @parseExpression @grammar.rules[rule]
      if parsed isnt false
        node(alias or rule, parsed)
      else
        false

  seq: ->
    expressions = arguments
    =>
      result = []
      position = @tokenStream.getPosition()
      for expression in expressions
        parsed = @parseExpression expression
        if parsed isnt false
          if parsed instanceof Object and parsed not instanceof Array
            result.push parsed
        else
          result = false
          @tokenStream.rollback position
          break
      if result
        _.extend {}, result...
      else
        false

  optional: (expression) ->
    =>
      position = @tokenStream.getPosition()
      parsed = @parseExpression expression
      if parsed isnt false
        parsed
      else
        @tokenStream.rollback position
        true

  or: (expression1, expression2) ->
    =>
      result = @getParseResult expression1
      if result is false
        result = @getParseResult expression2
      result

  oneOrMore: (expression) ->
    =>
      r = @getParseResult expression
      if r isnt false
        result = [r]
        more = do @zeroOrMore expression
        if more
          result.concat more # TODO Bug? This line has no effect.
        result
      else
        false

  zeroOrMore: (expression) ->
    =>
      while (r = @getParseResult expression) isnt false
        r

  getParseResult: (expression) ->
    position = @tokenStream.getPosition()
    parsed = @parseExpression expression
    if parsed isnt false
      parsed
    else
      @tokenStream.rollback position
      false

  parseExpression: (expression) ->
    if typeof expression is 'string'
      token = @tokenStream.next()
      if token.type is expression
        token.value
      else
        false
    else if typeof expression is 'function'
      expression()
    else if expression instanceof Array
      value = @parseExpression expression[1]
      if value isnt false
        node expression[0], value
      else
        false
    else
      throw Error 'Unknown expression type'
