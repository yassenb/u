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
        # "hello.1      ->   'e
        x[y]
      else if -x.length <= y < 0
        # TODO test negative indices
        x[x.length - y]
      else
        # [1;2;3].3     ->   $
        # "hello.10     ->   $
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
  if a not instanceof Array or a.length isnt 2
    # + . 1   ->   error '+ takes exactly two arguments'
    throw Error '+ takes exactly two arguments'
  [x, y] = a
  if typeof x in ['number', 'boolean'] and typeof y in ['number', 'boolean']
    x + y
  else if x instanceof Array and y instanceof Array
    x.concat y
  else if typeof x is typeof y is 'string'
    # TODO Are sequences and strings fundamentally distinct or can they be
    # concatenated to one another?
    x + y
  else
    throw Error 'Unsupported argument types for +'
