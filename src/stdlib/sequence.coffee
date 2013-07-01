{polymorphic} = require './base'

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
  # ~2 cut "abc     ->   ['a;"bc]
  # ~3 cut "abc     ->   ['();"abc]
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
      # [~1;_^2] update [1;2;3]   ->   [1;2;9]
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
      # [~1;99] before [1;2;3]    ->   [1;2;99;3]
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
      # [~1;99] after [1;2;3]    ->   [1;2;3;99]
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

@count = polymorphic(
  # _>3 count [4;1;3;5;1]     ->   2
  # _='s count "mississippi   ->   4
  (f, q) ->
    r = 0
    for x in q when f x then r++
    r
)
