# This module will be made available to compiler output at runtime but it will
# not be directly accessible to user U code.

@withNewContext = (ctx, f) ->
  f Object.create(ctx)

# cart == @{[]::[[]];xs\xss::+>([]\(@{x::x\_!(@@.xss)}!xs))};
# ... cart.[[1;2];[3;4;5];[6;7]]
# ... -> [[1;3;6];[1;3;7];[1;4;6];[1;4;7];[1;5;6];[1;5;7];
# ...     [2;3;6];[2;3;7];[2;4;6];[2;4;7];[2;5;6];[2;5;7]]
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
