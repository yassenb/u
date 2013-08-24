_ = require '../lib/underscore'

{parse} = require './peg-parser/u-grammar'
stdlib = require './stdlib/all'
helpers = require './helpers'

@exec = (uCode, ctx) ->
  ctx ?= Object.create stdlib
  (eval """
    (function (ctx, helpers) {
        return #{compile uCode};
    })
  """) ctx, helpers

@compile = compile = (uCode) ->
  ast = parse uCode
  if ast is false
    throw Error 'Syntax error'
  renderJS ast

renderJS = (node) ->
  # 1 _ 1   ->   error 'currying'
  if node is '_'
    throw Error 'Invalid currying'

  switch node.type
    when 'programBody'
      # 1;2;3   ->   3
      statements = _(node.value).map (child) ->
        "(#{renderJS child})"
      "(#{statements.join ','})"

    when 'value'
      renderJS node.value

    when 'const'
      renderJS node.value

    when 'number'
      # 5     ->   5
      # ~5    ->   0 - 5
      # 0.1   ->   0.1
      node.value.replace /^~/, '-'

    when 'string'
      JSON.stringify(
        if /^'\(/.test node.value
          # '(')rock''n'roll) . 0   ->   ')
          # '(')rock''n'roll) . 1   ->   'r
          # '(')rock''n'roll) . 5   ->   ''
          # '(')rock''n'roll) . 7   ->   ''
          # '(')rock''n'roll) . 8   ->   'r
          # '(.(.) . 1              ->   '(()
          # '(.').) . 1             ->   ')
          # # . '('n't')'')           ->   4
          h = { n: '\n', t: '\t', ')': ')', "'": "'", '\n': '' }
          node.value[2...-1].replace /'[nt\)'\n]/g, (x) -> h[x[1]]
        else
          # 'a        ->   '(a)
          # "Toledo   ->   '(Toledo)
          node.value[1...]
      )

    when 'name'
      nameToJS node.value

    when 'dollarConstant'
      switch node.value
        when '$'     then 'null'
        when '$f'    then 'false'
        when '$t'    then 'true'
        when '$pinf' then 'Infinity'
        when '$ninf' then '(-Infinity)'
        when '$e'    then 'Math.E'
        when '$pi'   then 'Math.PI'
        when '$np'   then throw Error '$np is not implemented' # TODO
        else
          # $pinfinity   ->   error 'Unrecognised constant'
          throw Error 'Unrecognised constant, ' + JSON.stringify node.value

    when 'sequence'
      # sum . [3]     ->   3
      # sum . [1;2]   ->   3
      "[#{_(node.value).map(renderJS).join ','}]"

    when 'expr'
      # Initial "_" must be treated differently from subsequent "_"-s.
      if node.value[0].argument.value is '_'
        # _   ->   error 'single underscore'
        if node.value.length is 1
          throw Error 'A single underscore cannot be used as an expression.'

        if node.value[1].argument.value is '_'
          # currying on both sides returns the function itself
          # _+_ . [2;3]   ->   5
          result = renderJS node.value[1].operator
        else
          # (_+1) . 2   ->   3
          result = "helpers.curryRight(#{renderJS node.value[1].operator},#{renderJS node.value[1].argument})"

        i = 2
      else
        result = renderJS node.value[0].argument
        i = 1

      _(node.value[i..]).reduce(
        (result, expr) ->
          if expr.argument.value is '_'
            # (1+_) . 2   ->   3
            "helpers.curryLeft(#{renderJS expr.operator}, #{result})"
          else
            # 2                     ->   2
            # 2 + 3 + 4             ->   9
            # 2 + 3 @{ x :: 7 } 4   ->   7
            "(#{renderJS expr.operator})([#{result},#{renderJS expr.argument}])"
        result
      )

    when 'def'
      if node.value.assignment
        renderJS node.value.assignment
      else
        # {a == b ++ b == 6}; a                       ->   6
        # b == 7; {a == b ++ b == 6}; [a;b]           ->   [6;7]
        # {a == b; b == 7 ++ b == 6}; b               ->   7
        # {a == b ++ {b == c ++ c == 6}}; a           ->   6
        # b == 4; {a == b ++ {b == c ++ c == 6}}; b   ->   4
        # {_\(x\(y\(z\[[z1;z2]]))) == a ++ a == [0;1;2;3;[4;5]]}; [x;y;z;z1;z2]   ->   [1;2;3;4;5]
        #
        # The following uses the JS trick that once you clone an object with Object.create hasOwnProperty no longer
        # returns true for any of its fields, only for the ones created/set after the clone
        """
          (function (outerCtx) {
            var ctx = Object.create(outerCtx);
            #{renderJS node.value.local};
            ctx = Object.create(ctx);
            #{_(node.value.assignments).map(renderJS).join ';\n'};
            for (var name in ctx) {
              if (ctx.hasOwnProperty(name)) {
                outerCtx[name] = ctx[name];
              }
            }
            return null;
          }(ctx))
        """

    when 'assignment'
      # a == 1; a      ->   1
      # a == 2+1; a    ->   3
      # [x;y] == [1]   ->   error 'Pattern matching'
      renderPatternJS(node.value.pattern.value, renderJS node.value.expr) +
        ' || (function () { throw Error(\'Pattern matching failure\') })()'

    when 'local'
      _(node.value).map(renderJS).join ';\n'

    when 'closure'
      renderJS node.value

    when 'parametric'
      # {a + b ++ a == 6; b == 5}   ->   11
      # a == 4; {a ++ a == 6}; a    ->   4
      withLocal node.value.local, renderJS node.value.expr

    when 'conditional'
      # ?{$t :: 2; 3}                     ->   2
      # ?{$f :: 2; 3}                     ->   3
      # ?{6 * 8 = 42 :: 2}                ->   $
      # ?{$f :: 2; $t :: 3; 4}            ->   3
      # ?{$t :: x + 2 ++ x == 5}          ->   7
      # a == 4; ?{$t :: 5 ++ a == 6}; a   ->   4
      r = _(node.value.tests).reduce(
        (r, test) ->
          r + "(#{renderJS test.condition})?(#{renderJS test.expr}):"
        ''
      )
      r += if node.value.else then renderJS node.value.else else 'null'
      withLocal node.value.local, r

    when 'function'
      # no pattern and no guard
      # @{::} . 3       ->   $
      # @{:: 123} . 3   ->   123
      #
      # patterns
      # @{a :: a+2} . 3   ->   5
      # @{1 :: 2} . 1     ->   2
      # @{  1 :: 2;
      # ... 3 :: 5} . 3   ->   5
      #
      # guards
      # @{($t) :: 123} . 3              ->   123
      # x == 5; @{(x > 4) :: 123} . 3   ->   123
      # x == 5; @{(x > 5) :: 123;
      # ...       (x > 4) :: 7} . 3     ->   7
      #
      # both patterns and guards
      # @{a ($t) :: a+2} . 3   ->   5
      #
      # can have locals
      # @{x :: x+y ++ y==1} . 2            ->   3
      # x == 6; @{:: x ++ x == 5} . 2; x   ->   6
      #
      # static scoping
      # x==5; f==@{:: x}; {f . 1 ++ x == 6}   ->   5
      #
      # each clause is evaluated in its own context
      # x == 6; @{x (x > 5) :: 5; _ ($t) :: x} . 3   ->   6
      #
      # fucntions keep correct references to their context
      # f == @{$t :: @{ :: @@}; $f :: 5}.$t; f.$t.$f   ->   5
      resultJS = ''
      for { functionlhs: { value: { pattern, guard } }, body }, i in _(node.value.clauses).pluck 'value'
        # A missing pattern or guard defaults to that from the previous clause.
        #
        # @{x (x>5) :: 1;
        # ... (x>4) :: 2;
        # ... (x>3) :: 3} . 4   ->   3
        # @{  x (x>5) :: 1;
        # ...   (x>4) :: 2;
        # ... y (y>3) :: 2;
        # ...   (y>2) :: 3} . 3   ->   3
        #
        # @{x (x>5) :: 1;
        # ...       :: 1;
        # ...       :: 1;
        # ... ($t)  :: 2} . 4   ->   2
        # @{  x   (x>5)  :: 1;
        # ...            :: 1;
        # ...            :: 1;
        # ... x\y (x>3)  :: 2;
        # ... x          :: 3} . 4   ->   3
        resultingPattern = pattern or resultingPattern or node.value.clauses[i - 1]?.value.functionlhs.pattern
        resultingGuard = guard or resultingGuard or node.value.clauses[i - 1]?.value.functionlhs.guard

        # A missing body defaults to the next clause's body.
        #
        # @{  _ :: ;
        # ...   :: ;
        # ...   :: 1;
        # ...   :: 2} . 4   ->   1
        # @{  ($f) :: 1;
        # ... ($t) :: ;
        # ...      :: 2} . 4   ->   2
        unless body
          for clause in node.value.clauses[i+1..]
            if body = clause.value.body
              break

        resultJS += """
          helpers.withNewContext(ctx, function (ctx) {
              var enter = (#{if resultingPattern? then renderPatternJS resultingPattern.value, 'arg' else 'true'}) &&
                          (#{if resultingGuard? then renderJS resultingGuard.value else 'true'});
              if (enter) {
                  body = (#{if body? then renderJS body else 'null'});
              }
              return enter;
          }) ||
        """
      # @{1 :: 2} . 3      ->   error 'No function definition'
      # @{($f) :: 2} . 3   ->   error 'No function definition'
      resultJS += '(function () { throw Error(\'No function definition for given input\') })()'

      resultJS = """
        helpers.createLambda(ctx, function (arg, ctx) {
            var body = null;
            #{resultJS}
            return body;
        })
      """

      if node.value.local
        resultJS = """
          helpers.withNewContext(ctx, function (ctx) {
            ctx._function = #{resultJS};
            #{renderJS node.value.local};
            return ctx._function;
          })
        """

      resultJS

    else
      throw Error 'Compiler error: Unrecognised node type, ' + node.type

withLocal = (local, expression) ->
  if local?
    """
      helpers.withNewContext(ctx, function (ctx) {
        #{renderJS local};
        return #{expression};
      })
    """
  else
    expression

nameToJS = (name) ->
  if /^[a-z_\$][a-z0-9_\$]*$/i.test name
    "ctx.#{name}"
  else if name.match /^@+$/
    # @{n (n > 0) :: n\(@.(n-1));
    # ...    ($t) :: []}.3   ->   [3;2;1]
    # @{ $f :: @{ :: @{ :: @@@.$t }.$t}.$t;
    # ... _ :: 5}.$f   ->   5
    # @{  $f :: a;
    # ... _  :: 5
    # ... ++ a == @.$t} . $f   ->   5
    # @{  $t :: a;
    # ... $f :: 5
    # ... ++ a == @{$t :: @.$f; $f :: @@.$f}.$t} . $t   ->   5
    parentChain = ''
    _(name.length - 1).times ->
      parentChain += '._parent'
    """
      function (arg) {
        return ctx#{parentChain}._function(arg, ctx);
      }
    """
  else
    "ctx[#{JSON.stringify name}]"

# renderPatternJS() builds a JavaScript expression that evaluates to true when the pattern is matched. As a side effect
# during its evaluation, the expression may associate names with values in the current context.
renderPatternJS = (pattern, valueJS) ->
  if pattern.type is 'expr'
    return renderPatternJS pattern.value, valueJS

  if pattern.length is 1
    # TODO are "_ == 1" and "5 == 5" valid expressions?
    value = pattern[0].argument.value
    if value is '_'
      # [x;_] == [4;2]; x       ->   4
      # [x;_;_] == [5;4;2]; x   ->   5
      'true'
    else if value.type is 'const'
      value = value.value
      if value.type is 'name'
        # [x;y] == [1;2]; x + y   ->   3
        "#{nameToJS value.value}=(#{valueJS}),true"
      else
        # [a;1] == [2;1]; a      ->   2
        # ['a;a] == ['a;'b]; a   ->   'b
        # [$t;a] == [$t;5]; a    ->   5
        "#{valueJS}===(#{renderJS value})"
    else if value.type is 'expr'
      renderPatternJS value, valueJS
    # The rest of the value options use valueJS at least twice in the compiled code so we wrap the code in a closure to
    # prevent double computation.
    else if valueJS isnt 'v'
      wrapInClosure pattern, valueJS
    else if value.type is 'sequence'
      # [x;[y;z]] == [1;[2;3]]; x+y+z               ->   6
      # @{[] :: $t; _ :: $f} . []                   ->   $t
      # @{[x;[y;z]] :: $t; _ :: $f} . [1;[2;3;4]]   ->   $f
      # @{[x;[y;z]] :: $t; _ :: $f} . [1;[2]]       ->   $f
      # @{[x;[y;z]] :: $t; _ :: $f} . "abc          ->   $f
      sequence = value.value
      _(sequence).reduce(
        (r, elem, i) ->
          r + " && (#{renderPatternJS elem, "#{valueJS}[#{i}]"})"
        "#{valueJS} instanceof Array && #{valueJS}.length===#{sequence.length}"
      )
    else
      # { a ++ b == 6 } == 5   ->   error 'Invalid pattern'
      throw Error 'Invalid pattern'

  else
    # See the note about the call to wrapInClosure above
    unless valueJS is 'v'
      wrapInClosure pattern, valueJS

    # Apply only the last operation and invoke renderPatternJS recursively.
    pattern = _(pattern)
    operator = pattern.last().operator.value
    leftArg = pattern.initial()
    rightArg = [pattern.last()]

    operatorName = operator.type is 'const' and operator.value.type is 'name' and operator.value.value
    switch operatorName
      when '\\'
        # x\y==[1;2;3]; [x;y]         ->   [1;[2;3]]
        # x\(y\z)==[1;2;3]; [x;y;z]   ->   [1;2;[3]]
        # x\y\z==[[1;2];3]; [x;y;z]   ->   [1;[2];[3]]
        # x\y==[1]; [x;y]             ->   [1;[]]
        # x\y==[]                     ->   error 'Pattern'
        """
          #{valueJS} instanceof Array &&
          #{valueJS}.length > 0 &&
          (#{renderPatternJS leftArg, valueJS + '[0]'}) &&
          (#{renderPatternJS rightArg, valueJS + '.slice(1)'})
        """
      when '/'
        # x/y==[1;2]; [x;y]             ->   [[1];2]
        # x/y/z==[1;2;3]; [x;y;z]       ->   [[1];2;3]
        # x/(y/z)==[1;[2;3]]; [x;y;z]   ->   [[1];[2];3]
        # x/y==[1]; [x;y]               ->   [[];1]
        # x\y/z==[1;2;3]; [x;y;z]       ->   [1;[2];3]
        # x/y==[]                       ->   error 'Pattern'
        """
          #{valueJS} instanceof Array &&
          #{valueJS}.length > 0 &&
          (#{renderPatternJS leftArg, valueJS + '.slice(0,-1)'}) &&
          (#{renderPatternJS rightArg, "#{valueJS}[#{valueJS}.length - 1]"})
        """
      else
        # x+y == 3               ->   error 'pattern'
        # x (_/_) y == [1;2;3]   ->   error 'pattern'
        throw Error 'Invalid pattern, only \\ and / are allowed'

wrapInClosure = (pattern, valueJS) ->
  """
    (function (v) {
      return #{renderPatternJS pattern, 'v'};
    }(#{valueJS}))
  """
