_ = require '../../lib/underscore'

{polymorphic} = require './base'

isNodeJS = not window?

fmt = (x) ->
  if x instanceof Array then _(x).map(fmt).join ' '
  else if x is null then '$'
  else if typeof x is 'boolean' then '$' + 'ft'[+x]
  else '' + x

# writeHelper(...)
# flag can be 'w' for write (the default) or 'a' for append
writeHelper = (filename, data, flag) ->
  content = fmt data
  if filename is ''
    if isNodeJS
      process.stdout.write content
    else
      alert content
  else if typeof filename is 'string'
    # TODO return $ on failure
    if isNodeJS
      require('fs').writeFileSync filename, content, {flag}
    else
      localStorage.setItem filename,
        if flag is 'a' then (localStorage.getItem(filename) or '') + content
        else content
  else if filename isnt null
    throw Error 'First argument to "write" or "writa" must be a string or $'
  content

@write = polymorphic(
  # $ write "abc             ->   "abc
  # $ write ["abc]           ->   "abc
  # $ write [1;2;3;"abc]     ->   '(1 2 3 abc)
  # $ write [1;[2;3];"abc]   ->   '(1 2 3 abc)
  (x, q) -> writeHelper x, q
)

@writa = polymorphic(
  (x, q) -> writeHelper x, q, 'a'
)

@readf = polymorphic(
  (s, q) ->
    content =
      if s
        # TODO return $ on failure
        if isNodeJS
          require('fs').readFileSync s
        else
          localStorage.getItem s
      else
        if isNodeJS
          throw Error 'Cannot read synchronously from stdin in NodeJS'
        else
          prompt 'Input:'
    if content?
      reads [content, q]
    else
      null
)

@reads = reads = polymorphic(
  # '(123 456 789)   reads ["num;"str;"num]   ->   [123;'(456);789;'()]
  # '(1't2)          reads ["num;"num]        ->   [1;2;'()]
  # '( 't 1't 't2't) reads ["num;"num]        ->   [1;2;'('t)]
  # '(1't2)          reads ["num]             ->   [1;'('t2)]
  # '(1'n2)          reads ["num;"num]        ->   [1;'()]
  # '(a b)           reads ["str]             ->   ['a;'( b)]
  # '(a b)           reads ["num]             ->   $
  # '(a b)           reads []                 ->   ['(a b)]
  (s, q) ->
    s = s.replace /^(.*)[^]*$/, '$1' # cut `s` off at the first newline
    r = []
    for t in q
      if not (m = s.match /^[ \t]*([^ \t]+)(.*)$/) then break
      [_ignore, item, s] = m
      if t is 'str'
        r.push item
      else if t is 'num'
        # TODO negative and floating-point numbers
        if not /^\d+$/.test item then return null
        r.push parseInt item, 10
      else
        throw Error "Invalid type, #{JSON.stringify t}.  Only \"num\" and \"str\" are allowed."
    r.push s
    r
)
