{polymorphic, qToString} = require '../../src/stdlib/base'

describe 'polymorphic', ->
  sum2 = (i1, i2) -> i1 + i2
  polySum2 = polymorphic sum2

  it 'produces a function that acts just as the original but takes its arguments as a single argument - an array', ->
    inc = polymorphic (i) -> i + 1
    inc(2).should.eql 3

    twice = polymorphic (q) -> q.concat q
    twice([1, 2]).should.eql [1, 2, 1, 2]

    polySum2([2, 3]).should.eql 5

    polySum3 = polymorphic (i1, i2, i3) -> i1 + i2 + i3
    polySum3([1, 2, 4]).should.eql 7

  it 'allows more than one prototype for a function', ->
    ps = polymorphic(
      sum2
      (s1, s2) -> s1 + ' ' + s2
    )
    ps([2, 3]).should.eql 5
    ps(['hello', 'world']).should.eql 'hello world'

  it 'throws when called with a function with bad argument names', ->
    f = polymorphic (a) -> 5
    (-> f 5).should.throwError /Bad type symbol/

  it 'throws when the obtained function is called with the wrong type of arguments', ->
    (-> polySum2(['ab', 2])).should.throwError /Unsupported operation/

describe 'qToString', ->
  it 'converts a sequence of chars into a string', ->
    qToString(['a', 'b', 'c']).should.eql 'abc'
    qToString(['a']).should.eql 'a'

  it 'doesn\'t conver into a string when an element in the sequence is not a character', ->
    qToString([1, 2]).should.eql [1, 2]
    qToString(['a', 2]).should.eql ['a', 2]
    qToString([2, 'a']).should.eql [2, 'a']
    qToString(['a', 'bb', 'c']).should.eql ['a', 'bb', 'c']
    qToString(['a', '', 'c']).should.eql ['a', '', 'c']

  it 'returns either an empty string or an empty sequence given the original sequence', ->
    qToString([], [1, 2]).should.eql []
    qToString([], []).should.eql []
    qToString([], 'abc').should.eql ''
    qToString([], '').should.eql ''
