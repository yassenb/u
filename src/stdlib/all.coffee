_ = require '../../lib/underscore'

_(@).extend _(['./nonverbal', './io', './numeric', './sequence']).map(require)...

# Remember each built-in function's name in case we need it for debugging purposes
for k, v of @ when typeof v is 'function' then v.uName = k
