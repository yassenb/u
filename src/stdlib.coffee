@['.'] = (a) ->
  if not (a instanceof Array) or a.length isnt 2
    throw Error 'Arguments to . must be a sequence of length 2'
  if typeof a[0] isnt 'function'
    throw Error 'First argument to . must be a function'
  a[0] a[1]

# 1 + 1          ->   2
# 1 + (1         ->   error 'Parser error'
# 1 + [1;2]      ->   error 'Inconsistent'
# [1] + [2;3]    ->   [1;2;3]
# [1;2;3] + []   ->   [1;2;3]
# +.[1]          ->   1
# +.[1;2;3;4]    ->   10
# +.[+]          ->   error 'Unsupported'
# [1;2+3;4]      ->   [1;5;4]
@['+'] = (a) ->
  if not (a instanceof Array) then a = [a]
  if a.length is 0 then return 0
  if typeof a[0] is 'number'
    r = 0
    for x in a
      if typeof x isnt 'number'
        throw Error 'Inconsistent argument types for +'
      r += x
    r
  else if a[0] instanceof Array
    for x in a
      if not (x instanceof Array)
        throw Error 'Inconsistent argument types for +'
    [].concat a...
  else
    throw Error 'Unsupported argument type for +'
