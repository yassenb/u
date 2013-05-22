
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
}).call(this)({"compiler": function(exports, require, module) {(function() {
  var compile, parse, renderJS;

  parse = require('./parser').parse;

  this.exec = function(uCode) {
    return (new Function("return " + (compile(uCode)) + ";"))();
  };

  this.compile = compile = function(uCode) {
    return renderJS(parse(uCode));
  };

  renderJS = function(node) {
    var alternative, child, condition, consequence, i, local, r, tokenType, _i, _len, _ref, _ref1, _ref2;

    switch (node[0]) {
      case 'number':
        return node[1];
      case 'name':
        return node[1].replace(/[^a-z0-9\$]/i, function(x) {
          return '_' + ('000' + x.charCodeAt(0).toString(16)).slice(-4);
        });
      case 'expression':
        r = renderJS(node[1]);
        i = 2;
        while (i < node.length) {
          r = "(" + (renderJS(node[i])) + ")([" + r + "].concat(" + (renderJS(node[i + 1])) + "))";
          i += 2;
        }
        return r;
      case 'sequence':
        return '[' + ((function() {
          var _i, _len, _ref, _results;

          _ref = node.slice(1);
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            child = _ref[_i];
            _results.push(renderJS(child));
          }
          return _results;
        })()).join(',') + ']';
      case 'conditional':
        r = '';
        _ref = node.slice(1, -2);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _ref1 = _ref[_i], tokenType = _ref1[0], condition = _ref1[1], consequence = _ref1[2];
          if (tokenType !== '::') {
            throw Error('Compiler error: expected "::" token as a child of "conditional", but found ' + JSON.stringify(tokenType));
          }
          r += "(" + (renderJS(condition)) + ")?(" + (renderJS(consequence)) + "):";
        }
        _ref2 = node.slice(-2), alternative = _ref2[0], local = _ref2[1];
        r += alternative ? renderJS(alternative) : '$';
        if (local) {
          throw Error('Not implemented: local clause within conditional');
        }
        return r;
      default:
        throw Error('Compiler error: Unrecognised node type, ' + node[0]);
    }
  };

}).call(this);
}, "lexer": function(exports, require, module) {(function() {
  var tokenDefs;

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
              value: m[0],
              startLine: startLine,
              startCol: startCol,
              endLine: line,
              endCol: col
            };
          }
        }
      }
    };
  };

}).call(this);
}, "parser": function(exports, require, module) {(function() {
  var lexer,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  lexer = require('./lexer');

  this.parse = function(code, opts) {
    var consume, demand, parseExpr, parseLocal, parseProgram, parseValue, parserError, result, token, tokenStream;

    if (opts == null) {
      opts = {};
    }
    tokenStream = lexer.tokenize(code);
    token = tokenStream.next();
    consume = function(tts) {
      var _ref;

      if (_ref = token.type, __indexOf.call(tts, _ref) >= 0) {
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
      var e, elseClause, ifThenClauses, local, r, t;

      t = token;
      if (consume(['number', 'string', 'name', '_'])) {
        return [t.type, t.value];
      } else if (consume(['('])) {
        r = parseExpr();
        demand(')');
        return r;
      } else if (consume(['['])) {
        r = ['sequence'];
        if (token.type !== ']') {
          r.push(parseValue());
          while (consume([';'])) {
            r.push(parseValue());
          }
        }
        demand(']');
        return r;
      } else if (consume(['{'])) {
        r = ['parametric', parseExpr(), parseLocal()];
        demand('}');
        return r;
      } else if (consume(['?{'])) {
        ifThenClauses = [];
        elseClause = null;
        while (true) {
          e = parseExpr();
          if (consume(['::'])) {
            ifThenClauses.push(['::', e, parseExpr()]);
          } else {
            elseClause = e;
            break;
          }
          if (!consume([';'])) {
            break;
          }
        }
        local = token.type === '++' ? parseLocal() : null;
        demand('}');
        return ['conditional'].concat(ifThenClauses, [elseClause], [local]);
      } else if (consume(['@{'])) {
        throw Error('Not implemented');
      } else {
        return parserError("Expected value but found " + t.type);
      }
    };
    parseLocal = function() {
      throw Error('Not implemented: parseLocal()');
    };
    result = parseProgram();
    demand('eof');
    return result;
  };

}).call(this);
}});
