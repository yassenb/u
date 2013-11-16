{polymorphic} = require './base'
{'!': uMap} = require './nonverbal'

@id = id = polymorphic(
  # id . 2     ->   2
  # id . [2]   ->   [2]
  (x) -> x
)

@const = polymorphic(
  # const . 5 . 6     ->   5
  # const . [5] . 6   ->   [5]
  (x) ->
    -> x
)

@when = polymorphic(
  # (_ * 2) when $t . 3   ->   6
  # (_ * 2) when $f . 3   ->   3
  (f, b) ->
    if b then f else id
)

@on = polymorphic(
  # sum on (_ * 2) . [1;2;3]   ->   12
  (f1, f2) ->
    (q) ->
      f1 uMap [f2, q]

  # : on [sum;#] . [5;8;14]   ->   9
  # id on [] . [1;2]          ->   []
  (f, q) ->
    (x) ->
      g = (f) -> f(x)
      f uMap [g, q]
)

@beyond = polymorphic(
  # (_ + 1) beyond (_ < 5) . 1   ->   [4;5]
  # (_ + 1) beyond (_ < 1) . 1   ->   [$;1]
  (f1, f2) ->
    (x) ->
      a = null
      b = x
      while f2 b
        a = b
        b = f1 b

      [a, b]
)

# TODO witheq
