# This file is require()-d from bin/u, which is the CLI wrapper around U.

fs = require 'fs'
optimist = require 'optimist'
{exec} = require './compiler'

@main = ->

  {argv} = optimist
    .usage('''
      Usage: u [ path/to/script.u ]\n
      When invoked without arguments, `u' reads source code from stdin.
    ''')
    .describe
      h: 'display this help message'
    .alias
      h: 'help'
    .boolean ['h']

  # Show help if requested.
  if argv.help then return optimist.showHelp()

  if argv._.length > 2
    optimist.printUsage()
    return process.exit 1

  uStream = if argv._.length then fs.createReadStream argv._[0] else process.stdin

  uCode = ''
  uStream.setEncoding 'utf8'
  uStream.on 'data', (s) -> uCode += s
  uStream.on 'end', ->
    console.info exec uCode

  return
