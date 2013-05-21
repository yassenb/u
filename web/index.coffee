parser = require 'parser'

jQuery ($) ->
  $('#inp')
    .focus()
    .keypress (event) ->
      if event.keyCode is 13
        r = try JSON.stringify parser.parse $('#inp').val() catch e then e.stack
        $('#outp').text $('#outp').text() + '\n' + r
        $(window).scrollTop $(document).height()
        false
      true
