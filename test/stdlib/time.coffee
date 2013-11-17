{time} = require '../../src/stdlib/time'
sinon = require 'sinon'

describe 'time', ->
  before ->
    @date = new Date
    @clock = sinon.useFakeTimers @date.getTime(), 'Date'

  after ->
    @clock.restore()

  it 'gives the current day/month/year when called with \'d', ->
    time('d').should.eql [@date.getDate(), @date.getMonth(), @date.getUTCFullYear()]

  it 'gives the current hour/minute/second when called with \'h', ->
    time('h').should.eql [@date.getHours(), @date.getMinutes(), @date.getSeconds()]

  it 'gives the current day/month/year and hour/minute/second when called with \'t', ->
    time('t').should.eql [[@date.getHours(), @date.getMinutes(), @date.getSeconds()],
                          [@date.getDate(), @date.getMonth(), @date.getUTCFullYear()]]

  it 'gives the seconds from 1970 when called with \'s', ->
    time('s').should.eql Math.floor(@date.getTime() / 1000)

  it 'pretty prints the time when called with \'p', ->
    time('p').should.eql @date.toString()
