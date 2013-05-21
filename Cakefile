# Sanity check
fs = require 'fs'
if not fs.existsSync 'node_modules'
  console.error '''
    Directory "node_modules/" does not exist.
    You should run "npm install" first.
  '''
  process.exit 1

{coffee, cat, jade, sass, action} = ake = require 'ake'
glob = require 'glob'
stitch = require 'stitch'

task 'build', ->
  ake [
    coffee 'src/**/*.coffee', (f) -> f.replace /^src\/(.+)\.coffee$/, 'lib/$1.js'
    coffee 'web/index.coffee'
    action(
      glob.sync('src/**/*.coffee').map (f) ->
        f.replace /^src\/(.+)\.coffee$/, 'lib/$1.js'
      ['web/u-stitched.js']
      ({callback, log}) ->
        stitch.createPackage(paths: ['lib']).compile (err, jsCode) ->
          if err then throw err
          log 'writing stitched file'
          fs.writeFile 'web/u-stitched.js', jsCode, (err) ->
            if err then throw err
            callback()
    )
  ]
