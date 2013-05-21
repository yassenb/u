(function() {
  var parser;

  parser = require('parser');

  jQuery(function($) {
    return $('#inp').focus().keypress(function(event) {
      var e, r;

      if (event.keyCode === 13) {
        r = (function() {
          try {
            return JSON.stringify(parser.parse($('#inp').val()));
          } catch (_error) {
            e = _error;
            return e.stack;
          }
        })();
        $('#outp').text($('#outp').text() + '\n' + r);
        $(window).scrollTop($(document).height());
        false;
      }
      return true;
    });
  });

}).call(this);
