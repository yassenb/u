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
      paramNames = ('' + f).replace(/^\s*function\s*\(([^\)]*)\)[^]+$/, '$1').split /\s*,\s*/
      (for t in paramNames then t[0]).join ''
  (a) ->
    for f, i in fs when (xs = coerce a, signatures[i]) then return f xs...
    throw Error """
      Unsupported operation,
      Argument: #{JSON.stringify a}
      Acceptable signatures: #{JSON.stringify signatures}
      Function name: #{JSON.stringify arguments.callee.uName}
    """

# coerce(...) takes an object `a` (which could be an array) and a type signature `ts` (which is a sequence of type
# initials) and tries to coerce `a` to the respective type or types.
# It returns either undefined or an array of coerced values.
coerce = (a, ts) ->
  if ts.length is 2
    if a instanceof Array and a.length is 2 and
            (x = coerce a[0], ts[0]) and
            (y = coerce a[1], ts[1])
      x.concat y
  else if ts.length is 1
    switch ts
      when 'n' then if typeof a in ['number', 'boolean'] then [+a]
      when 'i' then if typeof a in ['number', 'boolean'] and +a is ~~a then [+a]
      when 'b' then if typeof a is 'boolean' then [a]
      when 'q' then if a instanceof Array or typeof a is 'string' then [a]
      when 's' then if typeof a is 'string' then [a]
      when 'p' then undefined # TODO pictures
      when 'f' then if typeof a is 'function' then [a]
      when 'x' then [a]
      else throw Error 'Bad type symbol, ' + JSON.stringify ts
  else
    throw Error 'Bad type signature, ' + JSON.stringify ts

eq = (x, y) ->
  if x is y # translates to JavaScript's "===", which is type-safe
    true
  else if x instanceof Array and y instanceof Array and x.length is y.length
    for xi, i in x when not eq xi, y[i] then return false
    true
  else
    false

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
  # * . (- . 123)   ->   - . 1
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

@['<:'] = polymorphic(

  # <:.$pi       ->   3
  # <:.(-.$pi)   ->   -.4
  (n) -> Math.floor n

  # 34<:(-.5)        ->   [(-.7);(-.1)]
  # (-.(12:10))<:1   ->   [(-.2);(8:10)]
  (n1, n2) -> [(q = Math.floor n1 / n2), n1 - q * n2]
)

@['>:'] = polymorphic(

  # >:.$pi       ->   4
  # >:.(-.$pi)   ->   -.3
  (n) -> Math.ceil n

  # 34>:(-.5)        ->   [(-.6);4]
  # (-.(15:10))>:1   ->   [(-.1);(-.(5:10))]
  (n1, n2) -> [(q = Math.ceil n1 / n2), n1 - q * n2]
)

@['|:'] = polymorphic(

  # |:.$pi       ->   3
  # |:.(-.$pi)   ->   -.3
  # |:.$e        ->   3
  # |:.(1:2)     ->   0
  # |:.(3:2)     ->   2
  # |:.(-.1:2)   ->   0
  # |:.(-.3:2)   ->   -.2
  round = (n) ->
    x = Math.floor n
    d = n - x
    if d < .5 then x
    else if d > .5 then x + 1
    else x + Math.abs(x) % 2

  # 34|:(-.5)      ->   [-.7;-.1]
  (n1, n2) -> [(q = round n1 / n2), n1 - q * n2]
)

@['<'] = polymorphic(

  # 12 < 3   ->   $f
  # 1 < 23   ->   $t
  # 1 < 1    ->   $f
  # $f < 1   ->   $t
  # $t < 1   ->   $f
  (n1, n2) -> n1 < n2

  # '(12) < '3   ->   $t
  # '() < '( )   ->   $t
  # 'A < 'a      ->   $t
  # 'b < 'a      ->   $f
  (s1, s2) -> s1 < s2

  # 3       < "abcdefgh      ->   "abc
  # (- . 3) < "abcdefgh      ->   "defgh
  # 3 < "ab                  ->   "ab
  # (- . 3) < "ab            ->   '()
  # 3       < [1;2;3;4;5]    ->   [1;2;3]
  # (- . 3) < [1;2;3;4;5]    ->   [4;5]
  # 3 < [1;2]                ->   [1;2]
  # (- . 3) < [1;2]          ->   []
  (i, q) -> if i >= 0 then q[...i] else q[-i...]


  # -<[6;3;9;2]   ->   10
  # -<[123]       ->   123
  # -<[]          ->   $
  # +<"abcd       ->   "abcd
  # -<'()         ->   $
  (f, q) ->
    if q.length
      r = q[q.length - 1]
      for i in [q.length - 2 .. 0] by -1
        r = f [q[i], r]
      r
    else
      null

  # <.(sum on _).[_^2;1;2;3]   - >   14   " TODO enable test when "on" is implemented
  (f) -> throw Error '<.f is not implemented' # TODO implement as @{f::@{x\y::f.x.y}}
)

@['<='] = polymorphic(

  # 12 <= 3   ->   $f
  # 1 <= 23   ->   $t
  # 1 <= 1    ->   $t
  # $f <= 1   ->   $t
  # $t <= 1   ->   $t
  (n1, n2) -> n1 <= n2

  # '(12) <= '3   ->   $t
  # '() <= '( )   ->   $t
  # 'A <= 'a      ->   $t
  # 'b <= 'a      ->   $f
  (s1, s2) -> s1 <= s2
)

@['='] = polymorphic(

  # $=$                         ->   $t
  # 1=1                         ->   $t
  # 1+2=3                       ->   $t
  # 1+2=4                       ->   $f
  # [1]=1                       ->   $f
  # [1;2;3]=[1;2;3]             ->   $t
  # [1;[2;'3]]=[1;[2;'3]]       ->   $t
  # [1;2;3]=[1;'(2,3)]          ->   $f
  # '(123)=[1;2;3]              ->   $f
  # TODO does $t equal 1?
  # TODO how do we treat NaN-s?
  (x1, x2) -> eq x1, x2
)

@['<>'] = polymorphic(
  # $<>$                         ->   $f
  # 1<>1                         ->   $f
  # 1+2<>3                       ->   $f
  # 1+2<>4                       ->   $t
  # [1]<>1                       ->   $t
  # [1;2;3]<>[1;2;3]             ->   $f
  # [1;[2;'3]]<>[1;[2;'3]]       ->   $f
  # [1;2;3]<>[1;'(2,3)]          ->   $t
  # '(123)<>[1;2;3]              ->   $t
  (x1, x2) -> not eq x1, x2
)

@['>='] = polymorphic(

  # 12 >= 3   ->   $t
  # 1 >= 23   ->   $f
  # 1 >= 1    ->   $t
  # $f >= 1   ->   $f
  # $t >= 1   ->   $t
  (n1, n2) -> n1 >= n2

  # '(12) >= '3   ->   $f
  # '() >= '( )   ->   $f
  # 'A >= 'a      ->   $f
  # 'b >= 'a      ->   $t
  (s1, s2) -> s1 >= s2
)

@['>'] = polymorphic(

  # 12 > 3   ->   $t
  # 1 > 23   ->   $f
  # 1 > 1    ->   $f
  # 1 > $f   ->   $t
  # $t > 1   ->   $f
  (n1, n2) -> n1 > n2

  # '(12) > '3   ->   $f
  # '() > '( )   ->   $f
  # 'A > 'a      ->   $f
  # 'b > 'a      ->   $t
  (s1, s2) -> s1 > s2

  # 3       > "abcdefgh      ->   "fgh
  # (- . 3) > "abcdefgh      ->   "abcde
  # 3 > "ab                  ->   "ab
  # (- . 3) > "ab            ->   '()
  # 3       > [1;2;3;4;5]    ->   [3;4;5]
  # (- . 3) > [1;2;3;4;5]    ->   [1;2]
  # 3 > [1;2]                ->   [1;2]
  # (- . 3) > [1;2]          ->   []
  (i, q) -> if i >= 0 then q[Math.max(0, q.length - i)...] else q[...Math.max(0, q.length + i)]

  # - > [6;3;9;2]   ->   - . 8
  # - > [123]       ->   123
  # - > []          ->   $
  # + > "abcd       ->   "abcd
  # - > '()         ->   $
  # [2;3;-5;1] @{[cs;x]:: @{[v;c]::v*x+c} > cs} 2   - >   19 " TODO doesn't compile
  (f, q) ->
    if q.length
      r = q[0]
      for i in [1...q.length] by 1
        r = f [r, q[i]]
      r
    else
      null

  # {f.4 ++ dv == >.:; f==dv.100}   - >   25 " TODO enable test when 'parametric'-s are supported
  (f) -> throw Error '>.f is not implemented' # TODO implement as @{f::@{x::@{y::f.(x\y)}}}
)

@['|'] = polymorphic(

  # |.123         ->   123
  # |.(- . 123)   ->   123
  # |.$f          ->   0
  # |.$t          ->   1
  (n) -> Math.abs n

  # $f|$f   ->   $f
  # $f|$t   ->   $t
  # $t|$t   ->   $t
  # $t|$t   ->   $t
  (b1, b2) -> b1 or b2

  # 3|5          ->   5
  # (- . 3)|$t   ->   1
  (n1, n2) -> Math.max n1, n2

  # "star|"trek        ->   "starek
  # '()|"abracadabra   ->   "abrcd
  (s1, s2) ->
    r = s1
    for x in s2
      if r.indexOf(x) is -1
        r += x
    r

  # [5;7;4;2]|[7;2;3;8]          ->   [5;7;4;2;3;8]
  # []|[4;6;2;4;0;4;8;4;6;2;4]   ->   [4;6;2;0;8]
  (q1, q2) ->
    # TODO Should we tolerate mixing strings and sequences, like "[1;2;3]|'(abc)" and "'(abc)|[1;2;3]"?
    r = q1[...]
    for x in q2
      found = false
      for y in r when eq y, x
        found = true
        break
      if not found
        r.push x
    r

  # 4(|.:)5   ->   5:4
  (f) ->
    # TODO implement in U as @{f::@{x\(y\r)::f.(y\(x\r))}}
    (a) ->
      if a not instanceof Array or a.length < 2 then null
      else f [a[1], a[0]].concat a[2...]
)

@['&'] = polymorphic(

  # $f&$f   ->   $f
  # $f&$t   ->   $f
  # $t&$f   ->   $f
  # $t&$t   ->   $t
  (b1, b2) -> b1 and b2

  # 12&34             ->   12
  # (- . 2)&(- . 3)   ->   - . 3
  # $f&123            ->   0
  # 123&$t            ->   1
  (n1, n2) -> Math.min n1, n2

  # "aqua&"neutral   ->   "aua
  # "aqua&'()        ->   '()
  # '()&"aqua        ->   '()
  # "aqua&"aqua      ->   "aqua
  (s1, s2) ->
    r = ''
    for x in s1 when s2.indexOf(x) isnt -1
      r += x
    r

  # [1;2;3;1]&[4;5;3;6;7;1;8]   ->   [1;3;1]
  # [1;2;3]&[]                  ->   []
  # []&[1;2;3]                  ->   []
  # [1;2;3]&[1;2;3]             ->   [1;2;3]
  (q1, q2) ->
    r = []
    for x in q1
      for y in q2 when eq x, y
        r.push x
        break
    r
)

@[','] = polymorphic(

  # (- . 2),3   ->   [- . 2; - . 1; 0; 1; 2]
  # 0,5         ->   [0;1;2;3;4]
  # 5,0         ->   [5;4;3;2;1]
  # 5,5         ->   []
  # $e,5        ->   [$e; 1+$e; 2+$e]
  (n1, n2) -> [n1...n2]

  # 1,[10;3]         ->   [1;4;7]
  # 10,[1;(- . 3)]   ->   [10;7;4]
  # 10,[1;3]         ->   []
  # $pi,[10;$e]      ->   [$pi; $pi+$e; $pi+(2*$e)]
  (n1, q) ->
    if q not instanceof Array or q.length isnt 2 or
            typeof q[0] not in ['number', 'boolean'] or
            typeof q[1] not in ['number', 'boolean']
      throw Error 'The signature of "," is either "n1,n2" or "n1,[n2;n3]".'
    n2 = +q[0]
    n3 = +q[1]
    for i in [n1...n2] by n3 then i
)

@[',,'] = polymorphic(

  # (- . 2),,3   ->   [- . 2; - . 1; 0; 1; 2; 3]
  # 0,,5         ->   [0;1;2;3;4;5]
  # 5,,0         ->   [5;4;3;2;1;0]
  # 5,,5         ->   [5]
  # $e,5         ->   [$e; 1+$e; 2+$e]
  (n1, n2) -> [n1..n2]

  # 1,,[10;3]         ->   [1;4;7;10]
  # 10,,[1;(- . 3)]   ->   [10;7;4;1]
  # 10,,[1;3]         ->   []
  # $pi,,[10;$e]      ->   [$pi; $pi+$e; $pi+(2*$e)]
  (n1, q) ->
    if q not instanceof Array or q.length isnt 2 or
            typeof q[0] not in ['number', 'boolean'] or
            typeof q[1] not in ['number', 'boolean']
      throw Error 'The signature of "," is either "n1,n2" or "n1,[n2;n3]".'
    n2 = +q[0]
    n3 = +q[1]
    for i in [n1..n2] by n3 then i
)

@['#'] = polymorphic(

  # #."abc        ->   3
  # #.'a          ->   1
  # #.'('t)       ->   1
  # #.'()         ->   0
  # #.[1;2;3]     ->   3
  # 123#456       ->   2
  # 123#[4;5;6]   ->   2
  # #.[1]         ->   1
  # #.[]          ->   0
  (q) -> q.length

  # # . 123       ->   error 'Unsupported'
  # # . $t        ->   error 'Unsupported'
  # # . $         ->   error 'Unsupported'
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

@['~'] = polymorphic(

  # ~.$t   ->   $f
  # ~.$f   ->   $t
  (b) -> not b

  # 1 (~.=) 1   ->   $f
  # 1 (~.=) 2   ->   $t
  # 1 (~.+) 2   ->   $
  # 0 (~.+) 0   ->   $
  (f) -> (a) -> if typeof (r = f a) is 'boolean' then not r else null

  # ~."abc   ->   "cba
  # ~.'()    ->   '()
  (s) -> s.split('').reverse().join('')

  # ~ . [1;2;3]   ->   [3;2;1]
  # ~ . []        ->   []
  (q) -> q[...].reverse()

  # ~ . 0   ->   error 'Unsupported'
  # ~ . $   ->   error 'Unsupported'
)

@['!'] = polymorphic(

  # :![]          ->   []
  # _^2![1;2;3]   ->   [1;4;9]
  # _+'x!"abc     ->   ["ax;"bx;"cx]
  # @{xs::_<xs!(0,,(#.xs))} . "abc        ->   ['();'a;"ab;"abc]
  # @{xs::_>xs!(#.xs,,0)}   . "abc        ->   ["abc;"bc;'c;'()]
  # [1;1;2;3;4;5;6;0;0;9]._![4;2;_=0;5]   ->   [4;2;7;5]
  (f, q) -> for x in q then f x

  # [_<5;_^2]![3;1;5;17;4]   ->   [9;1;16]
  # [_<>'o;_+'a]!"Bonn       ->   ["Ba;"na;"na]
  (q1, q2) ->
    if q1 not instanceof Array or q1.length isnt 2 or not (typeof q1[0] is typeof q1[1] is 'function')
      # []![]   ->   error 'two functions'
      # [+;1]![]   ->   error 'two functions'
      throw Error 'When "!" is used in the form "q1!q2", "q1" must be a sequence of two functions.'
    [p, f] = q1
    for x in q2 when p x then f x
)

@['%'] = polymorphic(

  # q=="abcd; q._>>(_<>'b)%(0,(#.q))   ->   [0;2;3]
  (f, s) -> s.replace /[^]/g, (x) -> if f x then x else ''

  # _<4 % [5;2;4;1;3]   ->   [2;1;3]
  (f, q) -> for x in q when f x then x
)

@['%%'] = polymorphic(

  # _<'d %% "acebd   ->   ["acb;"ed]
  # _<'d %% '()      ->   ['();'()]
  (f, s) ->
    r = ['', '']
    for x in s then r[+!f x] += x
    r

  # _<4 %% [1;3;5;2;4]   ->   [[1;3;2];[5;4]]
  # _<4 %% []            ->   [[];[]]
  (f, q) ->
    r = [[], []]
    for x in q then r[+!f x].push x
    r
)

@['||'] = polymorphic(

  #      ||.[[0;1;2];
  # ...      [3;4;5];
  # ...      [6;7;8]]
  # ...                  ->   [[0;3;6];
  # ...                        [1;4;7];
  # ...                        [2;5;8]]
  #
  # ||.[[0;1;2];[3;4;5];[6;7]]     ->   [[0;3;6];[1;4;7]]
  # ||.[]                          ->   []
  # ||.[[];[1];[1;2]]              ->   []
  # ||.[[];[1];[1;2]]              ->   []
  (q) ->
    if q not instanceof Array
      # ||.'a   ->   error 'must be a sequence.'
      throw Error 'The argument to || must be a sequence.'
    if q.length is 0 then return []
    m = Infinity # length of the shortest sequence
    for a in q
      if a not instanceof Array
        # ||.[[];'a]   ->   error 'sequence of sequences'
        throw Error 'The argument to || must be a sequence of sequences.'
      m = Math.min m, a.length
    for i in [0...m]
      for a in q
        a[i]
)

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

@['=>'] = polymorphic(
  # 1 => (2*_) => (_+3) => (4^_)   ->   1024
  (x, f) -> f x
)

@['>>'] = polymorphic(
  # (1+_)>>(2*_) . 3   ->   8
  (f1, f2) -> (a) -> f2 f1 a
)

@['<<'] = polymorphic(
  # (1+_)<<(2*_) . 3   ->   7
  (f1, f2) -> (a) -> f1 f2 a
)

# ===== Numeric functions =====

@int = polymorphic(
  # int![-.1;0;1;$pi;-.$pi;$e;-.$e;$pinf;$ninf]   ->   [-.1;0;1;3;-.3;2;-.2;$pinf;$ninf]
  (n) -> if n >= 0 then Math.floor n else Math.ceil n
)

# TODO rat n i

@gcd = gcd = polymorphic(
  # 12 gcd 30   ->   6
  # 1  gcd 17   ->   1
  # 17 gcd 17   ->   17
  # 81 gcd 256  ->   1
  # 4276309 gcd 8113579   ->   3457
  (n1, n2) ->
    if n1 isnt ~~n1 or n2 isnt ~~n2 or n1 <= 0 or n2 <= 0
      # 2 gcd (-.3)   ->   error 'positive integers'
      # $e gcd $pi    ->   error 'positive integers'
      # 7 gcd $pinf   ->   error 'positive integers'
      throw Error '"gcd" is implemented only for positive integers' # TODO
    while n2 then [n1, n2] = [n2, n1 % n2]
    n1
)

@lcm = polymorphic(
  # 12 lcm 30   ->   60
  # 1  lcm 17   ->   17
  # 17 lcm 17   ->   17
  # 81 lcm 256  ->   20736
  # 4276309 lcm 8113579   ->   10036497223
  (n1, n2) -> n1 * (n2 / gcd [n1, n2])
)

@diag = polymorphic(
  # 3 diag 4            ->   5
  # 12 diag (-.5)       ->   13
  # diag.([2]*10+[3])   ->   7
  # diag.[$pi]          ->   $pi
  (q) ->
    r = 0
    for x in q
      if typeof x isnt 'number'
        # diag.[123;'(456)]   ->   error 'numbers'
        throw Error 'diag\'s argument must consist of numbers.'
      r += x * x
    Math.sqrt r
)

# Trigonometric functions
# TODO add tests when we have floating point numbers
@sin  = polymorphic (n) -> Math.sin  n
@cos  = polymorphic (n) -> Math.cos  n
@tan  = polymorphic (n) -> Math.tan  n
@asin = polymorphic (n) -> Math.asin n
@acos = polymorphic (n) -> Math.acos n
@atan = polymorphic (n1, n2) -> Math.atan2 n1, n2

@log = polymorphic(

  # 2 log 256             ->   8
  # 81 log 3              ->   1:4
  # $pi log (1:($pi^2))   ->   -.2
  # 1 log 0               ->   $ninf
  # TODO check for NaN
  (n1, n2) -> Math.log(n2) / Math.log(n1)
)

# TODO random n1 n2

# ===== Functions for sequences =====

# empty(...)
# empty.[]     ->   $t
# empty.'()    ->   $t
# empty.[1]    ->   $f
# empty.'a     ->   $f
# empty.0      ->   $f
# empty.[[]]   ->   $f
# empty.$f     ->   $f
# empty.$      ->   $f
@empty = (x) -> (x instanceof Array or typeof x is 'string') and x.length is 0

@fst = polymorphic(
  # fst.[1;2]   ->   1
  # fst."ab     ->   'a
  # TODO Should we return $ for an empty list/sequence?
  (q) -> if q.length then q[0] else null
)

@bst = polymorphic(
  # bst.[1;2]   ->   2
  # bst."ab     ->   'b
  # TODO Should we return $ for an empty list/sequence?
  (q) -> if q.length then q[q.length - 1] else null
)

@butf = polymorphic(
  # butf.[1;2;3]   ->   [2;3]
  # butf."abc      ->   "bc
  # butf.[1]       ->   []
  # butf.'a        ->   '()
  # butf.[]        ->   []
  # butf.'()       ->   '()
  (q) -> q[1...]
)

@butb = polymorphic(
  # butb.[1;2;3]   ->   [1;2]
  # butb."abc      ->   "ab
  # butb.[1]       ->   []
  # butb.'a        ->   '()
  # butb.[]        ->   []
  # butb.'()       ->   '()
  (q) -> q[...-1]
)

@rol = polymorphic(
  # rol.[1;2;3]   ->   [2;3;1]
  # rol."abc      ->   "bca
  # rol.[1]       ->   [1]
  # rol.'a        ->   'a
  # rol.[]        ->   []
  # rol.'()       ->   '()
  (q) -> q[1...].concat q[...1]
)

@ror = polymorphic(
  # ror.[1;2;3]   ->   [3;1;2]
  # ror."abc      ->   "cab
  # ror.[1]       ->   [1]
  # ror.'a        ->   'a
  # ror.[]        ->   []
  # ror.'()       ->   '()
  (q) -> q[-1...].concat q[...-1]
)

@cut = polymorphic(

  # 2 cut "abcde    ->   ["ab;"cde]
  # 0 cut [1;2;3]   ->   [[];[1;2;3]]
  # 3 cut [1;2;3]   ->   [[1;2;3];[]]
  # 0 cut '()       ->   ['();'()]
  # -.2 cut "abc    ->   ['a;"bc]
  # -.3 cut "abc    ->   ['();"abc]
  # TODO What to do with index out of bounds?
  (i, q) -> [q[...i], q[i...]]

  # _<3 cut [2;1;5;8;2;4]   ->   [[2;1];[5;8;2;4]]
  # _='a cut "abc           ->   ['a;"bc]
  # _='x cut "abc           ->   ['();"abc]
  # _<>'x cut "abc          ->   ["abc;'()]
  (f, q) ->
    i = 0
    while i < q.length and f q[i] then i++
    [q[...i], q[i...]]
)

@update = polymorphic(
  (q1, q2) ->
    if typeof q2 is 'string'
      # TODO What do we do in this case?
      throw Error 'Second argument to "update" cannot be a string.'
    if q1.length is 2 and q1[0] is ~~q1[0] and typeof q1[1] is 'function'
      # [1;_^2] update [1;2;3]     ->   [1;4;3]
      # [-.1;_^2] update [1;2;3]   ->   [1;2;9]
      # [3;_^2] update [1;2;3]     ->   $
      [i, f] = q1
      if i < 0 then i += q2.length
      if 0 <= i < q2.length
        q2[...i].concat [f q2[i]], q2[i + 1...]
      else
        null
    else if q1.length is 3 and typeof q1[0] is typeof q1[1] is 'function'
      # [_>3;_^2;99] update [1;2;3;4;5]   ->   [1;2;3;16;5]
      # [_>7;_^2;99] update [1;2;3;4;5]   ->   [1;2;3;4;5;99]
      [p, f, u] = q1
      r = null
      for x, i in q2 when p x
        r = q2[...i].concat [f x], q2[i + 1...]
        break
      r or q2.concat [u]
    else
      # [1;2] update [3;4]   ->   error 'Invalid first argument'
      throw Error 'Invalid first argument to "update"'
)

@before = polymorphic(
  (q1, q2) ->
    if typeof q2 is 'string'
      # TODO What do we do in this case?
      throw Error 'Second argument to "before" cannot be a string.'
    if q1.length is 2 and q1[0] is ~~q1[0]
      # [1;99] before [1;2;3]     ->   [1;99;2;3]
      # [-.1;99] before [1;2;3]   ->   [1;2;99;3]
      # [3;99] before [1;2;3]     ->   $
      [i, u] = q1
      if i < 0 then i += q2.length
      if 0 <= i < q2.length
        q2[...i].concat [u], q2[i...]
      else
        null
    else if q1.length is 3 and typeof q1[0] is typeof q1[1] is 'function'
      # [_>3;_^2;99] before [1;2;3;4;5]   ->   [1;2;3;16;4;5]
      # [_>7;_^2;99] before [1;2;3;4;5]   ->   [1;2;3;4;5;99]
      [p, f, u] = q1
      r = null
      for x, i in q2 when p x
        return q2[...i].concat [f x], q2[i...]
      q2.concat [u]
    else
      # ['a;2] before [3;4]   ->   error 'Invalid first argument'
      throw Error 'Invalid first argument to "before"'
)

@after = polymorphic(
  (q1, q2) ->
    if typeof q2 is 'string'
      # TODO What do we do in this case?
      throw Error 'Second argument to "after" cannot be a string.'
    if q1.length is 2 and q1[0] is ~~q1[0]
      # [1;99] after [1;2;3]     ->   [1;2;99;3]
      # [-.1;99] after [1;2;3]   ->   [1;2;3;99]
      # [3;99] after [1;2;3]     ->   $
      [i, u] = q1
      if i < 0 then i += q2.length
      if 0 <= i < q2.length
        q2[...i + 1].concat [u], q2[i + 1...]
      else
        null
    else if q1.length is 3 and typeof q1[0] is typeof q1[1] is 'function'
      # [_>3;_^2;99] after [1;2;3;4;5]   ->   [1;2;3;4;16;5]
      # [_>7;_^2;99] after [1;2;3;4;5]   ->   [99;1;2;3;4;5]
      [p, f, u] = q1
      r = null
      for x, i in q2 when p x
        return q2[...i + 1].concat [f x], q2[i + 1...]
      [u].concat q2
    else
      # ['a;2] after [3;4]   ->   error 'Invalid first argument'
      throw Error 'Invalid first argument to "after"'
)

# ===== Input/output functions =====

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

# Remember each built-in function's name in case we need it for debugging purposes
for k, v of @ when typeof v is 'function' then v.uName = k
