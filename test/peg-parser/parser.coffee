mockit = require 'mockit'

{Peg} = mockit '../../src/peg-parser/parser', {
  '../lexer': { tokenize: (tokens) ->
    index = 0
    next: ->
      token = ['eof', '']
      if index < tokens.length
        token = tokens[index]
        ++index
      { type: token[0], value: token[1] }
    getPosition: ->
      index
    rollback: (i) ->
      index = i
  }
}

class TestGrammar extends Peg
  getGrammar: ->
    grammar = { rules: @getTestGrammar() }
    grammar.start = grammar.rules.start
    grammar

describe 'Peg', ->
  describe '#parse()', ->
    simpleGrammar = class extends TestGrammar
      getTestGrammar: -> {
        start: ['var', 't1']
      }

    it 'parses the simplest grammar constructing an AST with one node', ->
      assertParse simpleGrammar, [
        [[['t1', 'x']], { var: 'x' }]
      ]

    # TODO it should throw when the source can't be parsed and return false when an empty AST is constructed
    it 'returns false when the source can\'t be parsed', ->
      assertParse simpleGrammar, [
        [[['t2', 'x']], false]
      ]

  describe '#ref()', ->
    it 'allows referencing other rules', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @ref 'var'
          var: 't1'
        }
      assertParse grammar, [
        [[['t1', 'x']], { type: 'var', value: 'x' }]
      ]

  describe '#seq()', ->
    it 'constructs a hash with only the explicitly named parts', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @seq @ref('def'), '=', ['val', 't2'], @zeroOrMore(';')
          def: 't1'
        }
      assertParse grammar, [
        [[['t1', 'x'], ['=', 'equal'], ['t2', 6], [';', 'column']], { val: 6 }]
      ]

    it 'constructs an AST node when there is only one named element in the sequence with the name \'\'', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @seq ['', @ref('var')]
          var: 't1'
        }
      assertParse grammar, [
        [[['t1', 'x']], { type: 'var', value: 'x' }]
      ]

    it 'constructs an empty hash when there are no named elements in the sequence', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @ref 'def'
          def: @seq 't1', '=', 't2', ';'
        }
      assertParse grammar, [
        [[['t1', 'x'], ['=', 'equal'], ['t2', 6], [';', 'column']], { type: 'def', value: {} }]
      ]

    it 'parses only when the whole sequence matches', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @or @ref('alt1'), @ref('alt2')
          alt1: @seq 'a', 'b', 'c'
          alt2: @seq 'a', 'b', 'd'
        }
      assertParse grammar, [
        [[['a', ''], ['b', ''], ['c', '']], { type: 'alt1', value: {} }]
        [[['a', ''], ['b', ''], ['d', '']], { type: 'alt2', value: {} }]
        [[['a', ''], ['b', ''], ['e', '']], false]
      ]

  describe '#optional()', ->
    it 'may or may not match', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @seq(['a', 'a'], ['b', @optional('b')], ['c', 'c'])
        }
      assertParse grammar, [
        [[['a', 1], ['c', 2]], { a: 1, b: null, c: 2 }]
        [[['a', 1], ['b', 2], ['c', 3]], { a: 1, b: 2, c: 3 }]
      ]

    it 'produces a node even when it doesn\'t match', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @seq 't1', ['opt', @ref('opt')], 't1'
          opt: @optional('t2')
        }
      assertParse grammar, [
        [[['t1', ''], ['t1', '']], { opt: { type: 'opt', value: null } }]
      ]

  describe '#or()', ->
    it 'matches if any of the two options match', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @or 't1', 't2'
        }
      assertParse grammar, [
        [[['t1', 5]], 5]
        [[['t2', 6]], 6]
      ]

    it 'provides an ordered choice', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @or ['first', @seq @seq('t1', 't1', 't1'), @seq('t1')],
                     ['second', @seq @seq('t1', 't1'), @seq('t1', 't1')]
        }
      assertParse grammar, [
        [[['t1', ''], ['t1', ''], ['t1', ''], ['t1', '']], { first: {} }]
      ]

  describe '#zeroOrMore()', ->
    grammar = class extends TestGrammar
      getTestGrammar: -> {
        start: @seq ['ones', @zeroOrMore(['one', 't1'])], ['last', 't2']
      }

    it 'matches on zero', ->
      assertParse grammar, [
        [[['t2', 'l']], { ones: [], last: 'l' }]
      ]

    it 'matches on more', ->
      assertParse grammar, [
        [[['t1', 1], ['t1', 2], ['t2', 'l']], { ones: [{ one: 1 }, { one: 2 }], last: 'l' }]
      ]

    it 'is greedy', ->
      grammar = class extends TestGrammar
        getTestGrammar: -> {
          start: @seq @zeroOrMore('t1'), @seq('t1', 't2')
        }
      assertParse grammar, [
        [[['t1', 1], ['t1', 2], ['t2', 'l']], false]
      ]

  assertParse = (grammarClass, asserts) ->
    grammar = new grammarClass
    for [tokens, ast] in asserts
      grammar.parse(tokens).should.eql ast, "parsed tokens\n#{tokens.join ' | '}"
