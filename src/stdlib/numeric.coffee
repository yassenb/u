{polymorphic} = require './base'

@int = polymorphic(
  # int![~1;0;1;$pi;-.$pi;$e;-.$e;$pinf;$ninf]   ->   [~1;0;1;3;~3;2;~2;$pinf;$ninf]
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
      # 2 gcd ~3      ->   error 'positive integers'
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
  # 12 diag ~5          ->   13
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
  # 81 log 3              ->   0.25
  # $pi log (1:($pi^2))   ->   ~2
  # 1 log 0               ->   $ninf
  # TODO check for NaN
  (n1, n2) -> Math.log(n2) / Math.log(n1)
)

# TODO random n1 n2
