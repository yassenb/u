_ = require '../lib/underscore'

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
        # [1;2].(-.1)   ->   2
        x[x.length - y]
      else
        # [1;2;3].3     ->   $
        # "hello.10     ->   $
        # [1;2].(-.3)   ->   $
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

@['-'] = (a) ->
  if a not instanceof Array
    a = [a]

  if a.length is 1
    x = a[0]
    if typeof x in ['number', 'boolean']
      # -.$t   ->   - . 1
      -x # JavaScript's unary minus coerces its argument to a number
    else
      # -.'a   ->   error 'Unsupported argument type'
      throw Error 'Unsupported argument type for -'
  else if a.length is 2
    [x, y] = a
    if typeof x in ['number', 'boolean'] and typeof y in ['number', 'boolean']
      # 2 - 3     ->   - . 1
      # 2 - 3     ->   - . 1
      # $f - $t   ->   - . 1
      # 3 - $t    ->   2
      x - y # JavaScript's minus operator coerces its arguments to numbers
    else if x instanceof Array and y instanceof Array
      # [8;1;5;5;1;5;5;1;9;9;1]-[0;1;5;8;1;5;5]  ->  [5;1;9;9;1]
      # [1;2;3;4;5] - [1;4;7]    ->   [2;3;5]
      # [[1;2];[3;4]] - [[1;2]]  ->   [[3;4]]
      r = x[...] # make a copy of x
      for yi in y
        for rj, j in r when eq yi, rj
          r.splice j, 1 # remove the j-th element from r
          break
      r
    else if typeof x is typeof y is 'string'
      # "mississippi-"dismiss   ->   "sippi
      r = x
      for yi in y when (j = r.indexOf yi) isnt -1
        r = r[...j] + r[j + 1...] # remove the j-th character from r
      r
    else
      # 1-[1;2;3]   ->   error 'Unsupported argument types'
      # $-0         ->   error 'Unsupported argument types'
      throw Error 'Unsupported argument types for -'
  else
    # -.[]        ->   error 'arguments'
    # -.[1;2;3]   ->   error 'arguments'
    throw Error '- takes one or two arguments but got ' + a.length

# $=$                         ->   $t
# 1=1                         ->   $t
# 1+2=3                       ->   $t
# 1+2=4                       ->   $f
# [1]=1                       ->   $f
# [1;2;3]=[1;2;3]             ->   $t
# [1;[2;'3]]=[1;[2;'3]]       ->   $t
# [1;2;3]=[1;'(2,3)]          ->   $f
# '(123)=[1;2;3]=[1;'(2,3)]   ->   $f
# TODO does $t equal 1?
# TODO how do we treat NaN-s?
@['='] = (a) ->
  if a not instanceof Array or a.length isnt 2
    throw Error '= takes exactly two arguments'
  eq a[0], a[1]

eq = (x, y) ->
  if x is y # translates to JavaScript's "===", which is type-safe
    true
  else if x instanceof Array and y instanceof Array and x.length is y.length
    for xi, i in x when not eq xi, y[i] then return false
    true
  else
    false
