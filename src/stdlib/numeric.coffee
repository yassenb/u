_ = require '../../lib/underscore'

{polymorphic} = require './base'
{Random} = require './util/random'

@int = polymorphic(
  # int.~1        ->   ~1
  # int.0         ->   0
  # int.1         ->   1
  # int.$pi       ->   3
  # int.(-.$pi)   ->   ~3
  # int.$e        ->   2
  # int.(-.$e)    ->   ~2
  (n) ->
    if n >= 0 then Math.floor n else Math.ceil n
)

# TODO rat n i

@gcd = gcd = polymorphic(
  # 12 gcd 30   ->   6
  # 1  gcd 17   ->   1
  # 17 gcd 17   ->   17
  # 81 gcd 256  ->   1
  # 4276309 gcd 8113579   ->   3457
  # 2 gcd ~3      ->   error 'positive integers'
  # $e gcd $pi    ->   error 'positive integers'
  # 7 gcd $pinf   ->   error 'positive integers'
  (n1, n2) ->
    if n1 isnt ~~n1 or n2 isnt ~~n2 or n1 <= 0 or n2 <= 0
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
  # 12 diag ~5          ->   13
  # diag.([2]*10+[3])   ->   7
  # diag.[$pi]          ->   $pi
  # diag.[]             ->   0
  # diag.[123;'(456)]   ->   error 'numbers'
  (q) ->
    result = _(q).foldl(
      (init, x) ->
        if typeof x isnt 'number'
          throw Error 'diag\'s argument must consist of numbers.'
        init + x * x
      0
    )
    Math.sqrt result
)

@sin  = polymorphic (n) -> Math.sin  n
@cos  = polymorphic (n) -> Math.cos  n
@tan  = polymorphic (n) -> Math.tan  n
@asin = polymorphic (n) -> Math.asin n
@acos = polymorphic (n) -> Math.acos n
@atan = polymorphic (n1, n2) -> Math.atan2 n1, n2

@log = polymorphic(
  # 2 log 256             ->   8
  # 81 log 3              ->   0.25
  # $pi log (1:($pi^2))   ->   ~2
  # 1 log 0               ->   $ninf
  # 2 log ~1              ->   $
  (n1, n2) ->
    result = Math.log(n2) / Math.log(n1)
    if _(result).isNaN() then null else result
)

rand = new Random
@random = polymorphic(
  # a == random . [5; ~1]; a < 5 & (a >= 0)    ->   $t
  # random . [4.5; ~1] < 5                     ->   $t
  # a == random . [1; ~1]; a < 1 & (a >= 0)    ->   $t
  # a == random . [0; ~1]; a < 1 & (a >= 0)    ->   $t
  # a == random . [~5; ~1]; a < 1 & (a >= 0)   ->   $t
  #     [random . [100; 6]; random . [100; ~1]; random . [100; ~1]] =
  # ... [random . [100; 6]; random . [100; ~1]; random . [100; ~1]]   ->   $t
  (n1, n2) ->
    # TODO how does rounding happen, like in |: or like in JS?
    n1 = Math.round(n1)
    n2 = Math.round(n2)

    rand.reSeed(n2) if n2 >= 0

    if n1 >= 2
      rand.randn(n1)
    else
      rand.randf()
)
