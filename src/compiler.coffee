_ = require '../lib/underscore'

{parse} = require './peg-parser/u-grammar'
stdlib = require './stdlib'
helpers = require './helpers'

@exec = (uCode, ctx) ->
  ctx ?= Object.create stdlib
  (new Function """
    var ctx     = arguments[0],
        helpers = arguments[1];
    return #{compile uCode};
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

  keys = _(node).keys()
  unless keys.length is 1
    throw Error 'Compiler error'
  exprType = keys[0]

  node = node[exprType]
  switch exprType
    when 'program'
      # 1;2;3   ->   3
      statements = _(node).map (child) ->
        "(#{renderJS child})"
      "(#{statements.join ','})"

    when 'const'
      renderJS node

    when 'number'
      # 5           ->   5
      # ~5          ->   0 - 5
      # 0-5         ->   ~5
      # 0.1         ->   0.1
      # 0.1 + 0.9   ->   1
      node.replace /^~/, '-'

    when 'string'
      JSON.stringify(
        if /^'\(/.test node
          # '(')rock''n'roll)   ->   '(')rock''n'roll)
          # '(()                ->   '(()
          # '('))               ->   ')
          # #.'('n't')'')       ->   4
          # '(abc'
          # ...def)             ->   "abcdef
          h = { n: '\n', t: '\t', ')': ')', "'": "'", '\n': '' }
          node[2...-1].replace /'[nt\)'\n]/g, (x) -> h[x[1]]
        else
          # 'a                  ->   '(a)
          # "Toledo             ->   '(Toledo)
          node[1...]
      )

    when 'name'
      nameToJS node

    when 'dollarConstant'
      switch node
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
          throw Error 'Unrecognised constant, ' + JSON.stringify node

    when 'sequence'
      # + . [1;2]   ->   3
      "[#{_(node.elements).map(renderJS).join ','}]"

    when 'expr'
      # 2 + 3 + 4             ->   9
      # 2 + 3 @{ x :: 7 } 4   ->   7

      # Initial "_" must be treated differently from subsequent "_"-s.
      if node[0].argument is '_'
        if node.length is 1
          throw Error 'A single underscore cannot be used as an expression.'

        if node[1].argument is '_'
          # _+_   ->   +
          r = renderJS node[1].operator # currying on both sides returns the function itself
        else
          # (_+1).2   ->   3
          r = "helpers.curryRight(#{renderJS node[1].operator},#{renderJS node[1].argument})"

        i = 2
      else
        r = renderJS node[0].argument
        i = 1

      _(node[i..]).reduce(
        (r, expr) ->
          if expr.argument is '_'
            # (1+_).2   ->   3
            "helpers.curryLeft(#{renderJS expr.operator}, #{r})"
          else
            "(#{renderJS expr.operator})([#{r},#{renderJS expr.argument}])"
        r
      )

    when 'def'
      if node.assignment
        renderJS node
      # {a == b ++ b == 6}; a   ->   6
      # b == 7; {a == b ++ b == 6}; [a;b]   ->   [6;7]
      # {_\(x\(y\(z\[[z1;z2]]))) == a ++ a == [0;1;2;3;[4;5]]}; [x;y;z;z1;z2]   ->   [1;2;3;4;5]
      else
        assignments = node.assignments
        namesToExport = assignmentNames assignments
        """
          helpers.assignmentsWithLocal(ctx,
            function (ctx) {
              #{renderJS node.local};
              #{_(assignments).map(renderJS).join ';\n'};
            },
            [#{_(namesToExport).map(JSON.stringify).join(',')}])
        """

    when 'assignment'
      # a==1; a             ->   1
      # a==2+1; a           ->   3
      renderPatternJS node.pattern, renderJS _(node).pick('expr')

    when 'defs'
      _(node).map(renderJS).join ';\n'

    when 'closure'
      renderJS node

    when 'parametric'
      # {a + b ++ a == 6; b == 5}   ->   11
      # TODO it's better if all .pick()-s are removed and the things they pick - named to avoid reconstructing parts of
      # the AST in the compiler
      withLocal node.local, renderJS _(node).pick('expr')

    when 'conditional'
      # ?{1::2;3}   ->   2
      # ?{0::2;3}   ->   3
      # ?{0::2}     ->   $
      # TODO negative test cases
      # ?{$f::2;$t::3;4}   ->   3
      # ?{x::2;y::3;4 ++ x==$f; y==$t}   ->   3
      r = _(node.tests).reduce(
        (r, test) ->
          r + "(#{renderJS test.condition})?(#{renderJS _(test).pick 'expr'}):"
        ''
      )
      r += if node.else then renderJS node.else else 'null'
      withLocal node.local, r

    when 'function'
      # @{:: 123} . 3                      ->   123
      # @{a :: a+2} . 3                    ->   5
      # x==5; @{:: x} . $                  ->   5
      # x==5; f==@{:: x}; x==6; f . x      ->   6
      # TODO the above test is wrong---a name cannot be associated with multiple values
      # TODO test that creating a new function creates a new context
      # @{1 :: 2} . 1                      ->   2
      # @{1 :: 2} . 3                      ->   $
      # @{x :: x+y ++ y==1} . 2            ->   3
      # @{a (1) :: a+2} . 3                ->   5
      # @{(1) :: 123} . 3                  ->   123
      # @{a (0) :: a+2; a ($t) :: 6} . 3   ->   6
      # 5 @{[x;y]::x+y+y} 3                ->   11
      # @{[x;y]::x+y+y} . 3                ->   $
      #
      # each clause should be evaluated in its own context
      # x == 6; @{x (x > 5) :: 5; _ ($t) :: x} . 3   ->   6
      resultJS = ''
      for { clause: { functionlhs: { pattern, guard }, body } }, i in node.clauses
        # A missing pattern or guard defaults to that from the previous clause.
        # @{x (x>5) :: 1;
        # ... (x>4) :: 2;
        # ... (x>3) :: 3} . 4   ->   3
        # @{x (x>5) :: 1;
        # ...       :: 1;
        # ...       :: 1;
        # ... ($t)  :: 2} . 4   ->   2
        # @{  _ :: ;
        # ...   :: ;
        # ...   :: 1;
        # ...   :: 2} . 4   ->   1
        resultingPattern = pattern or resultingPattern or node.clauses[i - 1]?.clause.functionlhs.pattern
        resultingGuard = guard or resultingGuard or node.clauses[i - 1]?.clause.functionlhs.guard

        # A missing body defaults to the next clause's body.
        unless resultingBody = body or resultingBody
          for clause in node.clauses[i+1..]
            if body = clause.clause.body
              resultingBody = body
              break

        resultJS += """
          helpers.withNewContext(ctx, function (ctx) {
              var enter = (#{if resultingPattern? then renderPatternJS resultingPattern, 'arg' else 'true'}) &&
                          (#{if resultingGuard? then renderJS resultingGuard else 'true'});
              if (enter) {
                  body = (#{if resultingBody? then renderJS resultingBody else 'null'});
              }
              return enter;
          }) ||
        """
      resultJS += 'null'

      resultJS = """
        helpers.createLambda(ctx, function (arg, ctx) {
            var body = null;
            #{resultJS};
            return body;
        })
      """

      if node.local
        resultJS = """
          helpers.withNewContext(ctx, function (ctx) {
            ctx._function = #{resultJS};
            #{renderJS node.local};
            return ctx._function;
          })
        """

      resultJS
    else
      throw Error 'Compiler error: Unrecognised node type, ' + exprType

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
  else if name.match /^@+$/
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
  if pattern.expr
    return renderPatternJS pattern.expr, valueJS

  if pattern.length is 1
    value = pattern[0].argument
    if value is '_'
      # _==1; $   ->   $
      'true'
    else if konst = value.const
      if name = konst.name
        # a==1; a+a   ->   2
        "#{nameToJS name}=(#{valueJS}),true"
      else
        # [a;1]==[2;1]; a      ->   2
        # ['a;a]==['a;'b]; a   ->   'b
        # [$t;$f;$pinf;$;a]==[$t;$f;$pinf;$;[1;2;3]]; a   ->   [1;2;3]
        "#{valueJS}===(#{renderJS konst})"
    else if value.expr
      renderPatternJS value, valueJS
    # The rest of the value options use valueJS at least twice in the compiled code so we wrap the code in a closure to
    # prevent double computation.
    else if valueJS isnt 'v'
      wrapInClosure pattern, valueJS
    else if seq = value.sequence?.elements
      # [x;[y;z]]==[1;[2;3]]; x+y+z   ->   6
      # @{[] :: $t; _ :: $f} . []     ->   $t
      _(seq).reduce(
        (r, elem, i) ->
          r + " && (#{renderPatternJS elem, "#{valueJS}[#{i}]"})"
        "#{valueJS} instanceof Array && #{valueJS}.length===#{seq.length}"
      )
    else  # value.closure
      # TODO test
      throw Error 'Invalid pattern, pattern can\'t be a closure'

  else
    # See the note about the call to wrapInClosure above
    unless valueJS is 'v'
      wrapInClosure pattern, valueJS

    # Apply only the last operation and invoke renderPatternJS recursively.
    pattern = _(pattern)
    operator = pattern.last().operator
    leftArg = pattern.initial()
    rightArg = [_(pattern.last()).pick('argument')]

    switch operator.const?.name
      when '\\'
        # x\y==[1;2;3]; [x;y]         ->   [1;[2;3]]
        # x\(y\z)==[1;2;3]; [x;y;z]   ->   [1;2;[3]]
        # x\y\z==[[1;2];3]; [x;y;z]   ->   [1;[2];[3]]
        # x\y==[1]; [x;y]             ->   [1;[]]
        """
          #{valueJS} instanceof Array &&
          #{valueJS}.length &&
          (#{renderPatternJS leftArg, valueJS + '[0]'}) &&
          (#{renderPatternJS rightArg, valueJS + '.slice(1)'})
        """
      when '/'
        # x/y==[1;2]; [x;y]         ->   [[1];2]
        # x/y/z==[1;2;3]; [x;y;z]   ->   [[1];2;3]
        # x\y/z==[1;2;3]; [x;y;z]   ->   [1;[2];3]
        """
          #{valueJS} instanceof Array &&
          #{valueJS}.length &&
          (#{renderPatternJS leftArg, valueJS + '.slice(0,-1)'}) &&
          (#{renderPatternJS rightArg, "#{valueJS}[#{valueJS}.length - 1]"})
        """
      else
        # x+y==3   ->   error 'pattern'
        # x (_/_) y == [1;2;3]   ->   error 'pattern'
        throw Error 'Invalid pattern, only \\ and / are allowed'

wrapInClosure = (pattern, valueJS) ->
  """
    (function (v) {
      return #{renderPatternJS pattern, 'v'};
    }(#{valueJS}))
  """

# TODO unit test
assignmentNames = (assignments) ->
  walkExpr = (expr) ->
    _(expr).map (subExpr) ->
      arg = subExpr.argument
      if name = arg.const?.name
        name
      else if arg.sequence?
        _(arg.sequence.elements).map (e) ->
          walkExpr e.expr
      else if arg.expr?
        walkExpr arg.expr

  exprs = _(assignments).map (assignment) ->
    assignment.assignment.pattern.expr
  _(_(exprs).map(walkExpr)).flatten()
