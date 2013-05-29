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
        sequence: @seq '[', ['elements', @optional(@oneOrMoreWithSep(@ref('expr'), ';'))], ']'
        closure: @or @ref('parametric'), @or(@ref('conditional'), @ref('function'))
        parametric: @seq '{', @ref('expr'), @ref('local'), '}'
        conditional: @seq('?{', ['tests', @oneOrMoreWithSep(@seq(@ref('expr', 'condition'), '::', @ref('expr')), ';')],
          @optional(@seq(';', @ref('expr', 'else'))), @optional(@ref('local')), '}')
        function: @seq '@{', ['clauses', @oneOrMoreWithSep(@ref('clause'), ';')], @optional(@ref('local')), '}'
        clause: @seq @optional(@ref('pattern')), @optional(@seq('(', @ref('expr', 'guard'), ')')), '::',
                     @optional(@ref('expr'))
        local: @seq '++', ['defs', @oneOrMoreWithSep(@ref('def'), ';')]
        const: @or ['number', 'number'], @or(['string', 'string'], ['name', 'name'])
        # TODO
        pattern: @ref('const')
      }
    }
    uGrammar.start = uGrammar.rules.program
    uGrammar

  oneOrMoreWithSep: (rule, separator) ->
    =>
      parsed = @getParseResult rule
      if parsed
        [parsed].concat @zeroOrMore(@seq separator, rule)()
      else
        false

@parse = (code) ->
  (new UGrammar).parse code
