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

@['.'] = polymorphic(

  # +.[1;2]  ->  3
  (f, x) -> f x

  # [1;2;3].0     ->   1
  # [1;2;3].2     ->   3
  # [1;2;3].$f    ->   1
  # [1;2;3].$t    ->   2
  # "hello.1      ->   'e
  # [1;2].(-.1)   ->   2
  # "abc.(-.2)    ->   'b
  # [1;2;3].3     ->   $
  # "hello.10     ->   $
  # [1;2].(-.3)   ->   $
  (q, i) ->
    if 0 <= i < q.length then q[i]
    else if -q.length <= i < 0 then q[q.length + i]
    else null

  # [1;2;0;4;5].@{x::?{x::0;1}}   ->   2
  # [1;2;3;4;5].@{x::?{x::0;1}}   ->   $
  (q, f) ->
    for x, i in q when f x then return i
    null

  # ..[1;2;3]     ->   error 'Unsupported'
  # [1;2;3].$pi   ->   error 'Unsupported'
  # [1;2].[3;4]   ->   error 'Unsupported'
  # 1 . 2         ->   error 'Unsupported'
)

@['+'] = polymorphic(

  # 1 + 1          ->   2
  # $t + $t        ->   2
  # 2 + $t         ->   3
  # $t + 2         ->   3
  (n1, n2) -> n1 + n2

  # [1] + [2;3]    ->   [1;2;3]
  # [] + [2;3]     ->   [2;3]
  # [1;2;3] + []   ->   [1;2;3]
  # '(hell)+'o     ->   "hello
  # "hello+'()     ->   "hello
  # TODO Are sequences and strings fundamentally distinct or can they be
  # concatenated to one another?
  (q1, q2) -> q1.concat q2

  # +.[]           ->   error 'Unsupported'
  # +.[1]          ->   error 'Unsupported'
  # +.[1;2;3;4]    ->   error 'Unsupported'
  # 1 + [1;2]      ->   error 'Unsupported'
  # +.[+;2]        ->   error 'Unsupported'
  # + . 1          ->   error 'Unsupported'
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
  # @{x::'<\x/'>}^3."xy   ->   '(<<<xy>>>)
  (f, i) ->
    if i < 0 then throw Error 'Obverse functions are not supported.'
    (a) -> (for [0...i] then a = f a); a
)

@[':'] = polymorphic(

  # :.$pi   ->   1:$pi
  # :.$t    ->   1
  # :.$f    ->   $pinf
  (n) -> 1 / n

  # $t:$f   ->   $pinf
  # 119:7   ->   17
  (n1, n2) -> n1 / n2

  # "abcdefghijkl:5   ->   ["abc;"def;"gh;"ij;"kl]
  # [1;2;3;4]:1       ->   [[1;2;3;4]]
  # [1;2;3;4]:2       ->   [[1;2];[3;4]]
  # [1;2;3;4]:3       ->   [[1;2];[3];[4]]
  # [1;2;3;4]:4       ->   [[1];[2];[3];[4]]
  # [1;2;3;4]:5       ->   [[1];[2];[3];[4];[]]
  # []:3              ->   [[];[];[]]
  # [1;2;3]:(- . 1)   ->   error 'must be positive'
  (q, i) ->
    if i <= 0 then throw Error 'Sequence denominator must be positive.'
    r = q.length % i
    l = (q.length - r) / i
    l1 = l + 1
    (for j in [0...r] then q[j * l1 ... (j + 1) * l1])
      .concat(for j in [r...i] then q[j * l + r ... (j + 1) * l + r])

  # 5:"abcdefghijkl   ->   ["abcde;"fghij;"kl]
  # 1:[1;2;3;4]       ->   [[1];[2];[3];[4]]
  # 2:[1;2;3;4]       ->   [[1;2];[3;4]]
  # 3:[1;2;3;4]       ->   [[1;2;3];[4]]
  # 4:[1;2;3;4]       ->   [[1;2;3;4]]
  # 5:[1;2;3;4]       ->   [[1;2;3;4]]
  # 3:[]              ->   []
  # (- . 1):[1;2;3]   ->   error 'must be positive'
  (i, q) ->
    if i <= 0 then throw Error 'Sequence numerator must be positive.'
    for j in [0...q.length] by i then q[j...j+i]
)

@['\\'] = polymorphic(

  # 'a\"bc   ->   "abc
  # "ab\'c   ->   error 'must be a string of length 1'
  (x, s) ->
    if typeof x isnt 'string' or x.length isnt 1
      throw Error 'In the expression "x\\s" where "s" is a string, "x" must be a string of length 1.'
    x + s

  # 1\[2;3]       ->   [1;2;3]
  # 1\[]          ->   [1]
  # [1;2]\[3;4]   ->   [[1;2];3;4]
  (x, q) -> [x].concat q

  # 1\2   ->   [1;2]
  (x1, x2) -> [x1, x2]
)

@['/'] = polymorphic(

  # "ab/'c   ->   "abc
  # 'a/"bc   ->   error 'must be a string of length 1'
  (s, x) ->
    if typeof x isnt 'string' or x.length isnt 1
      throw Error 'In the expression "s/x" where "s" is a string, "x" must be a string of length 1.'
    s + x

  # [1;2]/3       ->   [1;2;3]
  # []/1          ->   [1]
  # [1;2]/[3;4]   ->   [1;2;[3;4]]
  (q, x) -> q.concat [x]

  # 1/2   ->   [1;2]
  (x1, x2) -> [x1, x2]
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
