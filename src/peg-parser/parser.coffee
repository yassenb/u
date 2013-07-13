_ = require '../../lib/underscore'

{tokenize} = require '../lexer'

class Node
  constructor: (@type, @value) ->

class @Peg
  constructor: ->
    @grammar = @getGrammar()

  parse: (code) ->
    @tokenStream = tokenize code
    result = do @seq ['start', @grammar.start], 'eof'
    if result isnt false then result.start else result

  ref: (rule) ->
    =>
      parsed = @parseExpression @grammar.rules[rule]
      if parsed isnt false
        new Node(rule, parsed)
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
          if parsed instanceof Object and
              parsed not instanceof Node and
              parsed not instanceof Array
            result.push parsed
        else
          result = false
          @tokenStream.rollback position
          break
      if result
        if result.length is 1 and result[0]['']?
          result[0]['']
        else
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
        null

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
          result.concat more
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
        result = {}
        result[expression[0]] = value
        result
      else
        false
    else
      throw Error 'Unknown expression type'
