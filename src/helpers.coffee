# This module will be made available to compiler output at runtime but it will
# not be directly accessible to user U code.

@withNewContext = (ctx, f) ->
  f Object.create(ctx)

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
