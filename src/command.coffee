# This file is require()-d from bin/u, which is the CLI wrapper around U.

fs = require 'fs'
optimist = require 'optimist'

@main = ->

  {argv} = optimist
    .usage('''
      Usage: u [ path/to/script.u ]\n
      When invoked without arguments, `u' reads source code from stdin.
    ''')
    .describe
      e: 'pass a string from the command line as input'
      h: 'display this help message'
      n: 'print out the parse tree that the parser produces'
    .alias
      e: 'eval'
      h: 'help'
      n: 'nodes'
    .boolean(['h', 'n'])
    .string(['e'])

  # Show help if requested.
  if argv.help then return optimist.showHelp()

  if argv._.length > 2
    optimist.printUsage()
    return process.exit 1

  if argv.eval
    processCode argv.eval, argv
  else
    uStream = if argv._.length then fs.createReadStream argv._[0] else process.stdin
    uCode = ''
    uStream.setEncoding 'utf8'
    uStream.on 'data', (s) -> uCode += s
    uStream.on 'end', -> processCode uCode, argv
  return

processCode = (uCode, argv) ->
  if argv.nodes
    {parse} = require './peg-parser/u-grammar'
    process.stdout.write repr(parse uCode) + '\n'
  else
    {exec} = require './compiler'
    exec uCode
  return

repr = (x, indent = '') ->
  if x is null or typeof x in ['string', 'number', 'boolean']
    JSON.stringify x
  else if x instanceof Array
    '[\n' + indent +
      (for y in x then '  ' + repr y, indent + '  ').join(',\n' + indent) +
      '\n' + indent + ']'
  else if typeof x is 'object'
    '{\n' + indent +
      (for k, v of x then '  ' + k + ': ' + repr v, indent + '  ').join(',\n' + indent) +
      '\n' + indent + '}'
  else
    '???'
