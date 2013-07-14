{Peg} = require './parser'

class UGrammar extends Peg
  getGrammar: ->
    uGrammar = {
      rules: {
        program: @ref 'programBody'
        programBody: @oneOrMoreWithSep(['', @or(@ref('def'), @ref('expr'))], ';')
        def: @or ['assignment', @ref('assignment')],
                 @seq('{', ['assignments', @oneOrMoreWithSep(['', @ref('assignment')], ';')],
                      ['local', @ref('local')], '}')
        assignment: @seq ['pattern', @ref('pattern')], '==', ['expr', @ref('expr')]
        expr: @oneOrMoreWithSep(['argument', @ref('value')], ['operator', @ref('value')])
        value: @or(@ref('const'), @or('_', @or(@ref('sequence'), @or(@seq('(', ['', @ref('expr')], ')'),
                                                                     @ref('closure')))))
        sequence: @seq '[', ['', @zeroOrMoreWithSep(['', @ref('expr')], ';')], ']'
        closure: @or @ref('parametric'), @or(@ref('conditional'), @ref('function'))
        parametric: @seq '{', ['expr', @ref('expr')], ['local', @ref('local')], '}'
        conditional: @seq '?{',
          ['tests', @oneOrMoreWithSep(['', @seq(['condition', @ref('expr')], '::', ['expr', @ref('expr')])], ';')],
          @optional(@seq(';', ['else', @ref('expr')])), @optional(['local', @ref('local')]), '}'
        function: @seq '@{', ['clauses', @oneOrMoreWithSep(['', @ref('clause')], ';')],
          @optional(['local', @ref('local')]), '}'
        clause: @seq ['functionlhs', @ref('functionlhs')], '::', @optional(['body', @ref('expr')])
        functionlhs: @or ['guard', @ref('guard')],
                         @seq(@optional(['pattern', @ref('pattern')]), @optional(['guard', @ref('guard')]))
        guard: @seq('(', ['', @ref('expr')], ')')
        local: @seq '++', ['', @oneOrMoreWithSep(['', @ref('def')], ';')]
        const: @or @ref('number'), @or(@ref('string'), @or(@ref('name'), @ref('dollarConstant')))
        number: 'number'
        string: 'string'
        name: 'name'
        dollarConstant: 'dollarConstant'
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
      parsed = do @seq rule
      if parsed
        [parsed].concat do @zeroOrMore(@seq separator, rule)
      else
        zeroValue

@parse = (code) ->
  (new UGrammar).parse code
