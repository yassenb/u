_ = require '../lib/underscore'

{tokenize} = require '../src/lexer'

describe 'lexer', ->
  describe 'tokenize()', ->
    nextTimes = (n, code) ->
      tokenized = tokenize code
      result = null
      _(n).times (_0) -> result = tokenized.next()
      result

    describe 'next()', ->
      it 'should produce only the "eof" token when blank source is given', ->
        nextTimes(1, '').type.should.equal 'eof'
        nextTimes(1, ' \t\n ').type.should.equal 'eof'

      it 'return the next token on consecutive calls', ->
        nextTimes(2, '1+2').value.should.equal '+'

      it 'omits whitespace', ->
        nextTimes(3, '1 +\n5').value.should.equal '5'

      it 'omits comments', ->
        code = """
          1 + 2 " single line comment
          3
        """
        nextTimes(4, code).value.should.equal '3'

        code = """
          1 + 2
          "{ multi
            line
          "}
          3
        """
        nextTimes(4, code).value.should.equal '3'

      it 'returns the correct code position', ->
        code = """
          1 + 2
          "{ multi
             line comment
          "}
          " single line comment

          3 + 75 + 4
        """
        t = nextTimes 6, code
        t.startLine.should.equal 7
        t.endLine.should.equal 7
        t.startCol.should.equal 5
        t.endCol.should.equal 6

      it 'throws on unrecognized token', ->
        (-> nextTimes 1, '?').should.throw /^Syntax error: unrecognized token/

    it 'can rollback to a specific state', ->
      t = tokenize '1+3+5+7'

      t.next()
      t.next()
      position1 = t.getPosition()
      t.next()
      t.next()
      position2 = t.getPosition()
      t.next()
      t.rollback position2
      t.next().value.should.equal '5'
      t.rollback position1
      t.next().value.should.equal '3'

    # TODO test all kinds of tokens and combinations
