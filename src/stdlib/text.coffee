_ = require '../../lib/underscore'

{polymorphic} = require './base'

@ccvt = polymorphic(
  # ccvt . "hell   ->   [104;101;108;108]
  # ccvt . '()     ->   []
  (s) ->
    _(s).map (c) -> c.charCodeAt 0

  # ccvt . [104;101;108;108]   ->   "hell
  # ccvt . []                  ->   '()
  (q) ->
    String.fromCharCode q...

  # ccvt . 104   ->   'h
  (i) ->
    String.fromCharCode i
)

class Formatter
  format: (formatString, value) ->
    formatOptions = @parse(formatString)
    s = @toString(value, formatOptions['precision'])
    s = '+' + s if typeof value is 'number' and value > 0 and formatOptions['printPlus']
    @justify(s, formatOptions['justification'] or '>', formatOptions['width'])

  parse: (formatString) ->
    match = /^(<|>|=)?(\+)?(\d*)(\.\d*)?$/.exec formatString
    throw Error 'Invalid format string passed to frm' if match is null
    { justification: match[1] or null, printPlus: match[2] or null, width: match[3] or null, \
      precision: parseInt match[4]?.substring(1) or null }

  toString: (x, precision) ->
    if x == null
      '$'
    else if typeof x is 'number'
      x.toFixed(precision)
    else if typeof x is 'boolean'
      if x then '$t' else '$f'
    else if typeof x is 'string'
      x
    else if x instanceof Array
      xs = _(x).map (x) => @toString(x, precision)
      "[#{xs.join ';'}]"
    else if typeof x is 'function'
      '<function>'
    else
      throw Error 'unrecognized type'

  justify: (s, justification, width) ->
    width ?= s.length
    s = s.substring(0, width)  # TODO is this the right thing to do if the width is smaller?

    padding = ''
    _(width - s.length).times ->
      padding += ' '

    switch justification
      when '>' then s = padding + s
      when '<' then s += padding
      else  # '='
        i = (padding.length + 1) / 2
        s = padding.substring(0, i) + s + padding.substring(i)

    s

formatter = new Formatter
@frm = polymorphic(
  # '() frm $                 ->   '($)
  # '() frm 5                 ->   '(5)
  # '() frm $f                ->   '($f)
  # '() frm "hell             ->   '(hell)
  # '() frm [1;2;3]           ->   '([1;2;3])
  # '() frm [1;["he;"ll];3]   ->   '([1;[he;ll];3])
  # '() frm @{ :: 5}          ->   '(<function>)
  # '(>) frm 5                ->   '(5)
  # '(<) frm 5                ->   '(5)
  # '(=) frm 5                ->   '(5)
  # '(+) frm 5                ->   '(+5)
  # '(+) frm ~5               ->   '(-5)
  # '(4) frm 5                ->   '(   5)
  # '(3) frm 5                ->   '(  5)
  # '(1) frm 5                ->   '(5)
  # '(.0) frm 5               ->   '(5)
  # '(.1) frm 5               ->   '(5.0)
  # '(.2) frm 5.123           ->   '(5.12)
  # '(<4) frm "he             ->   '(he  )
  # '(>4) frm "he             ->   '(  he)
  # '(=4) frm "he             ->   '( he )
  # '(=3) frm "he             ->   '( he)
  # '(=5) frm "he             ->   '(  he )
  # '(=+7.2) frm 5.123        ->   '( +5.12 )
  (s, x) ->
    formatter.format(s, x)
)
