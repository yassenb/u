{tokenize} = require '../src/lexer'

describe 'lexer', ->
  describe 'tokenize()', ->
    firstToken = (code) ->
      tokenize(code).next()

    it 'should produce only the "eof" token when blank source is given', ->
      firstToken('').type.should.equal 'eof'
      firstToken(' \t\n ').type.should.equal 'eof'
