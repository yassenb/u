{polymorphic} = require './base'

@nil = nil = polymorphic(
  # nil . $     ->   $t
  # nil . 0     ->   $f
  # nil . $f    ->   $f
  # nil . []    ->   $f
  # nil . '()   ->   $f
  # nil . id    ->   $f
  (x) ->
    x == null
)

@val = polymorphic(
  # val . $     ->   $f
  # val . 0     ->   $t
  # val . $f    ->   $t
  # val . []    ->   $t
  # val . '()   ->   $t
  # val . id    ->   $t
  (x) ->
    not nil x
)

# TODO pictures
@type = polymorphic(
  # type . 0         ->   "num
  # type . $f        ->   "boo
  # type . '()       ->   "str
  # type . 'a        ->   "str
  # type . "hello    ->   "str
  # type . []        ->   "seq
  # type . [1;2]     ->   "seq
  # type . id        ->   "fun
  # type . (_ + 2)   ->   "fun
  # type . $         ->   "nil
  (x) ->
    if x == null
      'nil'
    else if typeof x is 'number'
      'num'
    else if typeof x is 'boolean'
      'boo'
    else if typeof x is 'string'
      'str'
    else if x instanceof Array
      'seq'
    else if typeof x is 'function'
      'fun'
    else
      throw Error 'unrecognized type'
)

@next = polymorphic(
  # 5 next 6   ->   6
  (x1, x2) ->
    x2
)

@prev = polymorphic(
  # 5 prev 6   ->   5
  (x1, x2) ->
    x1
)
