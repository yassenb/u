@['.'] = (a) ->
  if not (a instanceof Array) or a.length isnt 2
    # ..[1;2;3]   ->   error 'Arguments to . must be a sequence of length 2'
    throw Error 'Arguments to . must be a sequence of length 2'
  [x, y] = a
  if typeof x is 'function'
    # +.[1;2]  ->  3
    x y
  else if x instanceof Array or typeof x is 'string'
    if typeof y in ['number', 'boolean']
      y = +y # if boolean, convert to number
      if y isnt Math.floor y
        # [1;2;3].$pi   ->   error 'Indices must be integers'
        throw Error 'Indices must be integers'
      else if 0 <= y < x.length
        # [1;2;3].0     ->   1
        # [1;2;3].2     ->   3
        # [1;2;3].$f    ->   1
        # [1;2;3].$t    ->   2
        x[y]
      else if -x.length <= y < 0
        # TODO test negative indices
        x[x.length - y]
      else
        # [1;2;3].3     ->   $
        null
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
# $t + $t        ->   2
# 2 + $t         ->   3
# $t + 2         ->   3
@['+'] = (a) ->
  if a.length isnt 2
    throw Error '+ takes exactly two arguments'

  if typeof a[0] in ['number', 'boolean']
    if typeof a[1] not in ['number', 'boolean']
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
