
(function(/*! Stitch !*/) {
  if (!this.require) {
    var modules = {}, cache = {}, require = function(name, root) {
      var path = expand(root, name), module = cache[path], fn;
      if (module) {
        return module.exports;
      } else if (fn = modules[path] || modules[path = expand(path, './index')]) {
        module = {id: path, exports: {}};
        try {
          cache[path] = module;
          fn.apply(module.exports, [module.exports, function(name) {
            return require(name, dirname(path));
          }, module]);
          return module.exports;
        } catch (err) {
          delete cache[path];
          throw err;
        }
      } else {
        throw 'module \'' + name + '\' not found';
      }
    }, expand = function(root, name) {
      var results = [], parts, part;
      if (/^\.\.?(\/|$)/.test(name)) {
        parts = [root, name].join('/').split('/');
      } else {
        parts = name.split('/');
      }
      for (var i = 0, length = parts.length; i < length; i++) {
        part = parts[i];
        if (part == '..') {
          results.pop();
        } else if (part != '.' && part != '') {
          results.push(part);
        }
      }
      return results.join('/');
    }, dirname = function(path) {
      return path.split('/').slice(0, -1).join('/');
    };
    this.require = function(name) {
      return require(name, '');
    }
    this.require.define = function(bundle) {
      for (var key in bundle)
        modules[key] = bundle[key];
    };
  }
  return this.require.define;
}).call(this)({"lexer": function(exports, require, module) {(function() {
  var tokenDefs,
    _this = this;

  tokenDefs = [['-', /^\s+/], ['-', /^"[^a-z\{].*/i], ['-', /^"\{.*(?:\s*(?:"|"[^\}].*|[^"].*)[\n\r]+)*"\}.*/], ['number', /^\d+/], ['', /^(?:==|\?\{|@\{|::|\+\+|[\(\)\[\]\{\};_])/], ['name', /^[a-z][a-z0-9]*/i], ['name', /^\$(f|t|pinf|ninf|e|pi|np)?/], ['name', /^(?:<:|>:|\|:|=>|\|\||<=|>=|<>|,,|>>|<<|%%)/], ['name', /^[\+\-\*:\^=<>\/\\\.\#!%~\|,&]/]];

  this.tokenize = function(code, opts) {
    var col, line;

    if (opts == null) {
      opts = {};
    }
    line = col = 1;
    return {
      next: function() {
        var a, m, re, startCol, startLine, t, type, _i, _len, _ref;

        while (true) {
          if (!code) {
            return {
              type: 'eof',
              value: '',
              startLine: line,
              startCol: col,
              endLine: line,
              endCol: col
            };
          }
          startLine = line;
          startCol = col;
          type = null;
          for (_i = 0, _len = tokenDefs.length; _i < _len; _i++) {
            _ref = tokenDefs[_i], t = _ref[0], re = _ref[1];
            if (!(m = code.match(re))) {
              continue;
            }
            type = t || m[0];
            break;
          }
          if (!type) {
            throw Error(("Syntax error: unrecognized token at " + line + ":" + col + " ") + code, {
              file: opts.file,
              line: line,
              col: col,
              code: opts.code
            });
          }
          a = m[0].split('\n');
          line += a.length - 1;
          col = (a.length === 1 ? col : 1) + a[a.length - 1].length;
          code = code.substring(m[0].length);
          if (type !== '-') {
            return {
              type: type,
              startLine: startLine,
              startCol: startCol,
              value: m[0],
              endLine: line,
              endCol: col
            };
          }
        }
      }
    };
  };

  if (module === require.main) {
    (function() {
      var token, tokenStream, _results;

      tokenStream = _this.tokenize('$pinf >: > : >>>');
      _results = [];
      while ((token = tokenStream.next()).type !== 'eof') {
        _results.push(console.info(token));
      }
      return _results;
    })();
  }

}).call(this);
}, "parser": function(exports, require, module) {(function() {
  var lexer,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    _this = this;

  lexer = require('./lexer');

  this.parse = function(code, opts) {
    var consume, demand, parseExpr, parseProgram, parseValue, parserError, result, token, tokenStream;

    if (opts == null) {
      opts = {};
    }
    tokenStream = lexer.tokenize(code);
    token = tokenStream.next();
    consume = function(tt) {
      var _ref;

      if (_ref = token.type, __indexOf.call(tt.split(' '), _ref) >= 0) {
        return token = tokenStream.next();
      }
    };
    demand = function(tt) {
      if (token.type !== tt) {
        parserError("Expected token of type '" + tt + "' but got '" + token.type + "'");
      }
      token = tokenStream.next();
    };
    parserError = function(message) {
      throw Error("Parser error: " + message + " at " + token.startLine + ":" + token.startCol, {
        file: opts.file,
        line: token.startLine,
        col: token.startCol,
        code: code
      });
    };
    parseProgram = function() {
      return parseExpr();
    };
    parseExpr = function() {
      var r;

      r = ['expression', parseValue()].concat((function() {
        var _ref, _results;

        _results = [];
        while ((_ref = token.type) !== ')' && _ref !== ']' && _ref !== '}' && _ref !== ';' && _ref !== '==' && _ref !== '::' && _ref !== '++' && _ref !== 'eof') {
          _results.push(parseValue());
        }
        return _results;
      })());
      if (r.length === 2) {
        return r[1];
      } else {
        return r;
      }
    };
    parseValue = function() {
      var r, t;

      t = token;
      if (consume('number string name _')) {
        return [t.type, t.value];
      } else if (consume('(')) {
        r = parseExpr();
        demand(')');
        return r;
      } else if (consume('[')) {
        r = ['sequence'];
        if (token.type !== ']') {
          r.push(parseValue());
          while (consume(';')) {
            r.push(parseValue());
          }
        }
        demand(']');
        return r;
      } else if (consume('{')) {
        r = ['parametric', parseExpr(), parseLocal()];
        demand('}');
        return r;
      } else if (consume('?{')) {
        throw Error('Not implemented');
      } else if (consume('@{')) {
        throw Error('Not implemented');
      } else {
        return parserError("Expected value but found " + t.type);
      }
    };
    result = parseProgram();
    demand('eof');
    return result;
  };

  if (module === require.main) {
    (function() {
      return console.info(_this.parse('4*(1+2+3)-5+[6;7;[8];[];9]'));
    })();
  }

}).call(this);
}});
