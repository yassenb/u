_ = require '../../lib/underscore'

{polymorphic, qToString, uEqual} = require './base'

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
  # fst.[]      ->   $
  # fst.'()     ->   $
  (q) -> if q.length then q[0] else null
)

@bst = polymorphic(
  # bst.[1;2]   ->   2
  # bst."ab     ->   'b
  # bst.[]      ->   $
  # bst.'()     ->   $
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

@cut = cut = polymorphic(
  # 2 cut "abcde         ->   ["ab;"cde]
  # 0 cut [1;2;3]        ->   [[];[1;2;3]]
  # 3 cut [1;2;3]        ->   [[1;2;3];[]]
  # 0 cut '()            ->   ['();'()]
  # 0 cut []             ->   [[];[]]
  # ~2 cut "abc          ->   ['a;"bc]
  # ~3 cut "abc          ->   ['();"abc]
  # 2 cut ['h;'e;'l;6]   ->   ["he;['l;6]]
  # TODO What to do with index out of bounds?
  (i, q) -> [qToString(q[...i], q), qToString(q[i...], q)]

  # _<3 cut [2;1;5;8;2;4]   ->   [[2;1];[5;8;2;4]]
  # _='a cut "abc           ->   ['a;"bc]
  # _='x cut "abc           ->   ['();"abc]
  # _<>'x cut "abc          ->   ["abc;'()]
  # _<>6 cut ['h;'e;'l;6]   ->   ["hel;[6]]
  (f, q) ->
    i = 0
    while i < q.length and f q[i] then ++i

    cut [i, q]
)

@update = polymorphic(
  (q1, q2) ->
    # [1;_^2] update [1;2;3]              ->   [1;4;3]
    # [~1;_^2] update [1;2;3]             ->   [1;2;9]
    # [1;@{ :: 'x}] update "abc           ->   "axc
    # [1;@{ :: 'x}] update ['h;'e;'l;6]   ->   ['h;'x;'l;6]
    # [3;@{ :: 'l}] update ['h;'e;'l;6]   ->   "hell
    # [3;@{ :: 6}] update "hell           ->   ['h;'e;'l;6]
    # [3;_^2] update [1;2;3]              ->   $
    # [0;_^2] update '()                  ->   $
    # [0;_^2] update []                   ->   $
    if q1.length is 2 and q1[0] is ~~q1[0] and typeof q1[1] is 'function'
      [i, f] = q1
      if i < 0 then i += q2.length
      if 0 <= i < q2.length
        q2a = _(q2).toArray()
        qToString q2a[...i].concat([f q2a[i]], q2a[i + 1...])
      else
        null
    # [_>3;_^2;99] update [1;2;3;4;5]          ->   [1;2;3;16;5]
    # [_>7;_^2;99] update [1;2;3;4;5]          ->   [1;2;3;4;5;99]
    # [_='b;@{ :: 'x};$] update "abc           ->   "axc
    # [_='e;@{ :: 'x};$] update ['h;'e;'l;6]   ->   ['h;'x;'l;6]
    # [_=6;@{ :: 'l};$] update ['h;'e;'l;6]    ->   "hell
    # [_='h;@{ :: 6};$] update "hell           ->   [6;'e;'l;'l]
    # [_='a;_^2;'a] update '()                 ->   "a
    # [_='a;_^2;3] update '()                  ->   [3]
    # [_='a;_^2;3] update []                   ->   [3]
    # [_='a;_^2;'a] update []                  ->   "a
    else if q1.length is 3 and typeof q1[0] is typeof q1[1] is 'function'
      [p, f, u] = q1
      result = null
      q2a = _(q2).toArray()
      for x, i in q2 when p x
        result = q2a[...i].concat [f x], q2a[i + 1...]
        break
      qToString(result or q2a.concat [u])
    # [1;2] update [3;4]   ->   error 'Invalid first argument'
    else
      throw Error 'Invalid first argument to "update"'
)

@before = polymorphic(
  (q1, q2) ->
    # [1;99] before [1;2;3]        ->   [1;99;2;3]
    # [~1;99] before [1;2;3]       ->   [1;2;99;3]
    # [1;'a] before "abc           ->   "aabc
    # [2;'l] before ['h;'e;'l;6]   ->   ['h;'e;'l;'l;6]
    # [3;99] before [1;2;3]        ->   $
    # [0;6] before []              ->   $
    # [0;'a] before '()            ->   $
    if q1.length is 2 and q1[0] is ~~q1[0]
      [i, u] = q1
      if i < 0 then i += q2.length
      if 0 <= i < q2.length
        q2a = _(q2).toArray()
        qToString q2a[...i].concat([u], q2a[i...])
      else
        null
    # [_>3;_^2;99] before [1;2;3;4;5]          ->   [1;2;3;16;4;5]
    # [_>7;_^2;99] before [1;2;3;4;5]          ->   [1;2;3;4;5;99]
    # [_='l;@{ :: 'l};$] before "hel           ->   "hell
    # [_='l;@{ :: 'l};$] before ['h;'e;'l;6]   ->   ['h;'e;'l;'l;6]
    # [_>3;_^2;6] before []                    ->   [6]
    # [_='a;_^2;'b] before '()                 ->   "b
    else if q1.length is 3 and typeof q1[0] is typeof q1[1] is 'function'
      [p, f, u] = q1
      result = null
      q2a = _(q2).toArray()
      for x, i in q2 when p x
        result = q2a[...i].concat [f x], q2a[i...]
        break
      qToString(result or q2a.concat [u])
    else
      # ['a;2] before [3;4]   ->   error 'Invalid first argument'
      throw Error 'Invalid first argument to "before"'
)

@after = polymorphic(
  (q1, q2) ->
    # [1;99] after [1;2;3]        ->   [1;2;99;3]
    # [~1;99] after [1;2;3]       ->   [1;2;3;99]
    # [1;'a] after "abc           ->   "abac
    # [2;'l] after ['h;'e;'l;6]   ->   ['h;'e;'l;'l;6]
    # [3;99] after [1;2;3]        ->   $
    # [0;6] after []              ->   $
    # [0;'a] after '()            ->   $
    if q1.length is 2 and q1[0] is ~~q1[0]
      [i, u] = q1
      if i < 0 then i += q2.length
      if 0 <= i < q2.length
        q2a = _(q2).toArray()
        qToString q2a[...i + 1].concat([u], q2[i + 1...])
      else
        null
    # [_>3;_^2;99] after [1;2;3;4;5]          ->   [1;2;3;4;16;5]
    # [_>7;_^2;99] after [1;2;3;4;5]          ->   [99;1;2;3;4;5]
    # [_='l;@{ :: 'l};$] after "hel           ->   "hell
    # [_='l;@{ :: 'l};$] after ['h;'e;'l;6]   ->   ['h;'e;'l;'l;6]
    # [_>3;_^2;6] after []                    ->   [6]
    # [_='a;_^2;'b] after '()                 ->   "b
    else if q1.length is 3 and typeof q1[0] is typeof q1[1] is 'function'
      [p, f, u] = q1
      result = null
      q2a = _(q2).toArray()
      for x, i in q2 when p x
        result = q2a[...i + 1].concat [f x], q2a[i + 1...]
        break
      qToString (result or [u].concat q2a)
    # ['a;2] after [3;4]   ->   error 'Invalid first argument'
    else
      throw Error 'Invalid first argument to "after"'
)

@count = polymorphic(
  # _>3 count [4;1;3;5;1]     ->   2
  # _='s count "mississippi   ->   4
  # _>3 count [1;2]           ->   0
  # _>3 count []              ->   0
  (f, q) ->
    r = 0
    for x in q when f x then ++r
    r
)

@min = polymorphic(
  # min . "abc   ->   error 'not defined'
  (s) ->
    throw Error '"min" is not defined for strings'

  # min . [3;1;2]   ->   1
  # min . [3]       ->   3
  # min . []        ->   $pinf
  (q) ->
    _(q.concat [Infinity]).min()
)

@max = polymorphic(
  # max . "abc   ->   error 'not defined'
  (s) ->
    throw Error '"max" is not defined for strings'

  # max . [3;1;2]   ->   3
  # max . [3]       ->   3
  # max . []        ->   $ninf
  (q) ->
    _(q.concat [-Infinity]).max()
)

@sum = polymorphic(
  # sum . "abc   ->   error 'not defined'
  (s) ->
    throw Error '"sum" is not defined for strings'

  # sum . [4;1;2]   ->   7
  # sum . [3]       ->   3
  # sum . []        ->   0
  (q) ->
    _(q).reduce(
      (init, x) -> init + x
      0
    )
)

@prod = polymorphic(
  # prod . "abc   ->   error 'not defined'
  (s) ->
    throw Error '"prod" is not defined for strings'

  # prod . [4;1;2]   ->   8
  # prod . [3]       ->   3
  # prod . []        ->   1
  (q) ->
    _(q).reduce(
      (init, x) -> init * x
      1
    )
)

@and = polymorphic(
  # and . "abc   ->   error 'not defined'
  (s) ->
    throw Error '"and" is not defined for strings'

  # and . [$t]         ->   $t
  # and . [$f]         ->   $f
  # and . [$t;$t;$t]   ->   $t
  # and . [$t;$t;$f]   ->   $f
  # and . []           ->   $t
  (q) ->
    _(q).every _.identity
)

@or = polymorphic(
  # or . "abc   ->   error 'not defined'
  (s) ->
    throw Error '"or" is not defined for strings'

  # or . [$t]         ->   $t
  # or . [$f]         ->   $f
  # or . [$f;$f;$t]   ->   $t
  # or . [$f;$f;$f]   ->   $f
  # or . []           ->   $f
  (q) ->
    _(q).some _.identity
)

@all = polymorphic(
  # [$t] all @{x :: x}           ->   $t
  # [$f] all @{x :: x}           ->   $f
  # [$t;$t;$t] all @{x :: x}     ->   $t
  # [$t;$t;$f] all @{x :: x}     ->   $f
  # "bcd all (_ > 'a)            ->   $t
  # "abc all (_ > 'a)            ->   $f
  # ['h;'e;'l;6] all @{x :: x}   ->   $t
  # ['h;'e;'l;6] all (_ = 6)     ->   $f
  # [] all @{x :: x}             ->   $t
  # '() all @{x :: x}            ->   $t
  (q, f) ->
    qToString _(_(q).toArray()).every f
)

@any = any = polymorphic(
  # [$t] any @{x :: x}           ->   $t
  # [$f] any @{x :: x}           ->   $f
  # [$f;$f;$t] any @{x :: x}     ->   $t
  # [$f;$f;$f] any @{x :: x}     ->   $f
  # "bcd any (_ > 'c)            ->   $t
  # "abc any (_ > 'c)            ->   $f
  # ['h;'e;'l;6] any (_ = 6)     ->   $t
  # ['h;'e;'l;6] any (_ = 7)     ->   $f
  # [] any @{x :: x}             ->   $f
  # '() any @{x :: x}            ->   $f
  (q, f) ->
    qToString _(_(q).toArray()).some f
)

@in = uIn = polymorphic(
  # 1 in [3;1;2]     ->   $t
  # 4 in [3;1;2]     ->   $f
  # 4 in [4]         ->   $t
  # 'e in "hell      ->   $t
  # 'i in "hell      ->   $f
  # 6 in ['h;'e;6]   ->   $t
  # 4 in []          ->   $f
  # 'a in '()        ->   $f
  (x, q) ->
    any [q, (e) -> uEqual(e, x)]
)

@assv = assv = polymorphic(
  # assv . [[[1;"one]; [2;"two]]; 2]           ->   "two
  # assv . [[[1;"one]; [2;"two]; [2;"to]]; 2]  ->   "two
  # assv . [[[1;"one]; [2;"two]]; 4]           ->   $
  # assv . [[]; 4]                             ->   $
  # assv . [[1;2]; 4]                          ->   error 'Invalid argument'
  (q, x) ->
    assv [q, x, null]

  # assv . [[[1;"one];[2;"two]]; 4; "four]   ->   "four
  (q, x1, x2) ->
    for x in _(q).toArray()
      unless x instanceof Array and x.length is 2
        throw Error 'Invalid argument to "assv". Expecting a sequence of key-value pairs'
      return x[1] if uEqual(x[0], x1)

    x2
)

@scanl = polymorphic(
  # - scanl [6;3;9;2]       ->   [6;3;~6;~8]
  # - scanl [123]           ->   [123]
  # - scanl []              ->   []
  # + scanl "abcd           ->   ["a;"ab;"abc;"abcd]
  # - scanl '()             ->   []
  # @{ :: 'a} scanl "bcde   ->   ['b;'a;'a;'a]
  (f, q) ->
    _(_(q[1..]).toArray()).foldl(
      (init, x) ->
        init.concat [f [_(init).last(), x]]
      if q[0] then [q[0]] else []
    )
)

@scanr = polymorphic(
  # - scanr [6;3;9;2]       ->   [2;7;~4;10]
  # - scanr [123]           ->   [123]
  # - scanr []              ->   []
  # + scanr "abcd           ->   ["d;"cd;"bcd;"abcd]
  # - scanr '()             ->   []
  # @{ :: 'a} scanr "abcd   ->   ['d;'a;'a;'a]
  (f, q) ->
    _(_(q[...-1]).toArray()).foldr(
      (init, x) ->
        init.concat [f [x, _(init).last()]]
      if q.length > 0 then [_(q).last()] else []
    )
)

@from = polymorphic(
  # from . [@{ x (x < 4) :: [x; x + 1]; ($t) :: $}; 1]   ->   [1;2;3]
  # from . [@{ :: $}; 1]                                 ->   []
  # from . [@{ :: 5}; 1]                                 ->   error 'function'
  (f, x) ->
    result = []
    while true
      fresult = f x
      if fresult is null
        break
      else if fresult instanceof Array and fresult.length is 2
        result.push fresult[0]
        x = fresult[1]
      else
        throw Error 'The function given to "from" should return either $ or a sequence of two elements'
    result
)

@iterate = polymorphic(
  # iterate . [@{x :: 2 * x}; 0; 1]    ->   [1]
  # iterate . [@{x :: 2 * x}; 1; 1]    ->   [1; 2]
  # iterate . [@{x :: 2 * x}; 4; 1]    ->   [1; 2; 4; 8; 16]
  # iterate . [@{x :: 2 * x}; ~3; 1]   ->   error 'non-negative'
  (f, i, x) ->
    throw Error 'iterate takes a non-negative number' if i < 0

    result = [x]
    _.times i, -> result.push f(_(result).last())
    result
)

@eqseq = eqseq = polymorphic(
  # [1;2;3] eqseq [1;2;3]           ->   $t
  # [1;[2;4];3] eqseq [1;[2;4];3]   ->   $t
  # [1;[2;4];3] eqseq [1;[2;5];3]   ->   $f
  # [1;2] eqseq [1;2;3]             ->   $f
  # [] eqseq []                     ->   $t
  # [] eqseq [1]                    ->   $f
  # "abc eqseq "abc                 ->   $t
  # "abc eqseq ['a;'b;'c]           ->   $t
  # '() eqseq '()                   ->   $t
  # '() eqseq []                    ->   $t
  (q1, q2) ->
    q1a = _(q1).toArray()
    q2a = _(q2).toArray()
    _(_(q1a).zip q2a).every ([x1, x2]) -> uEqual x1, x2
)

@asprefix = asprefix = polymorphic(
  # [1;2] asprefix [1;2;3]   ->   [[1;2]; [3]]
  # [1;2] asprefix [1;2]     ->   [[1;2]; []]
  # [] asprefix [1;2]        ->   [[]; [1;2]]
  # [1;2] asprefix [1;3;4]   ->   $f
  # [1;2] asprefix [1]       ->   $f
  # [1;2] asprefix []        ->   $f
  # [1;2] asprefix [3;1;2]   ->   $f
  # "he asprefix "hell       ->   ["he; "ll]
  # "he asprefix ['h;'e;6]   ->   ["he; [6]]
  (q1, q2) ->
    q1a = _(q1).toArray()
    q2a = _(q2).toArray()
    if q1a.length <= q2a.length and eqseq [q1a, q2a[...q1a.length]]
      [qToString(q1a, q2), qToString(q2a[q1a.length..], q2)]
    else
      false
)

@assuffix = polymorphic(
  # [2;3] assuffix [1;2;3]   ->   [[1]; [2;3]]
  # [1;2] assuffix [1;2]     ->   [[]; [1;2]]
  # [] assuffix [1;2]        ->   [[1;2]; []]
  # [2;4] assuffix [1;3;4]   ->   $f
  # [1;2] assuffix [1]       ->   $f
  # [1;2] assuffix []        ->   $f
  # [1;2] assuffix [1;2;3]   ->   $f
  # "ll assuffix "hell       ->   ["he; "ll]
  # "he assuffix [6;'h;'e]   ->   [[6]; "he]
  (q1, q2) ->
    q1a = _(q1).toArray()
    q2a = _(q2).toArray()
    prefixLength = q2a.length - q1a.length
    if q1a.length <= q2a.length and eqseq [q1a, q2a[prefixLength..]]
      [qToString(q2a[...prefixLength], q2), qToString(q1a, q2)]
    else
      false
)

@asinfix = polymorphic(
  # [1;2] asinfix [1;2;3]            ->   [[]; [1;2]; [3]]
  # [1;2] asinfix [3;1;2]            ->   [[3]; [1;2]; []]
  # [3;4] asinfix [1;2;3;4;5]        ->   [[1;2]; [3;4]; [5]]
  # [1;2] asinfix [1;2]              ->   [[]; [1;2]; []]
  # [] asinfix [1;2]                 ->   [[]; []; [1;2]]
  # [1] asinfix []                   ->   $f
  # [1;2] asinfix [2;3;4]            ->   $f
  # [1;2] asinfix [1]                ->   $f
  # "el asinfix "hello               ->   ["h;"el;"lo]
  # "he asinfix "hello               ->   ['(); "he; "llo]
  # ['l;6] asinfix ['h;'e;'l;6;'l]   ->   ["he; ['l;6]; "l]
  (q1, q2) ->
    prefix = []
    for x, i in q2
      if rest = asprefix [q1, q2[i..]]
        return [qToString(prefix, q2), rest[0], rest[1]]
      prefix.push x

    false
)

@assort = polymorphic(
  # assort . [1;2;3;2;1;1]   ->   [[1;1;1]; [2;2]; [3]]
  # assort . [1;1]           ->   [[1;1]]
  # assort . [1]             ->   [[1]]
  # assort . []              ->   []
  # assort . "mississippi    ->   [['m]; ['i;'i;'i;'i]; ['s;'s;'s;'s]; ['p;'p]]
  (q) ->
    _(_(q).toArray()).foldl(
      (init, x) ->
        for s in init
          if uEqual(_(s).last(), x)
            s.push x
            return init
        init.concat [[x]]
      []
    )
)

@split = polymorphic(
  # '(words, and, commas) split [',]          ->   ["words; '( and); '( commas)]
  # '(words, and, commas,) split [',]         ->   ["words; '( and); '( commas)]
  # '(words, and, commas) split [',;' ]       ->   ["words; "and; "commas]
  # '(words, and, commas space) split '(, )   ->   ["words; "and; "commas; "space]
  # '(words, and, commas) split []            ->   ['(words, and, commas)]
  # "abc split [',]                           ->   ["abc]
  # '() split [',]                            ->   []
  # [1;2;0;4;5] split [0]                     ->   [[1;2]; [4;5]]
  # ['h;'e;6;'l;'l] split [6]                 ->   ["he; "ll]
  (q1, q2) ->
    result = []
    inq2 = (x) -> uIn [x, q2]
    while true
      [notUsed, q1] = cut [inq2, q1]
      [part, q1] = cut [((x) -> not inq2(x)), q1]
      break if part.length is 0
      result.push part
    result
)

ensureSequence = (e, errorMessage) ->
  unless e instanceof Array or typeof e is 'string'
    throw Error errorMessage
  e

@join = polymorphic(
  # "word join [0]   ->   error 'sequence of sequences'
  (s, q) ->
    throw Error '"join" expects a sequence of sequences to join'

  # ["words; "and; "commas] join ',        ->   '(words,and,commas)
  # ["words; "and; "commas] join '(, )     ->   '(words, and, commas)
  # ["words; "and; '(); "commas] join ',   ->   '(words,and,,commas)
  # ["he;"ll] join '()                     ->   "hell
  # ['();'()] join '()                     ->   '()
  # [[];'()] join '()                      ->   []
  # ["word] join ',                        ->   "word
  # [[1;2];[3]] join [0]                   ->   [1;2;0;3]
  # [] join [0]                            ->   []
  # ["he;"ll] join [6]                     ->   ['h;'e;6;'l;'l]
  # [1;2] join [0]                         ->   error 'sequence of sequences'
  (q1, q2) ->
    return [] if q1.length is 0

    ensureSeq = (e) -> ensureSequence e, '"join" expects a sequence of sequences to join'

    result = _(q1[1..]).foldl(
      (init, e) ->
        init.concat _(q2).toArray().concat _(ensureSeq(e)).toArray()
      _(ensureSeq q1[0]).toArray()
    )
    qToString result, q1[0]
)

@flatten = flatten = polymorphic(
  # flatten . 5                      ->   5
  # flatten . []                     ->   []
  # flatten . [[]]                   ->   []
  # flatten . [5]                    ->   [5]
  # flatten . [[5]]                  ->   [5]
  # flatten . [[5];6;[];[7;[8;9]]]   ->   [5;6;7;8;9]
  # flatten . '()                    ->   '()
  # flatten . "hell                  ->   "hell
  # flatten . ["hell;"no]            ->   ["hell;"no]
  (x) ->
    return x unless x instanceof Array
    _(x).foldl(
      (init, v) ->
        init.concat if v instanceof Array then flatten(v) else [v]
      []
    )
)

@cart = polymorphic(
  # cart . "abc   ->   error 'sequence of sequences'
  (s) ->
    throw Error '"cart" expects a sequence of sequences'

  # cart . [[1;2]; [3;4;5]; [6;7]]   ->   [[1;3;6];[1;3;7];[1;4;6];[1;4;7];[1;5;6];[1;5;7];
  # ...                                    [2;3;6];[2;3;7];[2;4;6];[2;4;7];[2;5;6];[2;5;7]]
  # cart . [[1;2]; [3]; [6;7]]       ->   [[1;3;6];[1;3;7];[2;3;6];[2;3;7]]
  # cart . [[1;2]; "ab]              ->   [[1;'a]; [1;'b]; [2;'a]; [2;'b]]
  # cart . ["ab; "cd]                ->   ["ac;"ad;"bc;"bd]
  # cart . [[1;2]]                   ->   [[1];[2]]
  # cart . [[1;2]; []; [6;7]]        ->   []
  # cart . []                        ->   [[]]
  # cart . [[];[]]                   ->   []
  (q) ->
    ensureSeq = (e) -> ensureSequence e, '"cart" expects a sequence of sequences'

    _(_(q).foldr(
      (init, x) ->
        products = _(_(ensureSeq x).toArray()).map (e) ->
          _(init).map (product) ->
            [e].concat product
        [].concat(products...)
      [[]]
    )).map (e) -> qToString e, []
)

@sort = sort = polymorphic(
  # sort . [<;[2;1;5;3;4]]                  ->   [1;2;3;4;5]
  # sort . [<;[1]]                          ->   [1]
  # sort . [<;[]]                           ->   []
  # sort . [<;"sorted]                      ->   "deorst
  # sort . [<;'()]                          ->   '()
  # sort . [@{[a;b] :: a.0 < (b.0)};
  # ...     [[2;0]; [3;0]; [2;1]; [1;0]]]   ->   [[1;0]; [2;0]; [2;1]; [3;0]]
  (f, q) ->
    # The retarded built-in Array.splice takes N arguments instead of an array of arguments which naturally exceeds
    # the stack size limit.
    splice = (a, offset, newElements) ->
      i = 0
      while i < newElements.length
        a[offset + i] = newElements[i]
        ++i
      null

    # JavaScript's sort doesn't guarantee stability in all browsers.
    qsort = (a, l, r) ->
      if r - l > 0
        pivot = a[l]
        ua = _(a[(l + 1)..r])
        leftPart = ua.filter (x) -> f([x, pivot])
        rightPart = ua.filter (x) -> not f([x, pivot])

        splice(a, l, leftPart)
        pivotIndex = l + leftPart.length
        splice(a, pivotIndex, [pivot])
        splice(a, pivotIndex + 1, rightPart)

        qsort(a, l, pivotIndex - 1)
        qsort(a, pivotIndex + 1, r)

      a

    sorted = qsort(_(q).toArray(), 0, q.length - 1)
    qToString sorted, q
)

@grade = polymorphic(
  # grade . [<;[2;1;5;3;4]]                  ->   [1;0;3;4;2]
  # grade . [<;[1]]                          ->   [0]
  # grade . [<;[]]                           ->   []
  # grade . [<;"sorted]                      ->   [5;4;1;2;0;3]
  # grade . [<;'()]                          ->   []
  # grade . [@{[a;b] :: a.0 < (b.0)};
  # ...      [[2;0]; [3;0]; [2;1]; [1;0]]]   ->   [3;0;2;1]
  (f, q) ->
    a = _(_(q).toArray()).map (e, i) -> [e, i]
    comparator = ([[e1, i1], [e2, i2]]) ->
      f [e1, e2]
    _(sort [comparator, a]).map ([e, i]) -> i
)
