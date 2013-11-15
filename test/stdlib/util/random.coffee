{Random} = require '../../../src/stdlib/util/random'

describe 'Random', ->
  it 'produces a random non-negative integer in the given range', ->
    x = (new Random).randn(5)
    x.should.not.be.below(0)
    x.should.be.below(5)

  it 'produces a random float in [0,1)', ->
    x = (new Random).randf()
    x.should.not.be.below(0)
    x.should.be.below(1)

  it 'should output the same sequence when seeded with the same value', ->
    rand = new Random
    seed = Math.random()

    rand.reSeed(seed)
    s1 = [rand.randf(), rand.randf(), rand.randf()]
    rand.reSeed(seed)
    s2 = [rand.randf(), rand.randf(), rand.randf()]
    s1.should.eql s2
