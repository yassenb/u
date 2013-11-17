_ = require '../../lib/underscore'

{polymorphic, qToString, uEqual} = require './base'

@['+'] = polymorphic(
  # 1 + 1          ->   2
  # $t + $t        ->   2
  # 2 + $t         ->   3
  # $t + 2         ->   3
  (n1, n2) -> n1 + n2

  # [1] + [2;3]         ->   [1;2;3]
  # [] + [2;3]          ->   [2;3]
  # [1;2;3] + []        ->   [1;2;3]
  # '(hell)+'o          ->   "hello
  # "hello+'()          ->   "hello
  # '(hell)+"no         ->   "hellno
  # "hell + [66]        ->   ['h;'e;'l;'l;66]
  # [2;66] + "hell      ->   [2;66;'h;'e;'l;'l]
  # ['h;'e] + ['l;'l]   ->   "hell
  # [] + '()            ->   []
  # '() + []            ->   '()
  (q1, q2) ->
    qToString _(q1).toArray().concat(_(q2).toArray()), q1
)

@['-'] = polymorphic(
  # -.3    ->   ~3
  (n) -> -n

  # 3 - 1     ->   2
  # 2 - 3     ->   ~1
  (n1, n2) -> n1 - n2

  # "mississippi-"dismiss   ->   "sippi
  # "apple-['p;4;'l]        ->   "ape
  # [8;1;5;5;1;5;5;1;9;9;1]-[0;1;5;8;1;5;5]  ->  [5;1;9;9;1]
  # [1;2;3;4;5] - [1;4;7]    ->   [2;3;5]
  # [[1;2];[3;4]] - [[1;2]]  ->   [[3;4]]
  # [1;2] - []              ->
  # [] - '()                ->   []
  # '() - []                ->   '()
  (q1, q2) ->
    qToString(
      _(_(q2).toArray()).foldl(
        # remove the first occurence of x in result (if any)
        (result, x) ->
          for y, i in result when uEqual(x, y)
            result.splice i, 1 # remove the i-th element from result
            break
          result
        _(q1).toArray()
      )
      q1
    )
)

@['*'] = polymorphic(
  # * . 123         ->   1
  # * . ~123        ->   ~1
  # * . 0           ->   0
  (n) -> (n > 0) - (n < 0) # signum

  # 2 * 3           ->   6
  (n1, n2) -> n1 * n2

  # [2;5]*3         ->   [2;5;2;5;2;5]
  # "abc*2          ->   "abcabc
  # [17]*0          ->   []
  # "abc*0          ->   '()
  # ['h;'e] * 2     ->   "hehe
  # TODO should we allow i*q as well?
  # [2;5]*~1        ->   error 'non-negative'
  (q, i) ->
    if i < 0
      throw Error 'Multiplier for sequence or string must be non-negative.'
    r = []
    _(i).times -> r.push _(q).toArray()...
    qToString r, q
)

@['^'] = polymorphic(
  # 2^3     ->   8
  # 3^2     ->   9
  # ~1^2    ->   1
  # ~1^~1   ->   ~1
  (n1, n2) -> Math.pow n1, n2

  # (_+[1;2]^3).[777]     ->   [777;1;2;1;2;1;2]
  # @{x::'<\x/'>}^3."xy   ->   '(<<<xy>>>)
  (f, i) ->
    if i < 0 then throw Error 'Obverse functions are not supported.'
    (a) ->
      _(i).times -> a = f a
      a
)

@[':'] = polymorphic(
  # :.3     ->   1:3
  # :.$pi   ->   1:$pi
  # :.0     ->   $pinf
  (n) -> 1 / n

  # 1:0     ->   $pinf
  # 119:7   ->   17
  (n1, n2) -> n1 / n2

  # "abcdefghijkl:5   ->   ["abc;"def;"gh;"ij;"kl]
  # [1;2;3;4]:1       ->   [[1;2;3;4]]
  # [1;2;3;4]:2       ->   [[1;2];[3;4]]
  # [1;2;3;4]:3       ->   [[1;2];[3];[4]]
  # [1;2;3;4]:4       ->   [[1];[2];[3];[4]]
  # [1;2;3;4]:5       ->   [[1];[2];[3];[4];[]]
  # []:3              ->   [[];[];[]]
  # [1;2;3]:~1        ->   error 'must be positive'
  (q, i) ->
    if i <= 0 then throw Error 'Sequence denominator must be positive.'
    r = q.length % i
    l = (q.length - r) / i
    l1 = l + 1
    (q[j * l1 ... (j + 1) * l1] for j in [0...r])
      .concat(q[j * l + r ... (j + 1) * l + r] for j in [r...i])

  # 5:"abcdefghijkl   ->   ["abcde;"fghij;"kl]
  # 1:[1;2;3;4]       ->   [[1];[2];[3];[4]]
  # 2:[1;2;3;4]       ->   [[1;2];[3;4]]
  # 3:[1;2;3;4]       ->   [[1;2;3];[4]]
  # 4:[1;2;3;4]       ->   [[1;2;3;4]]
  # 5:[1;2;3;4]       ->   [[1;2;3;4]]
  # 3:[]              ->   []
  # ~1:[1;2;3]        ->   error 'must be positive'
  (i, q) ->
    if i <= 0 then throw Error 'Sequence numerator must be positive.'
    q[j...j+i] for j in [0...q.length] by i
)

@['<:'] = polymorphic(
  # <:.$pi       ->   3
  # <:.(-.$pi)   ->   ~4
  (n) -> Math.floor n

  # 34<:~5    ->   [~7;~1]
  # ~1.2<:1   ->   [~2;0.8]
  (n1, n2) -> [(q = Math.floor n1 / n2), n1 - q * n2]
)

@['>:'] = polymorphic(
  # >:.$pi       ->   4
  # >:.(-.$pi)   ->   ~3
  (n) -> Math.ceil n

  # 34>:~5    ->   [~6;4]
  # ~1.5>:1   ->   [~1;~0.5]
  (n1, n2) -> [(q = Math.ceil n1 / n2), n1 - q * n2]
)

@['|:'] = polymorphic(
  # |:.$pi       ->   3
  # |:.(-.$pi)   ->   ~3
  # |:.$e        ->   3
  # |:.0.5       ->   0
  # |:.1.5       ->   2
  # |:.~0.5      ->   0
  # |:.~1.5      ->   ~2
  round = (n) ->
    x = Math.floor n
    d = n - x
    if d < .5 then x
    else if d > .5 then x + 1
    else x + Math.abs(x) % 2

  # 34|:~5    ->   [~7;~1]
  # TODO should rounding really be like in |: for one argument?
  # 3|:2      ->   [2;~1]
  (n1, n2) -> [(q = round n1 / n2), n1 - q * n2]
)

@['<'] = polymorphic(
  # 12 < 3   ->   $f
  # 1 < 23   ->   $t
  # 1 < 1    ->   $f
  (n1, n2) -> n1 < n2

  # '(12) < '3   ->   $t
  # '() < '( )   ->   $t
  # 'A < 'a      ->   $t
  # 'b < 'a      ->   $f
  # "ab < "abc   ->   $t
  # "ab < "aac   ->   $f
  (s1, s2) -> s1 < s2

  #  3<"abcdefgh     ->   "abc
  # ~3<"abcdefgh     ->   "defgh
  #  3<"ab           ->   "ab
  # ~3<"ab           ->   '()
  #  3<[1;2;3;4;5]   ->   [1;2;3]
  # ~3<[1;2;3;4;5]   ->   [4;5]
  #  3<[1;2]         ->   [1;2]
  # ~3<[1;2]         ->   []
  # 3<['h;'e;'l;6]   ->   "hel
  (i, q) ->
    aq = _(q).toArray()
    qToString (if i >= 0 then aq[...i] else aq[-i...]), q

  # -<[6;3;9;2]   ->   10
  # -<[123]       ->   123
  # -<[]          ->   $
  # +<"abcd       ->   "abcd
  # -<'()         ->   $
  (f, q) ->
    qToString _(_(q[...-1]).toArray()).foldr(
      (init, x) -> f [x, init]
      _(q).last() or null
    )

  # <.(sum on _).[_^2;1;2;3]   ->   14
  # <.(_ * 3 ^ _).[2;1;2;3]    ->   [1;2;3] * 9
  # <.@{ :: @{x :: x}}.[2]     ->   []
  # <.(_ * 3 ^ _).[]           ->   error 'non-empty sequences'
  (f) ->
    (q) ->
      unless (q instanceof Array) and q.length > 0
        throw Error 'Functions obtained via <.f work only on non-empty sequences'
      f(q[0])(q[1..])
)

@['<='] = polymorphic(
  # 12 <= 3   ->   $f
  # 1 <= 23   ->   $t
  # 1 <= 1    ->   $t
  (n1, n2) -> n1 <= n2

  # '(12) <= '3   ->   $t
  # '() <= '( )   ->   $t
  # 'A <= 'a      ->   $t
  # 'b <= 'a      ->   $f
  (s1, s2) -> s1 <= s2
)

# TODO what is equality?
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
  (x1, x2) -> uEqual(x1, x2)
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
  (x1, x2) -> not uEqual(x1, x2)
)

@['>='] = polymorphic(
  # 12 >= 3   ->   $t
  # 1 >= 23   ->   $f
  # 1 >= 1    ->   $t
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
  (n1, n2) -> n1 > n2

  # '(12) > '3   ->   $f
  # '() > '( )   ->   $f
  # 'A > 'a      ->   $f
  # 'b > 'a      ->   $t
  (s1, s2) -> s1 > s2

  #  3>"abcdefgh     ->   "fgh
  # ~3>"abcdefgh     ->   "abcde
  #  3>"ab           ->   "ab
  # ~3>"ab           ->   '()
  #  3>[1;2;3;4;5]   ->   [3;4;5]
  # ~3>[1;2;3;4;5]   ->   [1;2]
  #  3>[1;2]         ->   [1;2]
  # ~3>[1;2]         ->   []
  # 3>[6;'h;'e;'l]   ->   "hel
  (i, q) ->
    aq = _(q).toArray()
    aq =
      if i >= 0
        aq[Math.max(0, q.length - i)...]
      else
        aq[...Math.max(0, q.length + i)]
    qToString aq, q

  # - > [6;3;9;2]   ->   ~8
  # - > [123]       ->   123
  # - > []          ->   $
  # + > "abcd       ->   "abcd
  # - > '()         ->   $
  # [2;3;~5;1] @{[cs;x]:: @{[v;c]::v*x+c} > cs} 2   ->   19
  (f, q) ->
    qToString _(_(q[1..]).toArray()).foldl(
      (init, x) -> f [init, x]
      q[0] or null
    )

  # {f.4 ++ dv == >.:; f==dv.100}       ->   25
  # {f.3 ++ dv == >.:; f==dv."abcdef}   ->   ["ab;"cd;"ef]
  (f) ->
    (x) ->
      (y) ->
        y = [y] unless y instanceof Array
        f [x].concat(y)
)

member = (xs, x) ->
  _(xs).some((y) -> uEqual(x, y))

@['|'] = polymorphic(
  # |.123    ->   123
  # |.~123   ->   123
  # |.0      ->   0
  (n) -> Math.abs n

  # $f|$f   ->   $f
  # $f|$t   ->   $t
  # $t|$t   ->   $t
  # $t|$f   ->   $t
  (b1, b2) -> b1 or b2

  # 3|5     ->   5
  # ~3|$t   ->   1
  (n1, n2) -> Math.max n1, n2

  # "star|"trek        ->   "starek
  # '()|"abracadabra   ->   "abrcd
  # [5;7;4;2]|[7;2;3;8]          ->   [5;7;4;2;3;8]
  # []|[4;6;2;4;0;4;8;4;6;2;4]   ->   [4;6;2;0;8]
  # [1;2;'b;3] | "abc  ->   [1;2;'b;3;'a;'c]
  # "abc | [1;2;'b;3]  ->   ['a;'b;'c;1;2;3]
  # "abc | '()         ->   "abc
  # '() | []           ->   '()
  # [] | '()           ->   []
  (q1, q2) ->
    q1a = _(q1).toArray()
    qToString q1a.concat(
      _(_(_(q2).toArray()).filter (x) -> not member(q1a, x)).unique()
    ), q1

  # 4(|.:)5   ->   1.25
  # |.@{x :: x}.4   ->   error 'too few arguments'
  (f) ->
    (a) ->
      throw Error 'Function obtained via |.f called with too few arguments' if a not instanceof Array or a.length < 2
      f [a[1], a[0]].concat a[2...]
)

@['&'] = polymorphic(
  # $f&$f   ->   $f
  # $f&$t   ->   $f
  # $t&$f   ->   $f
  # $t&$t   ->   $t
  (b1, b2) -> b1 and b2

  # 12&34    ->   12
  # ~2&34    ->   ~2
  # ~2&~3    ->   ~3
  (n1, n2) -> Math.min n1, n2

  # "aqua&"neutral      ->   "aua
  # "aqua&'()           ->   '()
  # '()&"aqua           ->   '()
  # "aqua&"aqua         ->   "aqua
  # [1;2;3;1]&[4;5;3;6;7;1;8]   ->   [1;3;1]
  # [1;2;3]&[]                  ->   []
  # []&[1;2;3]                  ->   []
  # [1;2;3]&[1;2;3]             ->   [1;2;3]
  # [1;2;'b;3] & "abc   ->   "b
  # "abc & [1;2;'b;3]   ->   "b
  # "abc & '()          ->   '()
  # '() & []            ->   '()
  # [] & '()            ->   []
  (q1, q2) ->
    qToString _(_(q1).toArray()).filter(
      (x) -> member(_(q2).toArray(), x)
    ), q1
)

@[','] = polymorphic(
  # ~2,3   ->   [~2; ~1; 0; 1; 2]
  # 0,5    ->   [0;1;2;3;4]
  # 5,0    ->   [5;4;3;2;1]
  # 5,5    ->   []
  # $e,5   ->   [$e; 1+$e; 2+$e]
  (n1, n2) -> [n1...n2]

  # 1,[10;3]      ->   [1;4;7]
  # 10,[1;~3]     ->   [10;7;4]
  # 10,[1;3]      ->   []
  # $pi,[10;$e]   ->   [$pi; $pi+$e; $pi+(2*$e)]
  # 1,[1;3]       ->   []
  # 1,[5;0]       ->   []
  # 1,[5]         ->   error 'arguments'
  # 1,[1;3;4]     ->   error 'arguments'
  # 1,"ab         ->   error 'arguments'
  (n1, q) ->
    if q not instanceof Array or q.length isnt 2 or
            typeof q[0] not in ['number', 'boolean'] or
            typeof q[1] not in ['number', 'boolean']
      throw Error '"," takes arguments of type either "n1,n2" or "n1,[n2;n3]".'
    n2 = +q[0]
    n3 = +q[1]
    i for i in [n1...n2] by n3
)

@[',,'] = polymorphic(
  # ~2,,3   ->   [~2; ~1; 0; 1; 2; 3]
  # 0,,5    ->   [0;1;2;3;4;5]
  # 5,,0    ->   [5;4;3;2;1;0]
  # 5,,5    ->   [5]
  # $e,5    ->   [$e; 1+$e; 2+$e]
  (n1, n2) -> [n1..n2]

  # 1,,[10;3]         ->   [1;4;7;10]
  # 10,,[1;~3]        ->   [10;7;4;1]
  # 10,,[1;3]         ->   []
  # $pi,,[10;$e]      ->   [$pi; $pi+$e; $pi+(2*$e)]
  # 1,,[5;0]          ->   []
  # 1,,[5]            ->   error 'arguments'
  # 1,,[1;3;4]        ->   error 'arguments'
  # 1,,"ab            ->   error 'arguments'
  (n1, q) ->
    if q not instanceof Array or q.length isnt 2 or
            typeof q[0] not in ['number', 'boolean'] or
            typeof q[1] not in ['number', 'boolean']
      throw Error '",," takes arguments of type either "n1,n2" or "n1,[n2;n3]".'
    n2 = +q[0]
    n3 = +q[1]
    i for i in [n1..n2] by n3
)

@['#'] = polymorphic(
  # #."abc        ->   3
  # #.'a          ->   1
  # #.[1;2;3]     ->   3
  # 123#[4;5;6]   ->   2
  # #.[]          ->   0
  (q) -> q.length
)

@['\\'] = polymorphic(
  # 'a\"bc        ->   "abc
  # "ab\"de       ->   ["ab;'d;'e]
  # 1\[2;3]       ->   [1;2;3]
  # 1\[]          ->   [1]
  # [1;2]\[3;4]   ->   [[1;2];3;4]
  # []\[1;2]      ->   [[];1;2]
  # 'a\[1;2]      ->   ['a;1;2]
  # '()\"abc      ->   ['();'a;'b;'c]
  (x, q) ->
    x = [x] unless typeof x is 'stirng' and x.length is 1
    qToString _(x).toArray().concat(_(q).toArray())

  # 1\2           ->   [1;2]
  (x1, x2) -> [x1, x2]
)

@['/'] = polymorphic(
  # "ab/'c        ->   "abc
  # "ab/"de       ->   ['a;'b;"de]
  # [1;2]/3       ->   [1;2;3]
  # []/1          ->   [1]
  # [1;2]/[3;4]   ->   [1;2;[3;4]]
  # [1;2]/[]      ->   [1;2;[]]
  # [1;2]/'a      ->   [1;2;'a]
  # '()/'c        ->   "c
  # '()/"ab       ->   ["ab]
  (q, x) ->
    x = [x] unless typeof x is 'stirng' and x.length is 1
    qToString _(q).toArray().concat(_(x).toArray())

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
  (f) ->
    (a) ->
      if typeof (r = f a) is 'boolean' then not r else null

  # ~ . "abc           ->   "cba
  # ~ . '()            ->   '()
  # ~ . [1;2;3]        ->   [3;2;1]
  # ~ . []             ->   []
  # ~ . ['h;'e;'l;6]   ->   [6;'l;'e;'h]
  (q) ->
    qToString _(q).toArray().reverse(), q
)

@['!'] = polymorphic(
  # :![]          ->   []
  # _^2![1;2;3]   ->   [1;4;9]
  # _+'x!"abc     ->   ["ax;"bx;"cx]
  # _+'x!'()      ->   '()
  # @{xs::_<xs!(0,,(#.xs))} . "abc        ->   ['();'a;"ab;"abc]
  # @{xs::_>xs!(#.xs,,0)}   . "abc        ->   ["abc;"bc;'c;'()]
  # [1;1;2;3;4;5;6;0;0;9]._![4;2;_=0;5]   ->   [4;2;7;5]
  (f, q) ->
    qToString _(_(q).toArray()).map(f), q

  # [_<5;_^2]![3;1;5;17;4]   ->   [9;1;5;17;16]
  # [_<>'o;_+'a]!"Bonn       ->   ["Ba;'o;"na;"na]
  # [_<5;_^2]![]             ->   []
  # [_='a;_+'a]!'()          ->   '()
  # []![]                    ->   error 'two functions'
  # [+;1]![]                 ->   error 'two functions'
  (q1, q2) ->
    if q1 not instanceof Array or q1.length isnt 2 or not (typeof q1[0] is typeof q1[1] is 'function')
      throw Error 'When "!" is used in the form "q1!q2", "q1" must be a sequence of two functions.'
    [p, f] = q1
    qToString(
      (if p x then f x else x) for x in _(q2).toArray()
      q2
    )
)

@['%'] = polymorphic(
  # _<4 % [5;2;4;1;3]   ->   [2;1;3]
  # _<4 % [5]           ->   []
  # _<4 % []            ->   []
  # _='l % "hell        ->   "ll
  # _='b % '()          ->   '()
  # q=="abcd; q._>>(_<>'b)%(0,(#.q))   ->   [0;2;3]
  (f, q) ->
    qToString _(_(q).toArray()).filter(f), q

  # [_<5;_^2]%[3;1;5;17;4]   ->   [9;1;16]
  # [_<>'o;_+'a]%"Bonn       ->   ["Ba;"na;"na]
  # [_<5;_^2]%[]             ->   []
  # [_='a;_+'a] % "hell      ->   '()
  # [_='a;_+'a] % '()        ->   '()
  # []%[]                    ->   error 'two functions'
  # [+;1]%[]                 ->   error 'two functions'
  (q1, q2) ->
    if q1 not instanceof Array or q1.length isnt 2 or not (typeof q1[0] is typeof q1[1] is 'function')
      throw Error 'When "%" is used in the form "q1%q2", "q1" must be a sequence of two functions.'
    [p, f] = q1
    qToString(
      f x for x in _(q2).toArray() when p x
      q2
    )
)

@['%%'] = polymorphic(
  # _<'d %% "acebd            ->   ["acb;"ed]
  # _<'d %% '()               ->   ['();'()]
  # _<4 %% [1;3;5;2;4]        ->   [[1;3;2];[5;4]]
  # _<4 %% []                 ->   [[];[]]
  # _<>'e %% [1;2;'h;'e;'l]   ->   [[1;2;'h;'l];"e]
  (f, q) ->
    qa = _(_(q).toArray())
    [qToString(qa.filter(f), q),
     qToString(qa.filter((x) -> not f(x)), q)]
)

@['||'] = polymorphic(
  #  ||.[[0;1];
  # ...  [3;4];
  # ...  [6;7]]
  # ...                                        ->   [[0;3;6];
  # ...                                              [1;4;7]]
  # x == [1;2;3]; y == [4;5;6]; +>(*!(x||y))   ->   32
  # ||>>(*!_)>>sum.[[1;2;3];[4;5;6]]           ->   32
  # n == 5; k == 3; @{[[a;b];c]::c*a:b}<({_+(n-k)!x||x ++ x==k,0}/1)   ->   10
  # ||.[[0;1;2];[3;4;5];[6;7]]                 ->   [[0;3;6];[1;4;7]]
  # ||.[]                                      ->   []
  # ||.[[];[1];[1;2]]                          ->   []
  # ||.[[1;2;3]]                               ->   [[1];[2];[3]]
  # ||.["ab;"cd;"ef]                           ->   ["ace;"bdf]
  # ||.["a;"c;"e]                              ->   ["ace]
  (q) ->
    unless q instanceof Array and
    _(q).every((e) ->
      e instanceof Array or typeof e is 'string'
    )
      throw Error 'The argument to || must be a sequence of sequences.'

    return [] if q.length is 0

    l = Math.min((_(q).map (e) -> e.length)...)
    q = _(q).map (e) -> _(e).first(l)
    _(_.zip(q...)).map((e) -> qToString e, e)
)

@['.'] = polymorphic(
  # +.[1;2]  ->  3
  (f, x) -> f x

  # [1;2;3].0     ->   1
  # [1;2;3].2     ->   3
  # "hello.1      ->   'e
  # [1;2].~1      ->   2
  # "abc.~2       ->   'b
  # [1;2;3].3     ->   $
  # "hello.10     ->   $
  # [1;2].~3      ->   $
  # [].0          ->   $
  # '().0         ->   $
  (q, i) ->
    if 0 <= i < q.length then q[i]
    else if -q.length <= i < 0 then q[q.length + i]
    else null

  # [1;2;0;4;5].(_=0)   ->   2
  # [1;2;3;4;5].(_=6)   ->   $
  # "abc.(_='b)         ->   1
  # [].@{ :: $t}        ->   $
  (q, f) ->
    for x, i in q when f x then return i
    null
)

@['=>'] = polymorphic(
  # 1 => (2*_) => (_+3) => (4^_)   ->   1024
  # 1 => (2*_)                     ->   2
  (x, f) -> f x
)

@['>>'] = polymorphic(
  # (1+_)>>(2*_) . 3   ->   8
  (f1, f2) ->
    (a) -> f2 f1 a
)

@['<<'] = polymorphic(
  # (1+_)<<(2*_) . 3   ->   7
  (f1, f2) ->
    (a) -> f1 f2 a
)
