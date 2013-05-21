(function() {
  var compile, exec, parse, renderAST, tokenize, _ref;

  parse = require('parser').parse;

  tokenize = require('lexer').tokenize;

  _ref = require('compiler'), compile = _ref.compile, exec = _ref.exec;

  jQuery(function($) {
    return $('#inp').focus().keypress(function(event) {
      var e, t, tokenStream, uCode;

      if (event.keyCode === 13) {
        uCode = $('#inp').val();
        if (!uCode) {
          return false;
        }
        $('#outp').text($('#outp').text() + '\n' + ((function() {
          try {
            if (/^\.t\b/.test(uCode)) {
              tokenStream = tokenize(uCode.slice(3));
              return "Tokens for " + (JSON.stringify(uCode)) + ":\n  " + (((function() {
                var _results;

                _results = [];
                while ((t = tokenStream.next()).type !== 'eof') {
                  _results.push(JSON.stringify(t));
                }
                return _results;
              })()).join('\n  '));
            } else if (/^\.a\b/.test(uCode)) {
              return "AST for " + (JSON.stringify(uCode)) + ":\n" + (renderAST(parse(uCode.slice(3))));
            } else if (/^\.c\b/.test(uCode)) {
              return compile(uCode.slice(3));
            } else {
              return exec(uCode);
            }
          } catch (_error) {
            e = _error;
            return e.stack;
          }
        })()));
        $(window).scrollTop($(document).height());
        false;
      }
      return true;
    });
  });

  renderAST = function(node, indent) {
    var child;

    if (indent == null) {
      indent = '  ';
    }
    if (node.length === 2 && typeof node[1] === 'string') {
      return indent + node[0] + ' ' + JSON.stringify(node[1]);
    } else {
      return indent + node[0] + '\n' + ((function() {
        var _i, _len, _ref1, _results;

        _ref1 = node.slice(1);
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          child = _ref1[_i];
          _results.push(renderAST(child, indent + '  '));
        }
        return _results;
      })()).join('\n');
    }
  };

}).call(this);
