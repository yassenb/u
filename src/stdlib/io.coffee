_ = require '../../lib/underscore'
fs = require 'fs'

{polymorphic} = require './base'
{frm} = require './text'

isNodeJS = not window?

fmt = (x) ->
  if x instanceof Array then _(x).map(fmt).join ' '
  else if x is null then '$'
  else if typeof x is 'boolean' then '$' + 'ft'[+x]
  else if typeof x is 'function' then '<function>'
  else '' + x

# flag can be 'w' for write (the default) or 'a' for append
writeHelper = (filename, data, flag) ->
  content = fmt data
  if filename is ''
    if isNodeJS
      process.stdout.write content
    else
      alert content
  else if typeof filename is 'string'
    failed = false
    if isNodeJS
      try
        fs.writeFileSync filename, content, {flag}
      catch error
        failed = true
    else
      localStorage.setItem filename,
        if flag is 'a' then (localStorage.getItem(filename) or '') + content
        else content

    return null if failed
  content

# TODO all functions here should be (s, q), not (x, q)
@write = polymorphic(
  # $ write "abc             ->   "abc
  # $ write ["abc]           ->   "abc
  # $ write [1;2;3;"abc]     ->   '(1 2 3 abc)
  # $ write [1;[2;3];"abc]   ->   '(1 2 3 abc)
  # $ write [$]              ->   '($)
  # $ write [$f]             ->   '($f)
  # $ write [@{ :: 5}]       ->   '(<function>)
  (x, q) -> writeHelper x, q
)

@writa = polymorphic(
  (x, q) -> writeHelper x, q, 'a'
)

@readf = polymorphic(
  (s, q) ->
    content =
      if s isnt ''
        failed = false
        if isNodeJS
          try
            fs.readFileSync s
          catch error
            failed = true
        else
          localStorage.getItem s
      else
        if isNodeJS
          # TODO see http://stackoverflow.com/questions/3430939/node-js-readsync-from-stdin
          throw Error 'Reading from STDIN not implemented'
        else
          prompt 'Input:'
    if not failed and content?
      reads [content, q]
    else
      null
)

@reads = reads = polymorphic(
  # '(12)            reads ["num]        ->   [12;'()]
  # '(-5)            reads ["num]        ->   [~5;'()]
  # '(+5)            reads ["num]        ->   [5;'()]
  # '(3.14)          reads ["num]        ->   [3.14;'()]
  # '(314e-2)        reads ["num]        ->   [3.14;'()]
  # '(0.0314E+2)     reads ["num]        ->   [3.14;'()]
  # "hell            reads ["str]        ->   ["hell;'()]
  # '(12)            reads ["str]        ->   ['(12);'()]
  # '(1 2)           reads ["num;"num]   ->   [1;2;'()]
  # '(1't2)          reads ["num;"num]   ->   [1;2;'()]
  # '( 't 1't 't2't) reads ["num;"num]   ->   [1;2;'('t)]
  # '(5'n)           reads ["num]        ->   [5;'()]
  # '(1'n2)          reads ["num;"num]   ->   [1;'()]
  # '(a b)           reads ["str]        ->   ['a;'( b)]
  # '(5)             reads ["num;"num]   ->   [5;'()]
  # '(a b)           reads ["num]        ->   $
  # '(a b)           reads ["str;"num]   ->   $
  # '(1 [2])         reads ["num;"num]   ->   $
  # '(3.14ispi)      reads ["num]        ->   $
  # '(a b)           reads []            ->   ['(a b)]
  # '($t)            reads ["bool]       ->   error 'Invalid type'
  (s, q) ->
    s = s.match(/^(.*)$/m)[1] # cut `s` off at the first newline
    result = []
    for t in q
      break unless m = s.match /^[ \t]*([^ \t]+)(.*)$/
      item = m[1]
      s = m[2]
      if t is 'str'
        result.push item
      else if t is 'num'
        return null unless /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/.test item
        result.push parseFloat item
      else
        throw Error "Invalid type passed to read: #{frm ["", t]}.  Only \"num and \"str are allowed."
    result.push s
    result
)
