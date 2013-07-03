_ = require '../../lib/underscore'

# polymorphic(...) combines a list of functions into a single function that
# does type dispatching.  For instance
#     polymorphic(
#       (n) --> sgn n
#       (n1, n2) --> n1 * n2
#       (s, i) --> Array(i + 1).join(s)
#       (q, i) --> r = []; (for [0...i] then r = r.concat q); r
#     )
# could be an implementation for the * function.
# It introspects parameter names for their initials and tries to coerce actual
# arguments to the respective types before passing them:
#     n   number or boolean
#     i   integer or boolean
#     b   boolean
#     q   sequence or string
#     s   string
#     p   picture
#     f   function
#     x   anything
# If coercion fails, we try the next polymorphic variant.
# If all variants fail, we throw an error.
@polymorphic = (fs...) ->
  signatures = _(fs).map (f) ->
    paramNames = f.toString().match(/^\s*function\s*\(([^\)]*)\)/)[1].split /\s*,\s*/
    _(paramNames).map((param) -> param[0]).join ''
  (a) ->
    for f, i in fs when (xs = coerce a, signatures[i]) then return f xs...
    throw Error """
      Unsupported operation,
      Argument: #{JSON.stringify a}
      Acceptable signatures: #{JSON.stringify signatures}
      Function name: #{JSON.stringify arguments.callee.uName}
    """

# coerce(...) takes an object `a` (which could be an array) and a type signature `ts` (which is a sequence of type
# initials) and tries to coerce `a` to the respective type or types.
# It returns either undefined or an array of coerced values.
coerce = (a, ts) ->
  if ts.length is 2
    if a instanceof Array and a.length is 2 and
            (x = coerce a[0], ts[0]) and
            (y = coerce a[1], ts[1])
      x.concat y
  else if ts.length is 1
    switch ts
      when 'n' then if typeof a in ['number', 'boolean'] then [+a]
      when 'i' then if typeof a in ['number', 'boolean'] and +a is ~~a then [+a]
      when 'b' then if typeof a is 'boolean' then [a]
      when 'q' then if a instanceof Array or typeof a is 'string' then [a]
      when 's' then if typeof a is 'string' then [a]
      when 'p' then undefined # TODO pictures
      when 'f' then if typeof a is 'function' then [a]
      when 'x' then [a]
      else throw Error 'Bad type symbol, ' + JSON.stringify ts
  else
    throw Error 'Bad type signature, ' + JSON.stringify ts

# When given a sequence `q' in case the sequence is actually a string (an array of characters) returns the string,
# otherwise preservers `q'. `original' is the collection that q was obtained from, used in order to return the proper
# type of result when q is empty - either '' or []
@qToString = (q, original) ->
  isChar = (c) ->
    typeof c is 'string' and c.length is 1

  return q unless q instanceof Array

  result = if (_(q).every isChar) then q.join('') else q
  if result.length > 0
    result
  else
    original[...0] # gives '' if original is a string and [] if original is a list

@uEqual = (x, y) ->
  _(x).isEqual y
