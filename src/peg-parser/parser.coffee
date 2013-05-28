_ = require '../../lib/underscore'

{tokenize} = require '../lexer'

class @Peg
  constructor: ->
    @grammar = @getGrammar()

  parse: (code) ->
    @tokenStream = tokenize(code)
    @seq(@grammar.start, 'eof')()

  node = (key, value) ->
    result = {}
    result[key] = if value == true then null else value
    result

  ref: (rule, alias = null) ->
    =>
      parsed = @parseExpression @grammar.rules[rule]
      if parsed != false
        node(alias || rule, parsed)
      else
        false

  seq: ->
    expresssions = arguments
    =>
      result = []
      position = @tokenStream.getPosition()
      for expression in expresssions
        parsed = @parseExpression expression
        if parsed != false
          if parsed instanceof Object && !(parsed instanceof Array)
            result.push parsed
        else
          result = false
          @tokenStream.rollback(position)
          break
      if result
        _.extend({}, result...)
      else
        false

  optional: (expression) ->
    =>
      position = @tokenStream.getPosition()
      parsed = @parseExpression expression
      if parsed != false
        parsed
      else
        @tokenStream.rollback(position)
        true

  or: (expression1, expression2) ->
    =>
      result = @getParseResult expression1
      if result == false
        result = @getParseResult expression2
      result

  oneOrMore: (expression) ->
    =>
      r = @getParseResult expression
      if r != false
        result = [r]
        more = @zeroOrMore(expression)()
        if more
          result.concat more
        result
      else
        false

  zeroOrMore: (expression) ->
    =>
      while (r = @getParseResult expression) != false
        r

  getParseResult: (expression) ->
    position = @tokenStream.getPosition()
    parsed = @parseExpression expression
    if parsed != false
      parsed
    else
      @tokenStream.rollback(position)
      false

  parseExpression: (expression) ->
    if typeof expression == 'string'
      token = @tokenStream.next()
      if token.type == expression
        token.value
      else
        false
    else if typeof expression == 'function'
      expression()
    else if expression instanceof Array
      value = @parseExpression expression[1]
      if value != false
        node expression[0], value
      else
        false
    else
      throw 'Unknow expression type'
