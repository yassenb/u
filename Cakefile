# Sanity check
fs = require 'fs'
if not fs.existsSync 'node_modules'
  console.error '''
    Directory "node_modules/" does not exist.
    You should run "npm install" first.
  '''
  process.exit 1

{coffee, action} = ake = require 'ake'
glob = require 'glob'
stitch = require 'stitch'

coffeeToJsFileName = (f) ->
  f.replace /^src\/(.+)\.coffee$/, 'dist/$1.js'

task 'build', ->
  ake [
    coffee 'src/**/*.coffee', coffeeToJsFileName
    coffee 'web/index.coffee'
    action(
      glob.sync('src/**/*.coffee').map coffeeToJsFileName
      ['web/u-stitched.js']
      ({callback, log}) ->
        stitch.createPackage(paths: ['dist']).compile (err, jsCode) ->
          if err then throw err
          log 'writing stitched file'
          fs.writeFile 'web/u-stitched.js', jsCode, (err) ->
            if err then throw err
            callback()
    )
  ]
