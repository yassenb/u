_ = require '../lib/underscore'

# polymorphic(...) combines a list of functions into a single function that
# does type dispatching.  For instance
#     polymorphic(
#       (n) --> sgn n
#       (n1, n2) --> n1 * n2
#       (s, i) --> Array(i + 1).join(s)
#       (q, i) --> r = []; (for [0...i] then r = r.concat q); r
#     )
# could be an implementation for the * function.
# It introspects parameter names for their initials and tries to coerce actual
# arguments to the respective types before passing them:
#     n   number or boolean
#     i   integer or boolean
#     b   boolean
#     q   sequence or string
#     s   string
#     p   picture
#     f   function
#     x   anything
# If coercion fails, we try the next polymorphic variant.
# If all variants fail, we throw an error.
polymorphic = (fs...) ->
  signatures =
    for f in fs
      for t in ('' + f).replace(/^\s*function\s*\(([^\)]*)\)[^]+$/, '$1').split /\s*,\s*/
        t[0]
  (a) ->
    if a not instanceof Array then a = [a]
    for f, i in fs when (xs = coerce a, signatures[i]) then return f xs...
    throw Error 'Unsupported operation'

# coerce(...) takes a list `xs` of values and a type signature `ts` (which is a
# sequence of type initials) and tries to coerce each value to its respective
# type.
# It returns either undefined or a vector of coerced values.
coerce = (xs, ts) ->
  if xs.length is ts.length
    r = []
    for x, i in xs
      return unless (
        switch ts[i]
          when 'n' then x = +x; typeof xs[i] in ['number', 'boolean']
          when 'i' then x = +x; typeof xs[i] in ['number', 'boolean'] and x is ~~x
          when 'b' then typeof x is 'boolean'
          when 'q' then x instanceof Array or typeof x is 'string'
          when 's' then typeof x is 'string'
          when 'p' then false # TODO pictures
          when 'f' then typeof x is 'function'
          when 'x' then true
          else throw Error 'Bad type symbol, ' + JSON.stringify ts[i]
      )
      r.push x
    r

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
        # "abc.(-.2)    ->   'b
        x[x.length + y]
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
# +.[]           ->   error 'Unsupported'
# +.[1]          ->   error 'Unsupported'
# +.[1;2;3;4]    ->   error 'Unsupported'
# 1 + [1;2]      ->   error 'Unsupported'
# +.[+;2]        ->   error 'Unsupported'
# '(hell)+'o     ->   "hello
# "hello+'()     ->   "hello
# $t + $t        ->   2
# 2 + $t         ->   3
# $t + 2         ->   3
# + . 1          ->   error 'Unsupported'
@['+'] = polymorphic(
  (n1, n2) -> n1 + n2
  (q1, q2) -> q1.concat q2
  # TODO Are sequences and strings fundamentally distinct or can they be
  # concatenated to one another?
)

@['-'] = polymorphic(

  # -.$t   ->   - . 1
  # -.'a   ->   error 'Unsupported'
  (n) -> -n

  # 2 - 3     ->   - . 1
  # 2 - 3     ->   - . 1
  # $f - $t   ->   - . 1
  # 3 - $t    ->   2
  (n1, n2) -> n1 - n2

  # "mississippi-"dismiss   ->   "sippi
  (s1, s2) ->
    r = s1
    for c in s2 when (j = r.indexOf c) isnt -1
      r = r[...j] + r[j + 1...] # remove the j-th character from r
    r

  # [8;1;5;5;1;5;5;1;9;9;1]-[0;1;5;8;1;5;5]  ->  [5;1;9;9;1]
  # [1;2;3;4;5] - [1;4;7]    ->   [2;3;5]
  # [[1;2];[3;4]] - [[1;2]]  ->   [[3;4]]
  (q1, q2) ->
    r = q1[...] # make a copy
    for x in q2
      for y, j in r when eq x, y
        r.splice j, 1 # remove the j-th element from r
        break
    r

  # 1-[1;2;3]   ->   error 'Unsupported'
  # $-0         ->   error 'Unsupported'
  # -.[]        ->   error 'Unsupported'
  # -.[1;2;3]   ->   error 'Unsupported'
)

@['*'] = polymorphic(

  # * . 123         ->   1
  # * . [- . 123]   ->   - . 1
  # * . 0           ->   0
  # * . $t          ->   1
  # * . $f          ->   0
  (n) -> (n > 0) - (n < 0) # signum

  # 2 * 3           ->   6
  # $t * 5          ->   5
  (n1, n2) -> n1 * n2

  # [2;5]*3         ->   [2;5;2;5;2;5]
  # "abc*2          ->   "abcabc
  # [17]*$f         ->   []
  # "abc*0          ->   '()
  # TODO should we allow i*q as well?
  # [2;5]*$pi       ->   error 'Unsupported'
  # [2;5]*(- . 1)   ->   error 'non-negative'
  # 'a*$pinf        ->   error 'Unsupported'
  (q, i) ->
    if i < 0
      throw Error 'Multiplier for sequence or string must be non-negative.'
    r = q[...0] # gives '' if q is a string and [] if q is a list
    for [0...i] then r = r.concat q
    r

  # * . 'a          ->   error 'Unsupported'
  # 'a * 'b         ->   error 'Unsupported'
)

@['^'] = polymorphic(

  # 2^3               ->   8
  # 3^2               ->   9
  # (- . 1)^2         ->   1
  # (- . 1)^(- . 1)   ->   - . 1
  (n1, n2) -> Math.pow n1, n2

  # (_+[1;2]^3).[777]     ->   [777;1;2;1;2;1;2]
  # @{x::'<\x/'>}^3."xy   - >   '(<<<xy>>>)    " TODO enable this test after we implement \ and /
  (f, i) ->
    if i < 0 then throw Error 'Obverse functions are not supported.'
    (a) -> (for [0...i] then a = f a); a
)

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
