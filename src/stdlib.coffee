@['.'] = (a) ->
  if not (a instanceof Array) or a.length isnt 2
    throw Error 'Arguments to . must be a sequence of length 2'
  if typeof a[0] isnt 'function'
    throw Error 'First argument to . must be a function'
  a[0] a[1]

# 1 + 1          ->   2
# [1] + [2;3]    ->   [1;2;3]
# [] + [2;3]     ->   [2;3]
# [1;2;3] + []   ->   [1;2;3]
# +.[]           ->   error '+ takes exactly two arguments'
# +.[1]          ->   error '+ takes exactly two arguments'
# +.[1;2;3;4]    ->   error '+ takes exactly two arguments'
# 1 + [1;2]      ->   error 'Unsupported'
# +.[+;2]        ->   error 'Unsupported'
# '(hell)+'o     ->   "hello
# "hello+'()     ->   "hello
@['+'] = (a) ->
  if a.length isnt 2
    throw Error '+ takes exactly two arguments'

  if typeof a[0] is 'number'
    if typeof a[1] isnt 'number'
      throw Error 'Unsupported operation'
    a[0] + a[1]
  else if a[0] instanceof Array
    unless a[1] instanceof Array
      throw Error 'Unsupported operation'
    a[0].concat a[1]
  else if typeof a[0] is 'string'
    # TODO Are sequences and strings fundamentally distinct or can they be
    # concatenated to one another?
    if typeof a[1] isnt 'string'
      throw Error 'Unsupported operation'
    a[0] + a[1]
  else
    throw Error 'Unsupported argument type for +'

@$ = null
@$f = false
@$t = true
@$pinf = Infinity
@$ninf = -Infinity
@$e = Math.E
@$pi = Math.PI
#@$np = # TODO
