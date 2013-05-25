@['.'] = (a) ->
  if not (a instanceof Array) or a.length isnt 2
    # ..[1;2;3]   ->   error 'Arguments to . must be a sequence of length 2'
    throw Error 'Arguments to . must be a sequence of length 2'
  [x, y] = a
  if typeof x is 'function'
    # +.[1;2]  ->  3
    x y
  else if x instanceof Array or typeof x is 'string'
    if typeof y is 'number'
      # [1;2;3].$pi   ->   error 'Indices must be integers'
      if y isnt Math.floor y
        throw Error 'Indices must be integers'
      # [1;2;3].3     ->   error 'Index out of bounds'
      # TODO test negative indices
      if not (-x.length <= y < x.length)
        throw Error 'Index out of bounds'
      # [1;2;3].0     ->   1
      # [1;2;3].2     ->   3
      # TODO test negative indices
      x[if y < 0 then y + x.length else y]
    else if typeof y is 'function'
      # [1;2;0;4;5].@{x::?{x::0;1}}   ->   2
      # [1;2;3;4;5].@{x::?{x::0;1}}   ->   $
      for e, i in x when y e then return i
      null
    else
      # [1;2].[3;4]   ->   error 'Unsupported operation'
      throw Error 'Unsupported operation'
  else
    # 1 . 2   ->   error 'Unsupported operation'
    throw Error 'Unsupported operation'

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
