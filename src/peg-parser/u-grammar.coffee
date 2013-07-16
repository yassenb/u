{Peg} = require './parser'

class UGrammar extends Peg
  getGrammar: ->
    start: program = @ref 'programBody'
    rules:
      program: program
      programBody: @oneOrMoreWithSep ['', @or(@ref('def'), @ref('expr'))], ';'
      def: @or ['assignment', @ref('assignment')],
               @seq('{', ['assignments', @oneOrMoreWithSep(['', @ref 'assignment'], ';')],
                    ['local', @ref('local')], '}')
      assignment: @seq ['pattern', @ref 'pattern'], '==', ['expr', @ref 'expr']
      expr: @oneOrMoreWithSep ['argument', @ref 'value'], ['operator', @ref 'value']
      value: @or @ref('number'), @ref('string'), @ref('name'), @ref('dollarConstant'),
                 @ref('parametric'), @ref('conditional'), @ref('function'),
                 '_', @ref('sequence'), @seq('(', ['', @ref 'expr'], ')'),
      sequence: @seq '[', ['', @zeroOrMoreWithSep(['', @ref 'expr'], ';')], ']'
      parametric: @seq '{', ['expr', @ref 'expr'], ['local', @ref 'local'], '}'
      conditional: @seq '?{',
        ['tests', @oneOrMoreWithSep(['', @seq(['condition', @ref 'expr'], '::', ['expr', @ref 'expr'])], ';')],
        @optional(@seq(';', ['else', @ref('expr')])), @optional(['local', @ref('local')]), '}'
      function: @seq '@{', ['clauses', @oneOrMoreWithSep(['', @ref 'clause'], ';')],
        @optional(['local', @ref 'local']), '}'
      clause: @seq ['functionlhs', @ref 'functionlhs'], '::', @optional(['body', @ref 'expr'])
      functionlhs: @or ['guard', @ref 'guard'],
                       @seq(@optional(['pattern', @ref 'pattern']), @optional(['guard', @ref 'guard']))
      guard: @seq '(', ['', @ref 'expr'], ')'
      local: @seq '++', ['', @oneOrMoreWithSep(['', @ref 'def'], ';')]
      number: 'number'
      string: 'string'
      name: 'name'
      dollarConstant: 'dollarConstant'
      pattern: @ref 'expr'

  zeroOrMoreWithSep: (rule, separator) ->
    @someWithSep rule, separator, []

  oneOrMoreWithSep: (rule, separator) ->
    @someWithSep rule, separator, false

  someWithSep: (rule, separator, zeroValue) ->
    =>
      parsed = do @seq rule
      if parsed
        [parsed].concat do @zeroOrMore @seq separator, rule
      else
        zeroValue

@parse = (code) ->
  (new UGrammar).parse code
