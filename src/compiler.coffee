_ = require '../lib/underscore'

{parse} = require './peg-parser/u-grammar'
stdlib = require './stdlib'
helpers = require './helpers'

@exec = (uCode) ->
  (new Function """
    var ctx     = arguments[0],
        helpers = arguments[1];
    return #{compile uCode};
  """) stdlib, helpers

@compile = compile = (uCode) ->
  renderJS parse uCode

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
      # 5   ->   5
      node

    when 'string'
      JSON.stringify(
        if /^'\(/.test node
          # '(')rock''n'roll)   ->   '(')rock''n'roll)
          # '(()                ->   '(()
          h = { n: '\n', t: '\t', ')': ')', "'": "'", '\n': '' }
          node[2...-1].replace /'['tn\n]/g, (x) -> h[x[1]]
        else
          # 'a                  ->   '(a)
          # "Toledo             ->   '(Toledo)
          node[1...]
      )

    when 'name'
      nameToJS node

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
      # a==1; a             ->   1
      # a==2+1; a           ->   3
      # TODO multiple assignments with a local clause
      if assignment = node.assignment
        renderPatternJS assignment.pattern, renderJS _(assignment).pick('expr')

    when 'defs'
      _(node).map(renderJS).join ';\n'

    when 'closure'
      renderJS node

    when 'conditional'
      # ?{1::2;3}   ->   2
      # ?{0::2;3}   ->   3
      # ?{0::2}     ->   $
      # TODO negative test cases
      # ?{$f::2;$t::3;4}   ->   3
      # ?{x::2;y::3;4 ++ x==$f; y==$t}   ->   3
      r = _(node.tests).reduce(
        (r, test) ->
          r + "(#{renderJS { expr: test.condition }})?(#{renderJS _(test).pick 'expr'}):"
        ''
      )
      r += if node.else then renderJS { expr: node.else } else 'null'
      withLocal node.local, r

    when 'function'
      # @{:: 123} . 3                      ->   123
      # @{a :: a+2} . 3                    ->   5
      # x==5; @{:: x} . $                  ->   5
      # x==5; f==@{:: x}; x==6; f . x      ->   6
      # TODO test that creating a new function creates a new context
      # @{1 :: 2} . 1                      ->   2
      # @{1 :: 2} . 3                      ->   $
      # @{x :: x+y ++ y==1} . 2            ->   3
      # @{a (1) :: a+2} . 3                ->   5
      # @{(1) :: 123} . 3                  ->   123
      # @{a (0) :: a+2; a ($t) :: 6} . 3   ->   6
      # TODO enable the below two when pattern matching is implemented
      # 5 @{[x;y]::x+y+y} 3                #->   11
      # @{[x;y]::x+y+y} . 3                #->   $
      resultJS = ''
      for { clause: {pattern, guard, expr} }, i in node.clauses
        # A missing pattern or guard defaults to that from the previous clause.
        # TODO refactor this ugliness
        pattern =
          if pattern?
            renderPatternJS pattern, 'arg'
          else
            if i > 0
              renderPatternJS node.clauses[i - 1].pattern, 'arg'
            else
              'true'

        guard =
          if guard?
            renderJS { expr: guard }
          else
            if i > 0
              renderJS { expr: node.clauses[i - 1].guard }
            else
              'true'
        # A missing outcome defaults to the next clause's outcome.
        # TODO what if the next clause has no outcome as well?
        outcome =
          if expr?
            renderJS { expr: expr }
          else
            if i < node.clauses.length - 1
              renderJS { expr: node.clauses[i + 1].expr }
            else
              'null'

        resultJS += "(#{pattern}) && (#{guard}) ? (#{outcome}) : "
      resultJS += 'null'

      withLocal node.local, """
        helpers.createLambda(ctx, function (arg, ctx) {
            return #{resultJS};
        })
      """
    else
      throw Error 'Compiler error: Unrecognised node type, ' + exprType

withLocal = (local, expression) ->
  if local?
    """
      helpers.createLambda(ctx, function (_ignored, ctx) {
        #{renderJS local}
        return #{expression};
      })()
    """
  else
    expression

nameToJS = (name) ->
  if /^\$/.test name
    switch name
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
        throw Error 'Unrecognised constant, ' + JSON.stringify name
  else if /^[a-z_\$][a-z0-9_\$]*$/i.test name
    "ctx.#{name}"
  else
    "ctx[#{JSON.stringify name}]"

# renderPatternJS() builds a JavaScript expression that evaluates to true when
# the pattern is matched.  As a side effect during its evaluation, the
# expression may associate names with values in the current context.
renderPatternJS = (node, valueJS) ->
  konst = node.const
  if name = konst.name
    "#{nameToJS name}=(#{valueJS}),true"
  else if konst.number or konst.string
    "#{renderJS konst}===(#{valueJS})"
  else
    # TODO
    throw Error 'Unsupported pattern'
