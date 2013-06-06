{Peg} = require './parser'

class UGrammar extends Peg
  getGrammar: ->
    uGrammar = {
      rules: {
        program: ['program', @oneOrMoreWithSep(@or(@ref('def'), @ref('expr')), ';')]
        def: @or @ref('assignment'),
                 @seq('{', ['assignments', @oneOrMoreWithSep(@ref('assignment'), ';')], @ref('local'), '}')
        assignment: @seq @ref('pattern'), '==', @ref('expr')
        expr: @oneOrMoreWithSep(@ref('value', 'argument'), @ref('value', 'operator'))
        value: @or(@ref('const'), @or('_', @or(@ref('sequence'), @or(@seq('(', @ref('expr'), ')'), @ref('closure')))))
        sequence: @seq '[', ['elements', @zeroOrMoreWithSep(@ref('expr'), ';')], ']'
        closure: @or @ref('parametric'), @or(@ref('conditional'), @ref('function'))
        parametric: @seq '{', @ref('expr'), @ref('local'), '}'
        conditional: @seq '?{',
          ['tests', @oneOrMoreWithSep(@seq(['condition', @ref('expr')], '::', @ref('expr')), ';')],
          @optional(@seq(';', ['else', @ref('expr')])), @optional(@ref('local')), '}'
        function: @seq '@{', ['clauses', @oneOrMoreWithSep(@ref('clause'), ';')], @optional(@ref('local')), '}'
        clause: @seq @ref('functionlhs'), '::', @optional(['body', @ref('expr')])
        functionlhs: @or @ref('guard'), @seq(@optional(@ref('pattern')), @optional(@ref('guard')))
        guard: @seq('(', @ref('expr'), ')')
        local: @seq '++', ['defs', @oneOrMoreWithSep(@ref('def'), ';')]
        const: @or ['number', 'number'], @or(['string', 'string'], @or(['name', 'name'],
          ['dollarConstant', 'dollarConstant']))
        pattern: @ref('expr')
      }
    }
    uGrammar.start = uGrammar.rules.program
    uGrammar

  zeroOrMoreWithSep: (rule, separator) ->
    @someWithSep rule, separator, []

  oneOrMoreWithSep: (rule, separator) ->
    @someWithSep rule, separator, false

  someWithSep: (rule, separator, zeroValue) ->
    =>
      parsed = @getParseResult rule
      if parsed
        [parsed].concat @zeroOrMore(@seq separator, rule)()
      else
        zeroValue

@parse = (code) ->
  (new UGrammar).parse code
