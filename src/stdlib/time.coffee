{polymorphic} = require './base'

@time = polymorphic(
  # TODO shouldn't the function take a string as input?
  (x) ->
    date = new Date
    d = [date.getDate(), date.getMonth(), date.getUTCFullYear()]
    h = [date.getHours(), date.getMinutes(), date.getSeconds()]
    switch x
      when 't' then [h, d]
      when 'd' then d
      when 'h' then h
      when 's' then Math.floor(date.getTime() / 1000)
      when 'p' then date.toString()
      else throw Error "time takes one of 't, 'd, 'h, 's or 'p"
)

# TODO
# @delay = polymorphic(
  # # delay . ~3   - >   error 'non-negative'
  # (n) ->
    # throw Error 'delay can only take non-negative values' if n < 0
# )
