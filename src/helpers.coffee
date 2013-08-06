# This module will be made available to compiler output at runtime but it will
# not be directly accessible to user U code.

@withNewContext = (ctx, f) ->
  f Object.create(ctx)

# f == @{ :: @{ :: x} ++ x == 4}.$t; x == 5; f.$t   ->   4
# f == @{$t :: @{ :: @@}; $f :: 5}.$t; f.$t.$f      ->   5
@createLambda = (ctx, f) ->
  newCtx = Object.create ctx
  newCtx._parent = ctx
  newCtx._function = (x) -> f x, newCtx

@curryRight = (f, y) ->
  (x, ctx) ->
    f [x, y], ctx

@curryLeft  = (f, x) ->
  (y, ctx) ->
    f [x, y], ctx
