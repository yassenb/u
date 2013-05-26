# This module will be made available to compiler output at runtime but it will
# not be directly accessible to user U code.

@createLambda = (ctx, f) -> (x) -> f x, Object.create ctx
@curryRight = (f, y) -> (x, ctx) -> f [x, y], ctx
@curryLeft  = (f, x) -> (y, ctx) -> f [x, y], ctx
