_ = require '../../lib/underscore'

components = ['./nonverbal', './io', './numeric', './sequence', './higher-order', './time', './various']
_(@).extend _(components).map(require)...

# Remember each built-in function's name in case we need it for debugging purposes
for k, v of @ when typeof v is 'function' then v.uName = k
