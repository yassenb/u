_ = require '../../../lib/underscore'

# borrowed from http://coffeescriptcookbook.com/chapters/math/generating-predictable-random-numbers
class @Random
  # uses current time as seed
  constructor: ->
    # Knuth and Lewis' improvements to Park and Miller's LCPRNG
    @multiplier = 1664525
    @modulo = 4294967296 # 2**32-1;
    @offset = 1013904223
    @seed = (new Date().valueOf() * new Date().getMilliseconds()) % @modulo

  reSeed: (@seed) ->

  # return a random integer 0 <= n < @modulo
  rand: ->
    # new_seed = (a * seed + c) % m
    @seed = (@multiplier * @seed + @offset) % @modulo

  # return a random float 0 <= f < 1.0
  randf: ->
    @rand() / @modulo

  # return a random int 0 <= f < n
  randn: (n) ->
    Math.floor(@randf() * n)
