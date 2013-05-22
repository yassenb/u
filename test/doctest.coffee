trim = (s) -> s.replace /(^ +| +$)/g, ''

forEachDoctest = (handler, continuation) ->
  fs = require 'fs'
  glob = require 'glob'
  glob __dirname + '/../../src/**/*.coffee', (err, files) ->
    if err then throw err
    for f in files
      lines = fs.readFileSync(f, 'utf8').split '\n'
      i = 0
      while i < lines.length
        line = lines[i++]
        while i < lines.length and (m = lines[i].match(/^ *# *\.\.\.(.*)$/))
          line += '\n' + m[1]
          i++
        if m = line.match /^ *#(.*) -> (.+)$/
          handler code: trim(m[1]), expectation: trim(m[2])
    continuation?()

@runTestCase = runTestCase = ({code, expectation}) ->
  {exec} = require '../src/compiler'
  if m = expectation.match /^error\b\s*([^]*)$/
    expectedErrorMessage = if m[1] then eval m[1] else ''
    try
      exec code
      return {
        success: false
        reason: "It should have thrown an error, but it didn't."
      }
    catch e
      if expectedErrorMessage and e.message.indexOf(expectedErrorMessage) is -1
        return {
          success: false
          error: e
          reason: "It should have failed with #{
                    JSON.stringify expectedErrorMessage}, but it failed with #{
                    JSON.stringify e.message}"
        }
  else
    try
      expected = exec expectation
    catch e
      return {
        success: false
        error: e
        reason: "Cannot compute expected value #{JSON.stringify expectation}"
      }
    try
      actual = exec code
      if not eq actual, expected
        return {
          success: false
          reason: "Expected #{JSON.stringify expected} but got #{JSON.stringify actual}"
        }
    catch e
      return {
        success: false
        error: e
      }
  {success: true}

runDoctests = (continuation) ->
  nTests = nFailed = 0
  t0 = Date.now()
  lastTestTimestamp = 0
  forEachDoctest(
    ({code, expectation}) ->
      nTests++
      outcome = runTestCase {code, expectation}
      if not outcome.success
        nFailed++
        console.info "Test failed: #{JSON.stringify code}"
        if outcome.reason then console.error outcome.reason
        if outcome.error then console.error outcome.error.stack
      if Date.now() - lastTestTimestamp > 100
        process.stdout.write(
          nTests + (if nFailed then " (#{nFailed} failed)" else '') + '\r'
        )
        lastTestTimestamp = Date.now()

    -> # continuation after forEachDoctest
      console.info(
        (if nFailed then "#{nFailed} out of #{nTests} tests failed"
        else "All #{nTests} tests passed") +
        " in #{Date.now() - t0} ms."
      )
      continuation?()
  )

eq = (x, y) ->
  if x instanceof Array and y instanceof Array
    if x.length isnt y.length then return false
    for i in [0...x.length] when not eq x[i], y[i] then return false
    true
  else
    typeof x is typeof y and x is y

if module? and module is require.main
  runDoctests()
