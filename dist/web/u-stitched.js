
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
}).call(this)({"lib/underscore": function(exports, require, module) {// Underscore.js 1.4.4
// ===================

// > http://underscorejs.org
// > (c) 2009-2013 Jeremy Ashkenas, DocumentCloud Inc.
// > Underscore may be freely distributed under the MIT license.

// Baseline setup
// --------------
(function() {

  // Establish the root object, `window` in the browser, or `global` on the server.
  var root = this;

  // Save the previous value of the `_` variable.
  var previousUnderscore = root._;

  // Establish the object that gets returned to break out of a loop iteration.
  var breaker = {};

  // Save bytes in the minified (but not gzipped) version:
  var ArrayProto = Array.prototype, ObjProto = Object.prototype, FuncProto = Function.prototype;

  // Create quick reference variables for speed access to core prototypes.
  var push             = ArrayProto.push,
      slice            = ArrayProto.slice,
      concat           = ArrayProto.concat,
      toString         = ObjProto.toString,
      hasOwnProperty   = ObjProto.hasOwnProperty;

  // All **ECMAScript 5** native function implementations that we hope to use
  // are declared here.
  var
    nativeForEach      = ArrayProto.forEach,
    nativeMap          = ArrayProto.map,
    nativeReduce       = ArrayProto.reduce,
    nativeReduceRight  = ArrayProto.reduceRight,
    nativeFilter       = ArrayProto.filter,
    nativeEvery        = ArrayProto.every,
    nativeSome         = ArrayProto.some,
    nativeIndexOf      = ArrayProto.indexOf,
    nativeLastIndexOf  = ArrayProto.lastIndexOf,
    nativeIsArray      = Array.isArray,
    nativeKeys         = Object.keys,
    nativeBind         = FuncProto.bind;

  // Create a safe reference to the Underscore object for use below.
  var _ = function(obj) {
    if (obj instanceof _) return obj;
    if (!(this instanceof _)) return new _(obj);
    this._wrapped = obj;
  };

  // Export the Underscore object for **Node.js**, with
  // backwards-compatibility for the old `require()` API. If we're in
  // the browser, add `_` as a global object via a string identifier,
  // for Closure Compiler "advanced" mode.
  if (typeof exports !== 'undefined') {
    if (typeof module !== 'undefined' && module.exports) {
      exports = module.exports = _;
    }
    exports._ = _;
  } else {
    root._ = _;
  }

  // Current version.
  _.VERSION = '1.4.4';

  // Collection Functions
  // --------------------

  // The cornerstone, an `each` implementation, aka `forEach`.
  // Handles objects with the built-in `forEach`, arrays, and raw objects.
  // Delegates to **ECMAScript 5**'s native `forEach` if available.
  var each = _.each = _.forEach = function(obj, iterator, context) {
    if (obj == null) return;
    if (nativeForEach && obj.forEach === nativeForEach) {
      obj.forEach(iterator, context);
    } else if (obj.length === +obj.length) {
      for (var i = 0, l = obj.length; i < l; i++) {
        if (iterator.call(context, obj[i], i, obj) === breaker) return;
      }
    } else {
      for (var key in obj) {
        if (_.has(obj, key)) {
          if (iterator.call(context, obj[key], key, obj) === breaker) return;
        }
      }
    }
  };

  // Return the results of applying the iterator to each element.
  // Delegates to **ECMAScript 5**'s native `map` if available.
  _.map = _.collect = function(obj, iterator, context) {
    var results = [];
    if (obj == null) return results;
    if (nativeMap && obj.map === nativeMap) return obj.map(iterator, context);
    each(obj, function(value, index, list) {
      results[results.length] = iterator.call(context, value, index, list);
    });
    return results;
  };

  var reduceError = 'Reduce of empty array with no initial value';

  // **Reduce** builds up a single result from a list of values, aka `inject`,
  // or `foldl`. Delegates to **ECMAScript 5**'s native `reduce` if available.
  _.reduce = _.foldl = _.inject = function(obj, iterator, memo, context) {
    var initial = arguments.length > 2;
    if (obj == null) obj = [];
    if (nativeReduce && obj.reduce === nativeReduce) {
      if (context) iterator = _.bind(iterator, context);
      return initial ? obj.reduce(iterator, memo) : obj.reduce(iterator);
    }
    each(obj, function(value, index, list) {
      if (!initial) {
        memo = value;
        initial = true;
      } else {
        memo = iterator.call(context, memo, value, index, list);
      }
    });
    if (!initial) throw new TypeError(reduceError);
    return memo;
  };

  // The right-associative version of reduce, also known as `foldr`.
  // Delegates to **ECMAScript 5**'s native `reduceRight` if available.
  _.reduceRight = _.foldr = function(obj, iterator, memo, context) {
    var initial = arguments.length > 2;
    if (obj == null) obj = [];
    if (nativeReduceRight && obj.reduceRight === nativeReduceRight) {
      if (context) iterator = _.bind(iterator, context);
      return initial ? obj.reduceRight(iterator, memo) : obj.reduceRight(iterator);
    }
    var length = obj.length;
    if (length !== +length) {
      var keys = _.keys(obj);
      length = keys.length;
    }
    each(obj, function(value, index, list) {
      index = keys ? keys[--length] : --length;
      if (!initial) {
        memo = obj[index];
        initial = true;
      } else {
        memo = iterator.call(context, memo, obj[index], index, list);
      }
    });
    if (!initial) throw new TypeError(reduceError);
    return memo;
  };

  // Return the first value which passes a truth test. Aliased as `detect`.
  _.find = _.detect = function(obj, iterator, context) {
    var result;
    any(obj, function(value, index, list) {
      if (iterator.call(context, value, index, list)) {
        result = value;
        return true;
      }
    });
    return result;
  };

  // Return all the elements that pass a truth test.
  // Delegates to **ECMAScript 5**'s native `filter` if available.
  // Aliased as `select`.
  _.filter = _.select = function(obj, iterator, context) {
    var results = [];
    if (obj == null) return results;
    if (nativeFilter && obj.filter === nativeFilter) return obj.filter(iterator, context);
    each(obj, function(value, index, list) {
      if (iterator.call(context, value, index, list)) results[results.length] = value;
    });
    return results;
  };

  // Return all the elements for which a truth test fails.
  _.reject = function(obj, iterator, context) {
    return _.filter(obj, function(value, index, list) {
      return !iterator.call(context, value, index, list);
    }, context);
  };

  // Determine whether all of the elements match a truth test.
  // Delegates to **ECMAScript 5**'s native `every` if available.
  // Aliased as `all`.
  _.every = _.all = function(obj, iterator, context) {
    iterator || (iterator = _.identity);
    var result = true;
    if (obj == null) return result;
    if (nativeEvery && obj.every === nativeEvery) return obj.every(iterator, context);
    each(obj, function(value, index, list) {
      if (!(result = result && iterator.call(context, value, index, list))) return breaker;
    });
    return !!result;
  };

  // Determine if at least one element in the object matches a truth test.
  // Delegates to **ECMAScript 5**'s native `some` if available.
  // Aliased as `any`.
  var any = _.some = _.any = function(obj, iterator, context) {
    iterator || (iterator = _.identity);
    var result = false;
    if (obj == null) return result;
    if (nativeSome && obj.some === nativeSome) return obj.some(iterator, context);
    each(obj, function(value, index, list) {
      if (result || (result = iterator.call(context, value, index, list))) return breaker;
    });
    return !!result;
  };

  // Determine if the array or object contains a given value (using `===`).
  // Aliased as `include`.
  _.contains = _.include = function(obj, target) {
    if (obj == null) return false;
    if (nativeIndexOf && obj.indexOf === nativeIndexOf) return obj.indexOf(target) != -1;
    return any(obj, function(value) {
      return value === target;
    });
  };

  // Invoke a method (with arguments) on every item in a collection.
  _.invoke = function(obj, method) {
    var args = slice.call(arguments, 2);
    var isFunc = _.isFunction(method);
    return _.map(obj, function(value) {
      return (isFunc ? method : value[method]).apply(value, args);
    });
  };

  // Convenience version of a common use case of `map`: fetching a property.
  _.pluck = function(obj, key) {
    return _.map(obj, function(value){ return value[key]; });
  };

  // Convenience version of a common use case of `filter`: selecting only objects
  // containing specific `key:value` pairs.
  _.where = function(obj, attrs, first) {
    if (_.isEmpty(attrs)) return first ? null : [];
    return _[first ? 'find' : 'filter'](obj, function(value) {
      for (var key in attrs) {
        if (attrs[key] !== value[key]) return false;
      }
      return true;
    });
  };

  // Convenience version of a common use case of `find`: getting the first object
  // containing specific `key:value` pairs.
  _.findWhere = function(obj, attrs) {
    return _.where(obj, attrs, true);
  };

  // Return the maximum element or (element-based computation).
  // Can't optimize arrays of integers longer than 65,535 elements.
  // See: https://bugs.webkit.org/show_bug.cgi?id=80797
  _.max = function(obj, iterator, context) {
    if (!iterator && _.isArray(obj) && obj[0] === +obj[0] && obj.length < 65535) {
      return Math.max.apply(Math, obj);
    }
    if (!iterator && _.isEmpty(obj)) return -Infinity;
    var result = {computed : -Infinity, value: -Infinity};
    each(obj, function(value, index, list) {
      var computed = iterator ? iterator.call(context, value, index, list) : value;
      computed >= result.computed && (result = {value : value, computed : computed});
    });
    return result.value;
  };

  // Return the minimum element (or element-based computation).
  _.min = function(obj, iterator, context) {
    if (!iterator && _.isArray(obj) && obj[0] === +obj[0] && obj.length < 65535) {
      return Math.min.apply(Math, obj);
    }
    if (!iterator && _.isEmpty(obj)) return Infinity;
    var result = {computed : Infinity, value: Infinity};
    each(obj, function(value, index, list) {
      var computed = iterator ? iterator.call(context, value, index, list) : value;
      computed < result.computed && (result = {value : value, computed : computed});
    });
    return result.value;
  };

  // Shuffle an array.
  _.shuffle = function(obj) {
    var rand;
    var index = 0;
    var shuffled = [];
    each(obj, function(value) {
      rand = _.random(index++);
      shuffled[index - 1] = shuffled[rand];
      shuffled[rand] = value;
    });
    return shuffled;
  };

  // An internal function to generate lookup iterators.
  var lookupIterator = function(value) {
    return _.isFunction(value) ? value : function(obj){ return obj[value]; };
  };

  // Sort the object's values by a criterion produced by an iterator.
  _.sortBy = function(obj, value, context) {
    var iterator = lookupIterator(value);
    return _.pluck(_.map(obj, function(value, index, list) {
      return {
        value : value,
        index : index,
        criteria : iterator.call(context, value, index, list)
      };
    }).sort(function(left, right) {
      var a = left.criteria;
      var b = right.criteria;
      if (a !== b) {
        if (a > b || a === void 0) return 1;
        if (a < b || b === void 0) return -1;
      }
      return left.index < right.index ? -1 : 1;
    }), 'value');
  };

  // An internal function used for aggregate "group by" operations.
  var group = function(obj, value, context, behavior) {
    var result = {};
    var iterator = lookupIterator(value || _.identity);
    each(obj, function(value, index) {
      var key = iterator.call(context, value, index, obj);
      behavior(result, key, value);
    });
    return result;
  };

  // Groups the object's values by a criterion. Pass either a string attribute
  // to group by, or a function that returns the criterion.
  _.groupBy = function(obj, value, context) {
    return group(obj, value, context, function(result, key, value) {
      (_.has(result, key) ? result[key] : (result[key] = [])).push(value);
    });
  };

  // Counts instances of an object that group by a certain criterion. Pass
  // either a string attribute to count by, or a function that returns the
  // criterion.
  _.countBy = function(obj, value, context) {
    return group(obj, value, context, function(result, key) {
      if (!_.has(result, key)) result[key] = 0;
      result[key]++;
    });
  };

  // Use a comparator function to figure out the smallest index at which
  // an object should be inserted so as to maintain order. Uses binary search.
  _.sortedIndex = function(array, obj, iterator, context) {
    iterator = iterator == null ? _.identity : lookupIterator(iterator);
    var value = iterator.call(context, obj);
    var low = 0, high = array.length;
    while (low < high) {
      var mid = (low + high) >>> 1;
      iterator.call(context, array[mid]) < value ? low = mid + 1 : high = mid;
    }
    return low;
  };

  // Safely convert anything iterable into a real, live array.
  _.toArray = function(obj) {
    if (!obj) return [];
    if (_.isArray(obj)) return slice.call(obj);
    if (obj.length === +obj.length) return _.map(obj, _.identity);
    return _.values(obj);
  };

  // Return the number of elements in an object.
  _.size = function(obj) {
    if (obj == null) return 0;
    return (obj.length === +obj.length) ? obj.length : _.keys(obj).length;
  };

  // Array Functions
  // ---------------

  // Get the first element of an array. Passing **n** will return the first N
  // values in the array. Aliased as `head` and `take`. The **guard** check
  // allows it to work with `_.map`.
  _.first = _.head = _.take = function(array, n, guard) {
    if (array == null) return void 0;
    return (n != null) && !guard ? slice.call(array, 0, n) : array[0];
  };

  // Returns everything but the last entry of the array. Especially useful on
  // the arguments object. Passing **n** will return all the values in
  // the array, excluding the last N. The **guard** check allows it to work with
  // `_.map`.
  _.initial = function(array, n, guard) {
    return slice.call(array, 0, array.length - ((n == null) || guard ? 1 : n));
  };

  // Get the last element of an array. Passing **n** will return the last N
  // values in the array. The **guard** check allows it to work with `_.map`.
  _.last = function(array, n, guard) {
    if (array == null) return void 0;
    if ((n != null) && !guard) {
      return slice.call(array, Math.max(array.length - n, 0));
    } else {
      return array[array.length - 1];
    }
  };

  // Returns everything but the first entry of the array. Aliased as `tail` and `drop`.
  // Especially useful on the arguments object. Passing an **n** will return
  // the rest N values in the array. The **guard**
  // check allows it to work with `_.map`.
  _.rest = _.tail = _.drop = function(array, n, guard) {
    return slice.call(array, (n == null) || guard ? 1 : n);
  };

  // Trim out all falsy values from an array.
  _.compact = function(array) {
    return _.filter(array, _.identity);
  };

  // Internal implementation of a recursive `flatten` function.
  var flatten = function(input, shallow, output) {
    each(input, function(value) {
      if (_.isArray(value)) {
        shallow ? push.apply(output, value) : flatten(value, shallow, output);
      } else {
        output.push(value);
      }
    });
    return output;
  };

  // Return a completely flattened version of an array.
  _.flatten = function(array, shallow) {
    return flatten(array, shallow, []);
  };

  // Return a version of the array that does not contain the specified value(s).
  _.without = function(array) {
    return _.difference(array, slice.call(arguments, 1));
  };

  // Produce a duplicate-free version of the array. If the array has already
  // been sorted, you have the option of using a faster algorithm.
  // Aliased as `unique`.
  _.uniq = _.unique = function(array, isSorted, iterator, context) {
    if (_.isFunction(isSorted)) {
      context = iterator;
      iterator = isSorted;
      isSorted = false;
    }
    var initial = iterator ? _.map(array, iterator, context) : array;
    var results = [];
    var seen = [];
    each(initial, function(value, index) {
      if (isSorted ? (!index || seen[seen.length - 1] !== value) : !_.contains(seen, value)) {
        seen.push(value);
        results.push(array[index]);
      }
    });
    return results;
  };

  // Produce an array that contains the union: each distinct element from all of
  // the passed-in arrays.
  _.union = function() {
    return _.uniq(concat.apply(ArrayProto, arguments));
  };

  // Produce an array that contains every item shared between all the
  // passed-in arrays.
  _.intersection = function(array) {
    var rest = slice.call(arguments, 1);
    return _.filter(_.uniq(array), function(item) {
      return _.every(rest, function(other) {
        return _.indexOf(other, item) >= 0;
      });
    });
  };

  // Take the difference between one array and a number of other arrays.
  // Only the elements present in just the first array will remain.
  _.difference = function(array) {
    var rest = concat.apply(ArrayProto, slice.call(arguments, 1));
    return _.filter(array, function(value){ return !_.contains(rest, value); });
  };

  // Zip together multiple lists into a single array -- elements that share
  // an index go together.
  _.zip = function() {
    var args = slice.call(arguments);
    var length = _.max(_.pluck(args, 'length'));
    var results = new Array(length);
    for (var i = 0; i < length; i++) {
      results[i] = _.pluck(args, "" + i);
    }
    return results;
  };

  // Converts lists into objects. Pass either a single array of `[key, value]`
  // pairs, or two parallel arrays of the same length -- one of keys, and one of
  // the corresponding values.
  _.object = function(list, values) {
    if (list == null) return {};
    var result = {};
    for (var i = 0, l = list.length; i < l; i++) {
      if (values) {
        result[list[i]] = values[i];
      } else {
        result[list[i][0]] = list[i][1];
      }
    }
    return result;
  };

  // If the browser doesn't supply us with indexOf (I'm looking at you, **MSIE**),
  // we need this function. Return the position of the first occurrence of an
  // item in an array, or -1 if the item is not included in the array.
  // Delegates to **ECMAScript 5**'s native `indexOf` if available.
  // If the array is large and already in sort order, pass `true`
  // for **isSorted** to use binary search.
  _.indexOf = function(array, item, isSorted) {
    if (array == null) return -1;
    var i = 0, l = array.length;
    if (isSorted) {
      if (typeof isSorted == 'number') {
        i = (isSorted < 0 ? Math.max(0, l + isSorted) : isSorted);
      } else {
        i = _.sortedIndex(array, item);
        return array[i] === item ? i : -1;
      }
    }
    if (nativeIndexOf && array.indexOf === nativeIndexOf) return array.indexOf(item, isSorted);
    for (; i < l; i++) if (array[i] === item) return i;
    return -1;
  };

  // Delegates to **ECMAScript 5**'s native `lastIndexOf` if available.
  _.lastIndexOf = function(array, item, from) {
    if (array == null) return -1;
    var hasIndex = from != null;
    if (nativeLastIndexOf && array.lastIndexOf === nativeLastIndexOf) {
      return hasIndex ? array.lastIndexOf(item, from) : array.lastIndexOf(item);
    }
    var i = (hasIndex ? from : array.length);
    while (i--) if (array[i] === item) return i;
    return -1;
  };

  // Generate an integer Array containing an arithmetic progression. A port of
  // the native Python `range()` function. See
  // [the Python documentation](http://docs.python.org/library/functions.html#range).
  _.range = function(start, stop, step) {
    if (arguments.length <= 1) {
      stop = start || 0;
      start = 0;
    }
    step = arguments[2] || 1;

    var len = Math.max(Math.ceil((stop - start) / step), 0);
    var idx = 0;
    var range = new Array(len);

    while(idx < len) {
      range[idx++] = start;
      start += step;
    }

    return range;
  };

  // Function (ahem) Functions
  // ------------------

  // Create a function bound to a given object (assigning `this`, and arguments,
  // optionally). Delegates to **ECMAScript 5**'s native `Function.bind` if
  // available.
  _.bind = function(func, context) {
    if (func.bind === nativeBind && nativeBind) return nativeBind.apply(func, slice.call(arguments, 1));
    var args = slice.call(arguments, 2);
    return function() {
      return func.apply(context, args.concat(slice.call(arguments)));
    };
  };

  // Partially apply a function by creating a version that has had some of its
  // arguments pre-filled, without changing its dynamic `this` context.
  _.partial = function(func) {
    var args = slice.call(arguments, 1);
    return function() {
      return func.apply(this, args.concat(slice.call(arguments)));
    };
  };

  // Bind all of an object's methods to that object. Useful for ensuring that
  // all callbacks defined on an object belong to it.
  _.bindAll = function(obj) {
    var funcs = slice.call(arguments, 1);
    if (funcs.length === 0) funcs = _.functions(obj);
    each(funcs, function(f) { obj[f] = _.bind(obj[f], obj); });
    return obj;
  };

  // Memoize an expensive function by storing its results.
  _.memoize = function(func, hasher) {
    var memo = {};
    hasher || (hasher = _.identity);
    return function() {
      var key = hasher.apply(this, arguments);
      return _.has(memo, key) ? memo[key] : (memo[key] = func.apply(this, arguments));
    };
  };

  // Delays a function for the given number of milliseconds, and then calls
  // it with the arguments supplied.
  _.delay = function(func, wait) {
    var args = slice.call(arguments, 2);
    return setTimeout(function(){ return func.apply(null, args); }, wait);
  };

  // Defers a function, scheduling it to run after the current call stack has
  // cleared.
  _.defer = function(func) {
    return _.delay.apply(_, [func, 1].concat(slice.call(arguments, 1)));
  };

  // Returns a function, that, when invoked, will only be triggered at most once
  // during a given window of time.
  _.throttle = function(func, wait) {
    var context, args, timeout, result;
    var previous = 0;
    var later = function() {
      previous = new Date;
      timeout = null;
      result = func.apply(context, args);
    };
    return function() {
      var now = new Date;
      var remaining = wait - (now - previous);
      context = this;
      args = arguments;
      if (remaining <= 0) {
        clearTimeout(timeout);
        timeout = null;
        previous = now;
        result = func.apply(context, args);
      } else if (!timeout) {
        timeout = setTimeout(later, remaining);
      }
      return result;
    };
  };

  // Returns a function, that, as long as it continues to be invoked, will not
  // be triggered. The function will be called after it stops being called for
  // N milliseconds. If `immediate` is passed, trigger the function on the
  // leading edge, instead of the trailing.
  _.debounce = function(func, wait, immediate) {
    var timeout, result;
    return function() {
      var context = this, args = arguments;
      var later = function() {
        timeout = null;
        if (!immediate) result = func.apply(context, args);
      };
      var callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
      if (callNow) result = func.apply(context, args);
      return result;
    };
  };

  // Returns a function that will be executed at most one time, no matter how
  // often you call it. Useful for lazy initialization.
  _.once = function(func) {
    var ran = false, memo;
    return function() {
      if (ran) return memo;
      ran = true;
      memo = func.apply(this, arguments);
      func = null;
      return memo;
    };
  };

  // Returns the first function passed as an argument to the second,
  // allowing you to adjust arguments, run code before and after, and
  // conditionally execute the original function.
  _.wrap = function(func, wrapper) {
    return function() {
      var args = [func];
      push.apply(args, arguments);
      return wrapper.apply(this, args);
    };
  };

  // Returns a function that is the composition of a list of functions, each
  // consuming the return value of the function that follows.
  _.compose = function() {
    var funcs = arguments;
    return function() {
      var args = arguments;
      for (var i = funcs.length - 1; i >= 0; i--) {
        args = [funcs[i].apply(this, args)];
      }
      return args[0];
    };
  };

  // Returns a function that will only be executed after being called N times.
  _.after = function(times, func) {
    if (times <= 0) return func();
    return function() {
      if (--times < 1) {
        return func.apply(this, arguments);
      }
    };
  };

  // Object Functions
  // ----------------

  // Retrieve the names of an object's properties.
  // Delegates to **ECMAScript 5**'s native `Object.keys`
  _.keys = nativeKeys || function(obj) {
    if (obj !== Object(obj)) throw new TypeError('Invalid object');
    var keys = [];
    for (var key in obj) if (_.has(obj, key)) keys[keys.length] = key;
    return keys;
  };

  // Retrieve the values of an object's properties.
  _.values = function(obj) {
    var values = [];
    for (var key in obj) if (_.has(obj, key)) values.push(obj[key]);
    return values;
  };

  // Convert an object into a list of `[key, value]` pairs.
  _.pairs = function(obj) {
    var pairs = [];
    for (var key in obj) if (_.has(obj, key)) pairs.push([key, obj[key]]);
    return pairs;
  };

  // Invert the keys and values of an object. The values must be serializable.
  _.invert = function(obj) {
    var result = {};
    for (var key in obj) if (_.has(obj, key)) result[obj[key]] = key;
    return result;
  };

  // Return a sorted list of the function names available on the object.
  // Aliased as `methods`
  _.functions = _.methods = function(obj) {
    var names = [];
    for (var key in obj) {
      if (_.isFunction(obj[key])) names.push(key);
    }
    return names.sort();
  };

  // Extend a given object with all the properties in passed-in object(s).
  _.extend = function(obj) {
    each(slice.call(arguments, 1), function(source) {
      if (source) {
        for (var prop in source) {
          obj[prop] = source[prop];
        }
      }
    });
    return obj;
  };

  // Return a copy of the object only containing the whitelisted properties.
  _.pick = function(obj) {
    var copy = {};
    var keys = concat.apply(ArrayProto, slice.call(arguments, 1));
    each(keys, function(key) {
      if (key in obj) copy[key] = obj[key];
    });
    return copy;
  };

   // Return a copy of the object without the blacklisted properties.
  _.omit = function(obj) {
    var copy = {};
    var keys = concat.apply(ArrayProto, slice.call(arguments, 1));
    for (var key in obj) {
      if (!_.contains(keys, key)) copy[key] = obj[key];
    }
    return copy;
  };

  // Fill in a given object with default properties.
  _.defaults = function(obj) {
    each(slice.call(arguments, 1), function(source) {
      if (source) {
        for (var prop in source) {
          if (obj[prop] == null) obj[prop] = source[prop];
        }
      }
    });
    return obj;
  };

  // Create a (shallow-cloned) duplicate of an object.
  _.clone = function(obj) {
    if (!_.isObject(obj)) return obj;
    return _.isArray(obj) ? obj.slice() : _.extend({}, obj);
  };

  // Invokes interceptor with the obj, and then returns obj.
  // The primary purpose of this method is to "tap into" a method chain, in
  // order to perform operations on intermediate results within the chain.
  _.tap = function(obj, interceptor) {
    interceptor(obj);
    return obj;
  };

  // Internal recursive comparison function for `isEqual`.
  var eq = function(a, b, aStack, bStack) {
    // Identical objects are equal. `0 === -0`, but they aren't identical.
    // See the Harmony `egal` proposal: http://wiki.ecmascript.org/doku.php?id=harmony:egal.
    if (a === b) return a !== 0 || 1 / a == 1 / b;
    // A strict comparison is necessary because `null == undefined`.
    if (a == null || b == null) return a === b;
    // Unwrap any wrapped objects.
    if (a instanceof _) a = a._wrapped;
    if (b instanceof _) b = b._wrapped;
    // Compare `[[Class]]` names.
    var className = toString.call(a);
    if (className != toString.call(b)) return false;
    switch (className) {
      // Strings, numbers, dates, and booleans are compared by value.
      case '[object String]':
        // Primitives and their corresponding object wrappers are equivalent; thus, `"5"` is
        // equivalent to `new String("5")`.
        return a == String(b);
      case '[object Number]':
        // `NaN`s are equivalent, but non-reflexive. An `egal` comparison is performed for
        // other numeric values.
        return a != +a ? b != +b : (a == 0 ? 1 / a == 1 / b : a == +b);
      case '[object Date]':
      case '[object Boolean]':
        // Coerce dates and booleans to numeric primitive values. Dates are compared by their
        // millisecond representations. Note that invalid dates with millisecond representations
        // of `NaN` are not equivalent.
        return +a == +b;
      // RegExps are compared by their source patterns and flags.
      case '[object RegExp]':
        return a.source == b.source &&
               a.global == b.global &&
               a.multiline == b.multiline &&
               a.ignoreCase == b.ignoreCase;
    }
    if (typeof a != 'object' || typeof b != 'object') return false;
    // Assume equality for cyclic structures. The algorithm for detecting cyclic
    // structures is adapted from ES 5.1 section 15.12.3, abstract operation `JO`.
    var length = aStack.length;
    while (length--) {
      // Linear search. Performance is inversely proportional to the number of
      // unique nested structures.
      if (aStack[length] == a) return bStack[length] == b;
    }
    // Add the first object to the stack of traversed objects.
    aStack.push(a);
    bStack.push(b);
    var size = 0, result = true;
    // Recursively compare objects and arrays.
    if (className == '[object Array]') {
      // Compare array lengths to determine if a deep comparison is necessary.
      size = a.length;
      result = size == b.length;
      if (result) {
        // Deep compare the contents, ignoring non-numeric properties.
        while (size--) {
          if (!(result = eq(a[size], b[size], aStack, bStack))) break;
        }
      }
    } else {
      // Objects with different constructors are not equivalent, but `Object`s
      // from different frames are.
      var aCtor = a.constructor, bCtor = b.constructor;
      if (aCtor !== bCtor && !(_.isFunction(aCtor) && (aCtor instanceof aCtor) &&
                               _.isFunction(bCtor) && (bCtor instanceof bCtor))) {
        return false;
      }
      // Deep compare objects.
      for (var key in a) {
        if (_.has(a, key)) {
          // Count the expected number of properties.
          size++;
          // Deep compare each member.
          if (!(result = _.has(b, key) && eq(a[key], b[key], aStack, bStack))) break;
        }
      }
      // Ensure that both objects contain the same number of properties.
      if (result) {
        for (key in b) {
          if (_.has(b, key) && !(size--)) break;
        }
        result = !size;
      }
    }
    // Remove the first object from the stack of traversed objects.
    aStack.pop();
    bStack.pop();
    return result;
  };

  // Perform a deep comparison to check if two objects are equal.
  _.isEqual = function(a, b) {
    return eq(a, b, [], []);
  };

  // Is a given array, string, or object empty?
  // An "empty" object has no enumerable own-properties.
  _.isEmpty = function(obj) {
    if (obj == null) return true;
    if (_.isArray(obj) || _.isString(obj)) return obj.length === 0;
    for (var key in obj) if (_.has(obj, key)) return false;
    return true;
  };

  // Is a given value a DOM element?
  _.isElement = function(obj) {
    return !!(obj && obj.nodeType === 1);
  };

  // Is a given value an array?
  // Delegates to ECMA5's native Array.isArray
  _.isArray = nativeIsArray || function(obj) {
    return toString.call(obj) == '[object Array]';
  };

  // Is a given variable an object?
  _.isObject = function(obj) {
    return obj === Object(obj);
  };

  // Add some isType methods: isArguments, isFunction, isString, isNumber, isDate, isRegExp.
  each(['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp'], function(name) {
    _['is' + name] = function(obj) {
      return toString.call(obj) == '[object ' + name + ']';
    };
  });

  // Define a fallback version of the method in browsers (ahem, IE), where
  // there isn't any inspectable "Arguments" type.
  if (!_.isArguments(arguments)) {
    _.isArguments = function(obj) {
      return !!(obj && _.has(obj, 'callee'));
    };
  }

  // Optimize `isFunction` if appropriate.
  if (typeof (/./) !== 'function') {
    _.isFunction = function(obj) {
      return typeof obj === 'function';
    };
  }

  // Is a given object a finite number?
  _.isFinite = function(obj) {
    return isFinite(obj) && !isNaN(parseFloat(obj));
  };

  // Is the given value `NaN`? (NaN is the only number which does not equal itself).
  _.isNaN = function(obj) {
    return _.isNumber(obj) && obj != +obj;
  };

  // Is a given value a boolean?
  _.isBoolean = function(obj) {
    return obj === true || obj === false || toString.call(obj) == '[object Boolean]';
  };

  // Is a given value equal to null?
  _.isNull = function(obj) {
    return obj === null;
  };

  // Is a given variable undefined?
  _.isUndefined = function(obj) {
    return obj === void 0;
  };

  // Shortcut function for checking if an object has a given property directly
  // on itself (in other words, not on a prototype).
  _.has = function(obj, key) {
    return hasOwnProperty.call(obj, key);
  };

  // Utility Functions
  // -----------------

  // Run Underscore.js in *noConflict* mode, returning the `_` variable to its
  // previous owner. Returns a reference to the Underscore object.
  _.noConflict = function() {
    root._ = previousUnderscore;
    return this;
  };

  // Keep the identity function around for default iterators.
  _.identity = function(value) {
    return value;
  };

  // Run a function **n** times.
  _.times = function(n, iterator, context) {
    var accum = Array(n);
    for (var i = 0; i < n; i++) accum[i] = iterator.call(context, i);
    return accum;
  };

  // Return a random integer between min and max (inclusive).
  _.random = function(min, max) {
    if (max == null) {
      max = min;
      min = 0;
    }
    return min + Math.floor(Math.random() * (max - min + 1));
  };

  // List of HTML entities for escaping.
  var entityMap = {
    escape: {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#x27;',
      '/': '&#x2F;'
    }
  };
  entityMap.unescape = _.invert(entityMap.escape);

  // Regexes containing the keys and values listed immediately above.
  var entityRegexes = {
    escape:   new RegExp('[' + _.keys(entityMap.escape).join('') + ']', 'g'),
    unescape: new RegExp('(' + _.keys(entityMap.unescape).join('|') + ')', 'g')
  };

  // Functions for escaping and unescaping strings to/from HTML interpolation.
  _.each(['escape', 'unescape'], function(method) {
    _[method] = function(string) {
      if (string == null) return '';
      return ('' + string).replace(entityRegexes[method], function(match) {
        return entityMap[method][match];
      });
    };
  });

  // If the value of the named property is a function then invoke it;
  // otherwise, return it.
  _.result = function(object, property) {
    if (object == null) return null;
    var value = object[property];
    return _.isFunction(value) ? value.call(object) : value;
  };

  // Add your own custom functions to the Underscore object.
  _.mixin = function(obj) {
    each(_.functions(obj), function(name){
      var func = _[name] = obj[name];
      _.prototype[name] = function() {
        var args = [this._wrapped];
        push.apply(args, arguments);
        return result.call(this, func.apply(_, args));
      };
    });
  };

  // Generate a unique integer id (unique within the entire client session).
  // Useful for temporary DOM ids.
  var idCounter = 0;
  _.uniqueId = function(prefix) {
    var id = ++idCounter + '';
    return prefix ? prefix + id : id;
  };

  // By default, Underscore uses ERB-style template delimiters, change the
  // following template settings to use alternative delimiters.
  _.templateSettings = {
    evaluate    : /<%([\s\S]+?)%>/g,
    interpolate : /<%=([\s\S]+?)%>/g,
    escape      : /<%-([\s\S]+?)%>/g
  };

  // When customizing `templateSettings`, if you don't want to define an
  // interpolation, evaluation or escaping regex, we need one that is
  // guaranteed not to match.
  var noMatch = /(.)^/;

  // Certain characters need to be escaped so that they can be put into a
  // string literal.
  var escapes = {
    "'":      "'",
    '\\':     '\\',
    '\r':     'r',
    '\n':     'n',
    '\t':     't',
    '\u2028': 'u2028',
    '\u2029': 'u2029'
  };

  var escaper = /\\|'|\r|\n|\t|\u2028|\u2029/g;

  // JavaScript micro-templating, similar to John Resig's implementation.
  // Underscore templating handles arbitrary delimiters, preserves whitespace,
  // and correctly escapes quotes within interpolated code.
  _.template = function(text, data, settings) {
    var render;
    settings = _.defaults({}, settings, _.templateSettings);

    // Combine delimiters into one regular expression via alternation.
    var matcher = new RegExp([
      (settings.escape || noMatch).source,
      (settings.interpolate || noMatch).source,
      (settings.evaluate || noMatch).source
    ].join('|') + '|$', 'g');

    // Compile the template source, escaping string literals appropriately.
    var index = 0;
    var source = "__p+='";
    text.replace(matcher, function(match, escape, interpolate, evaluate, offset) {
      source += text.slice(index, offset)
        .replace(escaper, function(match) { return '\\' + escapes[match]; });

      if (escape) {
        source += "'+\n((__t=(" + escape + "))==null?'':_.escape(__t))+\n'";
      }
      if (interpolate) {
        source += "'+\n((__t=(" + interpolate + "))==null?'':__t)+\n'";
      }
      if (evaluate) {
        source += "';\n" + evaluate + "\n__p+='";
      }
      index = offset + match.length;
      return match;
    });
    source += "';\n";

    // If a variable is not specified, place data values in local scope.
    if (!settings.variable) source = 'with(obj||{}){\n' + source + '}\n';

    source = "var __t,__p='',__j=Array.prototype.join," +
      "print=function(){__p+=__j.call(arguments,'');};\n" +
      source + "return __p;\n";

    try {
      render = new Function(settings.variable || 'obj', '_', source);
    } catch (e) {
      e.source = source;
      throw e;
    }

    if (data) return render(data, _);
    var template = function(data) {
      return render.call(this, data, _);
    };

    // Provide the compiled function source as a convenience for precompilation.
    template.source = 'function(' + (settings.variable || 'obj') + '){\n' + source + '}';

    return template;
  };

  // Add a "chain" function, which will delegate to the wrapper.
  _.chain = function(obj) {
    return _(obj).chain();
  };

  // OOP
  // ---------------
  // If Underscore is called as a function, it returns a wrapped object that
  // can be used OO-style. This wrapper holds altered versions of all the
  // underscore functions. Wrapped objects may be chained.

  // Helper function to continue chaining intermediate results.
  var result = function(obj) {
    return this._chain ? _(obj).chain() : obj;
  };

  // Add all of the Underscore functions to the wrapper object.
  _.mixin(_);

  // Add all mutator Array functions to the wrapper.
  each(['pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'], function(name) {
    var method = ArrayProto[name];
    _.prototype[name] = function() {
      var obj = this._wrapped;
      method.apply(obj, arguments);
      if ((name == 'shift' || name == 'splice') && obj.length === 0) delete obj[0];
      return result.call(this, obj);
    };
  });

  // Add all accessor Array functions to the wrapper.
  each(['concat', 'join', 'slice'], function(name) {
    var method = ArrayProto[name];
    _.prototype[name] = function() {
      return result.call(this, method.apply(this._wrapped, arguments));
    };
  });

  _.extend(_.prototype, {

    // Start chaining a wrapped Underscore object.
    chain: function() {
      this._chain = true;
      return this;
    },

    // Extracts the result from a wrapped and chained object.
    value: function() {
      return this._wrapped;
    }

  });

}).call(this);
}, "src/a": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  var i, re, s;

  re = /^\s$/;

  console.info((function() {
    var _i, _results;

    _results = [];
    for (i = _i = 0; _i < 65536; i = ++_i) {
      if (re.test(s = String.fromCharCode(i))) {
        _results.push(i);
      }
    }
    return _results;
  })());

}).call(this);
}, "src/command": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  var exec, fs, optimist;

  fs = require('fs');

  optimist = require('optimist');

  exec = require('./compiler').exec;

  this.main = function() {
    var argv, uCode, uStream;

    argv = optimist.usage('Usage: u [ path/to/script.u ]\n\nWhen invoked without arguments, `u\' reads source code from stdin.').describe({
      h: 'display this help message'
    }).alias({
      h: 'help'
    }).boolean(['h']).argv;
    if (argv.help) {
      return optimist.showHelp();
    }
    if (argv._.length > 2) {
      optimist.printUsage();
      return process.exit(1);
    }
    uStream = argv._.length ? fs.createReadStream(argv._[0]) : process.stdin;
    uCode = '';
    uStream.setEncoding('utf8');
    uStream.on('data', function(s) {
      return uCode += s;
    });
    uStream.on('end', function() {
      return exec(uCode);
    });
  };

}).call(this);
}, "src/compiler": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  var assignmentNames, compile, helpers, nameToJS, parse, renderJS, renderPatternJS, stdlib, withLocal, wrapInClosure, _;

  _ = require('../lib/underscore');

  parse = require('./peg-parser/u-grammar').parse;

  stdlib = require('./stdlib');

  helpers = require('./helpers');

  this.exec = function(uCode, ctx) {
    if (ctx == null) {
      ctx = Object.create(stdlib);
    }
    return (eval("(function (ctx, helpers) {\n    return " + (compile(uCode)) + ";\n})"))(ctx, helpers);
  };

  this.compile = compile = function(uCode) {
    var ast;

    ast = parse(uCode);
    if (ast === false) {
      throw Error('Syntax error');
    }
    return renderJS(ast);
  };

  renderJS = function(node) {
    var assignments, body, clause, exprType, guard, h, i, keys, namesToExport, pattern, r, resultJS, resultingBody, resultingGuard, resultingPattern, statements, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;

    if (node === '_') {
      throw Error('Invalid currying');
    }
    keys = _(node).keys();
    if (keys.length !== 1) {
      throw Error('Compiler error');
    }
    exprType = keys[0];
    node = node[exprType];
    switch (exprType) {
      case 'program':
        statements = _(node).map(function(child) {
          return "(" + (renderJS(child)) + ")";
        });
        return "(" + (statements.join(',')) + ")";
      case 'const':
        return renderJS(node);
      case 'number':
        return node.replace(/^~/, '-');
      case 'string':
        return JSON.stringify(/^'\(/.test(node) ? (h = {
          n: '\n',
          t: '\t',
          ')': ')',
          "'": "'",
          '\n': ''
        }, node.slice(2, -1).replace(/'[nt\)'\n]/g, function(x) {
          return h[x[1]];
        })) : node.slice(1));
      case 'name':
        return nameToJS(node);
      case 'dollarConstant':
        switch (node) {
          case '$':
            return 'null';
          case '$f':
            return 'false';
          case '$t':
            return 'true';
          case '$pinf':
            return 'Infinity';
          case '$ninf':
            return '(-Infinity)';
          case '$e':
            return 'Math.E';
          case '$pi':
            return 'Math.PI';
          case '$np':
            throw Error('$np is not implemented');
            break;
          default:
            throw Error('Unrecognised constant, ' + JSON.stringify(node));
        }
        break;
      case 'sequence':
        return "[" + (_(node.elements).map(renderJS).join(',')) + "]";
      case 'expr':
        if (node[0].argument === '_') {
          if (node.length === 1) {
            throw Error('A single underscore cannot be used as an expression.');
          }
          if (node[1].argument === '_') {
            r = renderJS(node[1].operator);
          } else {
            r = "helpers.curryRight(" + (renderJS(node[1].operator)) + "," + (renderJS(node[1].argument)) + ")";
          }
          i = 2;
        } else {
          r = renderJS(node[0].argument);
          i = 1;
        }
        return _(node.slice(i)).reduce(function(r, expr) {
          if (expr.argument === '_') {
            return "helpers.curryLeft(" + (renderJS(expr.operator)) + ", " + r + ")";
          } else {
            return "(" + (renderJS(expr.operator)) + ")([" + r + "," + (renderJS(expr.argument)) + "])";
          }
        }, r);
      case 'def':
        if (node.assignment) {
          return renderJS(node);
        } else {
          assignments = node.assignments;
          namesToExport = assignmentNames(assignments);
          return "helpers.assignmentsWithLocal(ctx,\n  function (ctx) {\n    " + (renderJS(node.local)) + ";\n    " + (_(assignments).map(renderJS).join(';\n')) + ";\n  },\n  [" + (_(namesToExport).map(JSON.stringify).join(',')) + "])";
        }
        break;
      case 'assignment':
        return renderPatternJS(node.pattern, renderJS(_(node).pick('expr')));
      case 'defs':
        return _(node).map(renderJS).join(';\n');
      case 'closure':
        return renderJS(node);
      case 'parametric':
        return withLocal(node.local, renderJS(_(node).pick('expr')));
      case 'conditional':
        r = _(node.tests).reduce(function(r, test) {
          return r + ("(" + (renderJS(test.condition)) + ")?(" + (renderJS(_(test).pick('expr'))) + "):");
        }, '');
        r += node["else"] ? renderJS(node["else"]) : 'null';
        return withLocal(node.local, r);
      case 'function':
        resultJS = '';
        _ref = node.clauses;
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          _ref1 = _ref[i].clause, (_ref2 = _ref1.functionlhs, pattern = _ref2.pattern, guard = _ref2.guard), body = _ref1.body;
          resultingPattern = pattern || resultingPattern || ((_ref3 = node.clauses[i - 1]) != null ? _ref3.clause.functionlhs.pattern : void 0);
          resultingGuard = guard || resultingGuard || ((_ref4 = node.clauses[i - 1]) != null ? _ref4.clause.functionlhs.guard : void 0);
          if (!(resultingBody = body || resultingBody)) {
            _ref5 = node.clauses.slice(i + 1);
            for (_j = 0, _len1 = _ref5.length; _j < _len1; _j++) {
              clause = _ref5[_j];
              if (body = clause.clause.body) {
                resultingBody = body;
                break;
              }
            }
          }
          resultJS += "helpers.withNewContext(ctx, function (ctx) {\n    var enter = (" + (resultingPattern != null ? renderPatternJS(resultingPattern, 'arg') : 'true') + ") &&\n                (" + (resultingGuard != null ? renderJS(resultingGuard) : 'true') + ");\n    if (enter) {\n        body = (" + (resultingBody != null ? renderJS(resultingBody) : 'null') + ");\n    }\n    return enter;\n}) ||";
        }
        resultJS += 'null';
        resultJS = "helpers.createLambda(ctx, function (arg, ctx) {\n    var body = null;\n    " + resultJS + ";\n    return body;\n})";
        if (node.local) {
          resultJS = "helpers.withNewContext(ctx, function (ctx) {\n  ctx._function = " + resultJS + ";\n  " + (renderJS(node.local)) + ";\n  return ctx._function;\n})";
        }
        return resultJS;
      default:
        throw Error('Compiler error: Unrecognised node type, ' + exprType);
    }
  };

  withLocal = function(local, expression) {
    if (local != null) {
      return "helpers.withNewContext(ctx, function (ctx) {\n  " + (renderJS(local)) + ";\n  return " + expression + ";\n})";
    } else {
      return expression;
    }
  };

  nameToJS = function(name) {
    var parentChain;

    if (/^[a-z_\$][a-z0-9_\$]*$/i.test(name)) {
      return "ctx." + name;
    } else if (name.match(/^@+$/)) {
      parentChain = '';
      _(name.length - 1).times(function() {
        return parentChain += '._parent';
      });
      return "function (arg) {\n  return ctx" + parentChain + "._function(arg, ctx);\n}";
    } else {
      return "ctx[" + (JSON.stringify(name)) + "]";
    }
  };

  renderPatternJS = function(pattern, valueJS) {
    var konst, leftArg, name, operator, rightArg, seq, value, _ref, _ref1;

    if (pattern.expr) {
      return renderPatternJS(pattern.expr, valueJS);
    }
    if (pattern.length === 1) {
      value = pattern[0].argument;
      if (value === '_') {
        return 'true';
      } else if (konst = value["const"]) {
        if (name = konst.name) {
          return "" + (nameToJS(name)) + "=(" + valueJS + "),true";
        } else {
          return "" + valueJS + "===(" + (renderJS(konst)) + ")";
        }
      } else if (value.expr) {
        return renderPatternJS(value, valueJS);
      } else if (valueJS !== 'v') {
        return wrapInClosure(pattern, valueJS);
      } else if (seq = (_ref = value.sequence) != null ? _ref.elements : void 0) {
        return _(seq).reduce(function(r, elem, i) {
          return r + (" && (" + (renderPatternJS(elem, "" + valueJS + "[" + i + "]")) + ")");
        }, "" + valueJS + " instanceof Array && " + valueJS + ".length===" + seq.length);
      } else {
        throw Error('Invalid pattern, pattern can\'t be a closure');
      }
    } else {
      if (valueJS !== 'v') {
        wrapInClosure(pattern, valueJS);
      }
      pattern = _(pattern);
      operator = pattern.last().operator;
      leftArg = pattern.initial();
      rightArg = [_(pattern.last()).pick('argument')];
      switch ((_ref1 = operator["const"]) != null ? _ref1.name : void 0) {
        case '\\':
          return "" + valueJS + " instanceof Array &&\n" + valueJS + ".length &&\n(" + (renderPatternJS(leftArg, valueJS + '[0]')) + ") &&\n(" + (renderPatternJS(rightArg, valueJS + '.slice(1)')) + ")";
        case '/':
          return "" + valueJS + " instanceof Array &&\n" + valueJS + ".length &&\n(" + (renderPatternJS(leftArg, valueJS + '.slice(0,-1)')) + ") &&\n(" + (renderPatternJS(rightArg, "" + valueJS + "[" + valueJS + ".length - 1]")) + ")";
        default:
          throw Error('Invalid pattern, only \\ and / are allowed');
      }
    }
  };

  wrapInClosure = function(pattern, valueJS) {
    return "(function (v) {\n  return " + (renderPatternJS(pattern, 'v')) + ";\n}(" + valueJS + "))";
  };

  assignmentNames = function(assignments) {
    var exprs, walkExpr;

    walkExpr = function(expr) {
      return _(expr).map(function(subExpr) {
        var arg, name, _ref;

        arg = subExpr.argument;
        if (name = (_ref = arg["const"]) != null ? _ref.name : void 0) {
          return name;
        } else if (arg.sequence != null) {
          return _(arg.sequence.elements).map(function(e) {
            return walkExpr(e.expr);
          });
        } else if (arg.expr != null) {
          return walkExpr(arg.expr);
        }
      });
    };
    exprs = _(assignments).map(function(assignment) {
      return assignment.assignment.pattern.expr;
    });
    return _(_(exprs).map(walkExpr)).flatten();
  };

}).call(this);
}, "src/helpers": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  this.withNewContext = function(ctx, f) {
    return f(Object.create(ctx));
  };

  this.createLambda = function(ctx, f) {
    var newCtx;

    newCtx = Object.create(ctx);
    newCtx._parent = ctx;
    return newCtx._function = function(x) {
      return f(x, newCtx);
    };
  };

  this.curryRight = function(f, y) {
    return function(x, ctx) {
      return f([x, y], ctx);
    };
  };

  this.curryLeft = function(f, x) {
    return function(y, ctx) {
      return f([x, y], ctx);
    };
  };

  this.assignmentsWithLocal = function(ctx, f, namesToExport) {
    var name, newCtx, value;

    newCtx = Object.create(ctx);
    f(newCtx);
    for (name in newCtx) {
      value = newCtx[name];
      if (namesToExport.indexOf(name) !== -1) {
        ctx[name] = newCtx[name];
      }
    }
    return null;
  };

}).call(this);
}, "src/lexer": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  var tokenDefs, _;

  _ = require('../lib/underscore');

  tokenDefs = [['-', /\s+/], ['-', /"[^a-z\{].*/i], ['-', /^#!.*/i], ['-', /"\{.*(?:\s*(?:"|"[^\}].*|[^"].*)[\n\r]+)*"\}.*/], ['number', /~?\d+(?:\.\d+)?/], ['string', /'\(('[^]|[^'\)])*\)/], ['string', /'[^\(]/], ['string', /"[a-z][a-z0-9]*/i], ['', /(?:==|\?\{|@\{|::|\+\+|[\(\)\[\]\{\};_])/], ['dollarConstant', /\$[a-z]*/i], ['name', /[a-z][a-z0-9]*/i], ['name', /(?:<:|>:|\|:|=>|\|\||<=|>=|<>|,,|>>|<<|%%)/], ['name', /[\+\-\*:\^=<>\/\\\.\#!%~\|,&]/], ['name', /@+/]];

  (function() {
    var d, re, _i, _len, _results;

    _results = [];
    for (_i = 0, _len = tokenDefs.length; _i < _len; _i++) {
      d = tokenDefs[_i];
      re = d[1];
      _results.push(d[1] = new RegExp('^' + re.source, re.ignoreCase ? 'i' : void 0));
    }
    return _results;
  })();

  this.tokenize = function(code, opts) {
    var position;

    if (opts == null) {
      opts = {};
    }
    position = {
      line: 1,
      col: 1,
      code: code
    };
    return {
      next: function() {
        var lines, match, re, startCol, startLine, t, type, _i, _len, _ref;

        while (true) {
          if (position.code === '') {
            return {
              type: 'eof',
              value: '',
              startLine: position.line,
              startCol: position.col,
              endLine: position.line,
              endCol: position.col
            };
          }
          startLine = position.line;
          startCol = position.col;
          type = null;
          for (_i = 0, _len = tokenDefs.length; _i < _len; _i++) {
            _ref = tokenDefs[_i], t = _ref[0], re = _ref[1];
            if (match = position.code.match(re)) {
              type = t || match[0];
              break;
            }
          }
          if (!type) {
            throw Error(("Syntax error: unrecognized token at " + position.line + ":" + position.col + " ") + position.code, {
              file: opts.file,
              line: position.line,
              col: position.col,
              code: opts.code
            });
          }
          match = match[0];
          lines = match.split('\n');
          position.line += lines.length - 1;
          position.col = (lines.length === 1 ? position.col : 1) + _(lines).last().length;
          position.code = position.code.substr(match.length);
          if (type !== '-') {
            return {
              type: type,
              value: match,
              startLine: startLine,
              startCol: startCol,
              endLine: position.line,
              endCol: position.col - 1
            };
          }
        }
      },
      rollback: function(pos) {
        position.line = pos.line;
        position.col = pos.col;
        return position.code = pos.code;
      },
      getPosition: function() {
        return {
          line: position.line,
          col: position.col,
          code: position.code
        };
      }
    };
  };

}).call(this);
}, "src/parser": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  var lexer,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  lexer = require('./lexer');

  this.parse = function(code, opts) {
    var consume, demand, parseDef, parseDefOrExpr, parseExpr, parseLocal, parseProgram, parseValue, parserError, result, token, tokenStream;

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
      var r;

      r = ['program', parseDefOrExpr()].concat((function() {
        var _results;

        _results = [];
        while (consume([';'])) {
          _results.push(parseDefOrExpr());
        }
        return _results;
      })());
      if (r.length === 2) {
        return r[1];
      } else {
        return r;
      }
    };
    parseDefOrExpr = function() {
      var e, pattern, r;

      if (consume(['{'])) {
        r = ['def'];
        while (true) {
          pattern = parseExpr();
          demand('==');
          r.push(['==', pattern, parseExpr()]);
          if (!consume([';'])) {
            break;
          }
        }
        demand('}');
        return r;
      } else {
        e = parseExpr();
        if (consume(['=='])) {
          return ['==', e, parseExpr()];
        } else {
          return e;
        }
      }
    };
    parseDef = function() {
      var r, _ref;

      r = parseDefOrExpr();
      if ((_ref = r[0]) !== 'def' && _ref !== '==') {
        parserError('Expected def but found expression');
      }
      return r;
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
      var clauses, e, elseClause, guard, ifThenClauses, initialTokenType, local, pattern, r, result, t, _ref, _ref1;

      t = token;
      if (consume(['number', 'string', 'name', 'dollarConstant', '_'])) {
        return [t.type, t.value];
      } else if (consume(['('])) {
        r = parseExpr();
        demand(')');
        return r;
      } else if (consume(['['])) {
        r = ['sequence'];
        if (token.type !== ']') {
          r.push(parseExpr());
          while (consume([';'])) {
            r.push(parseExpr());
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
        clauses = [];
        while (true) {
          pattern = guard = null;
          if (token.type !== '::') {
            initialTokenType = token.type;
            e = parseValue();
            _ref = token.type === '(' ? [e, parseExpr()] : initialTokenType === '(' ? [null, e] : [e, null], pattern = _ref[0], guard = _ref[1];
          }
          demand('::');
          result = (_ref1 = token.type) === ';' || _ref1 === '++' || _ref1 === '}' ? null : parseExpr();
          clauses.push(['clause', pattern, guard, result]);
          if (!consume([';'])) {
            break;
          }
        }
        local = token.type === '++' ? parseLocal() : null;
        demand('}');
        return ['function'].concat(clauses, [local]);
      } else {
        return parserError("Expected value but found " + t.type);
      }
    };
    parseLocal = function() {
      demand('++');
      return ['local', parseDef()].concat((function() {
        var _results;

        _results = [];
        while (consume(';')) {
          _results.push(parseDef());
        }
        return _results;
      })());
    };
    result = parseProgram();
    demand('eof');
    return result;
  };

}).call(this);
}, "src/peg-parser/parser": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  var tokenize, _,
    __slice = [].slice;

  _ = require('../../lib/underscore');

  tokenize = require('../lexer').tokenize;

  this.Peg = (function() {
    var node;

    function Peg() {
      this.grammar = this.getGrammar();
    }

    Peg.prototype.parse = function(code) {
      this.tokenStream = tokenize(code);
      return this.seq(this.grammar.start, 'eof')();
    };

    node = function(key, value) {
      var result;

      result = {};
      result[key] = value === true ? null : value;
      return result;
    };

    Peg.prototype.ref = function(rule, alias) {
      var _this = this;

      if (alias == null) {
        alias = null;
      }
      return function() {
        var parsed;

        parsed = _this.parseExpression(_this.grammar.rules[rule]);
        if (parsed !== false) {
          return node(alias || rule, parsed);
        } else {
          return false;
        }
      };
    };

    Peg.prototype.seq = function() {
      var expressions,
        _this = this;

      expressions = arguments;
      return function() {
        var expression, parsed, position, result, _i, _len;

        result = [];
        position = _this.tokenStream.getPosition();
        for (_i = 0, _len = expressions.length; _i < _len; _i++) {
          expression = expressions[_i];
          parsed = _this.parseExpression(expression);
          if (parsed !== false) {
            if (parsed instanceof Object && !(parsed instanceof Array)) {
              result.push(parsed);
            }
          } else {
            result = false;
            _this.tokenStream.rollback(position);
            break;
          }
        }
        if (result) {
          return _.extend.apply(_, [{}].concat(__slice.call(result)));
        } else {
          return false;
        }
      };
    };

    Peg.prototype.optional = function(expression) {
      var _this = this;

      return function() {
        var parsed, position;

        position = _this.tokenStream.getPosition();
        parsed = _this.parseExpression(expression);
        if (parsed !== false) {
          return parsed;
        } else {
          _this.tokenStream.rollback(position);
          return true;
        }
      };
    };

    Peg.prototype.or = function(expression1, expression2) {
      var _this = this;

      return function() {
        var result;

        result = _this.getParseResult(expression1);
        if (result === false) {
          result = _this.getParseResult(expression2);
        }
        return result;
      };
    };

    Peg.prototype.oneOrMore = function(expression) {
      var _this = this;

      return function() {
        var more, r, result;

        r = _this.getParseResult(expression);
        if (r !== false) {
          result = [r];
          more = _this.zeroOrMore(expression)();
          if (more) {
            result.concat(more);
          }
          return result;
        } else {
          return false;
        }
      };
    };

    Peg.prototype.zeroOrMore = function(expression) {
      var _this = this;

      return function() {
        var r, _results;

        _results = [];
        while ((r = _this.getParseResult(expression)) !== false) {
          _results.push(r);
        }
        return _results;
      };
    };

    Peg.prototype.getParseResult = function(expression) {
      var parsed, position;

      position = this.tokenStream.getPosition();
      parsed = this.parseExpression(expression);
      if (parsed !== false) {
        return parsed;
      } else {
        this.tokenStream.rollback(position);
        return false;
      }
    };

    Peg.prototype.parseExpression = function(expression) {
      var token, value;

      if (typeof expression === 'string') {
        token = this.tokenStream.next();
        if (token.type === expression) {
          return token.value;
        } else {
          return false;
        }
      } else if (typeof expression === 'function') {
        return expression();
      } else if (expression instanceof Array) {
        value = this.parseExpression(expression[1]);
        if (value !== false) {
          return node(expression[0], value);
        } else {
          return false;
        }
      } else {
        throw Error('Unknown expression type');
      }
    };

    return Peg;

  })();

}).call(this);
}, "src/peg-parser/u-grammar": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  var Peg, UGrammar, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Peg = require('./parser').Peg;

  UGrammar = (function(_super) {
    __extends(UGrammar, _super);

    function UGrammar() {
      _ref = UGrammar.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    UGrammar.prototype.getGrammar = function() {
      var uGrammar;

      uGrammar = {
        rules: {
          program: ['program', this.oneOrMoreWithSep(this.or(this.ref('def'), this.ref('expr')), ';')],
          def: this.or(this.ref('assignment'), this.seq('{', ['assignments', this.oneOrMoreWithSep(this.ref('assignment'), ';')], this.ref('local'), '}')),
          assignment: this.seq(this.ref('pattern'), '==', this.ref('expr')),
          expr: this.oneOrMoreWithSep(this.ref('value', 'argument'), this.ref('value', 'operator')),
          value: this.or(this.ref('const'), this.or('_', this.or(this.ref('sequence'), this.or(this.seq('(', this.ref('expr'), ')'), this.ref('closure'))))),
          sequence: this.seq('[', ['elements', this.zeroOrMoreWithSep(this.ref('expr'), ';')], ']'),
          closure: this.or(this.ref('parametric'), this.or(this.ref('conditional'), this.ref('function'))),
          parametric: this.seq('{', this.ref('expr'), this.ref('local'), '}'),
          conditional: this.seq('?{', ['tests', this.oneOrMoreWithSep(this.seq(['condition', this.ref('expr')], '::', this.ref('expr')), ';')], this.optional(this.seq(';', ['else', this.ref('expr')])), this.optional(this.ref('local')), '}'),
          "function": this.seq('@{', ['clauses', this.oneOrMoreWithSep(this.ref('clause'), ';')], this.optional(this.ref('local')), '}'),
          clause: this.seq(this.ref('functionlhs'), '::', this.optional(['body', this.ref('expr')])),
          functionlhs: this.or(this.ref('guard'), this.seq(this.optional(this.ref('pattern')), this.optional(this.ref('guard')))),
          guard: this.seq('(', this.ref('expr'), ')'),
          local: this.seq('++', ['defs', this.oneOrMoreWithSep(this.ref('def'), ';')]),
          "const": this.or(['number', 'number'], this.or(['string', 'string'], this.or(['name', 'name'], ['dollarConstant', 'dollarConstant']))),
          pattern: this.ref('expr')
        }
      };
      uGrammar.start = uGrammar.rules.program;
      return uGrammar;
    };

    UGrammar.prototype.zeroOrMoreWithSep = function(rule, separator) {
      return this.someWithSep(rule, separator, []);
    };

    UGrammar.prototype.oneOrMoreWithSep = function(rule, separator) {
      return this.someWithSep(rule, separator, false);
    };

    UGrammar.prototype.someWithSep = function(rule, separator, zeroValue) {
      var _this = this;

      return function() {
        var parsed;

        parsed = _this.getParseResult(rule);
        if (parsed) {
          return [parsed].concat(_this.zeroOrMore(_this.seq(separator, rule))());
        } else {
          return zeroValue;
        }
      };
    };

    return UGrammar;

  })(Peg);

  this.parse = function(code) {
    return (new UGrammar).parse(code);
  };

}).call(this);
}, "src/stdlib": function(exports, require, module) {// Generated by CoffeeScript 1.6.2
(function() {
  var coerce, eq, fmt, gcd, isNodeJS, k, polymorphic, reads, round, v, writeHelper, _,
    __slice = [].slice;

  _ = require('../lib/underscore');

  polymorphic = function() {
    var f, fs, paramNames, signatures, t;

    fs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    signatures = (function() {
      var _i, _len, _results;

      _results = [];
      for (_i = 0, _len = fs.length; _i < _len; _i++) {
        f = fs[_i];
        paramNames = ('' + f).replace(/^\s*function\s*\(([^\)]*)\)[^]+$/, '$1').split(/\s*,\s*/);
        _results.push(((function() {
          var _j, _len1, _results1;

          _results1 = [];
          for (_j = 0, _len1 = paramNames.length; _j < _len1; _j++) {
            t = paramNames[_j];
            _results1.push(t[0]);
          }
          return _results1;
        })()).join(''));
      }
      return _results;
    })();
    return function(a) {
      var i, xs, _i, _len;

      for (i = _i = 0, _len = fs.length; _i < _len; i = ++_i) {
        f = fs[i];
        if ((xs = coerce(a, signatures[i]))) {
          return f.apply(null, xs);
        }
      }
      throw Error("Unsupported operation,\nArgument: " + (JSON.stringify(a)) + "\nAcceptable signatures: " + (JSON.stringify(signatures)) + "\nFunction name: " + (JSON.stringify(arguments.callee.uName)));
    };
  };

  coerce = function(a, ts) {
    var x, y, _ref, _ref1;

    if (ts.length === 2) {
      if (a instanceof Array && a.length === 2 && (x = coerce(a[0], ts[0])) && (y = coerce(a[1], ts[1]))) {
        return x.concat(y);
      }
    } else if (ts.length === 1) {
      switch (ts) {
        case 'n':
          if ((_ref = typeof a) === 'number' || _ref === 'boolean') {
            return [+a];
          }
          break;
        case 'i':
          if (((_ref1 = typeof a) === 'number' || _ref1 === 'boolean') && +a === ~~a) {
            return [+a];
          }
          break;
        case 'b':
          if (typeof a === 'boolean') {
            return [a];
          }
          break;
        case 'q':
          if (a instanceof Array || typeof a === 'string') {
            return [a];
          }
          break;
        case 's':
          if (typeof a === 'string') {
            return [a];
          }
          break;
        case 'p':
          return void 0;
        case 'f':
          if (typeof a === 'function') {
            return [a];
          }
          break;
        case 'x':
          return [a];
        default:
          throw Error('Bad type symbol, ' + JSON.stringify(ts));
      }
    } else {
      throw Error('Bad type signature, ' + JSON.stringify(ts));
    }
  };

  eq = function(x, y) {
    var i, xi, _i, _len;

    if (x === y) {
      return true;
    } else if (x instanceof Array && y instanceof Array && x.length === y.length) {
      for (i = _i = 0, _len = x.length; _i < _len; i = ++_i) {
        xi = x[i];
        if (!eq(xi, y[i])) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  };

  this['+'] = polymorphic(function(n1, n2) {
    return n1 + n2;
  }, function(q1, q2) {
    return q1.concat(q2);
  });

  this['-'] = polymorphic(function(n) {
    return -n;
  }, function(n1, n2) {
    return n1 - n2;
  }, function(s1, s2) {
    var c, j, r, _i, _len;

    r = s1;
    for (_i = 0, _len = s2.length; _i < _len; _i++) {
      c = s2[_i];
      if ((j = r.indexOf(c)) !== -1) {
        r = r.slice(0, j) + r.slice(j + 1);
      }
    }
    return r;
  }, function(q1, q2) {
    var j, r, x, y, _i, _j, _len, _len1;

    r = q1.slice(0);
    for (_i = 0, _len = q2.length; _i < _len; _i++) {
      x = q2[_i];
      for (j = _j = 0, _len1 = r.length; _j < _len1; j = ++_j) {
        y = r[j];
        if (!(eq(x, y))) {
          continue;
        }
        r.splice(j, 1);
        break;
      }
    }
    return r;
  });

  this['*'] = polymorphic(function(n) {
    return (n > 0) - (n < 0);
  }, function(n1, n2) {
    return n1 * n2;
  }, function(q, i) {
    var r, _i;

    if (i < 0) {
      throw Error('Multiplier for sequence or string must be non-negative.');
    }
    r = q.slice(0, 0);
    for (_i = 0; 0 <= i ? _i < i : _i > i; 0 <= i ? _i++ : _i--) {
      r = r.concat(q);
    }
    return r;
  });

  this['^'] = polymorphic(function(n1, n2) {
    return Math.pow(n1, n2);
  }, function(f, i) {
    if (i < 0) {
      throw Error('Obverse functions are not supported.');
    }
    return function(a) {
      var _i;

      for (_i = 0; 0 <= i ? _i < i : _i > i; 0 <= i ? _i++ : _i--) {
        a = f(a);
      }
      return a;
    };
  });

  this[':'] = polymorphic(function(n) {
    return 1 / n;
  }, function(n1, n2) {
    return n1 / n2;
  }, function(q, i) {
    var j, l, l1, r;

    if (i <= 0) {
      throw Error('Sequence denominator must be positive.');
    }
    r = q.length % i;
    l = (q.length - r) / i;
    l1 = l + 1;
    return ((function() {
      var _i, _results;

      _results = [];
      for (j = _i = 0; 0 <= r ? _i < r : _i > r; j = 0 <= r ? ++_i : --_i) {
        _results.push(q.slice(j * l1, (j + 1) * l1));
      }
      return _results;
    })()).concat((function() {
      var _i, _results;

      _results = [];
      for (j = _i = r; r <= i ? _i < i : _i > i; j = r <= i ? ++_i : --_i) {
        _results.push(q.slice(j * l + r, (j + 1) * l + r));
      }
      return _results;
    })());
  }, function(i, q) {
    var j, _i, _ref, _results;

    if (i <= 0) {
      throw Error('Sequence numerator must be positive.');
    }
    _results = [];
    for (j = _i = 0, _ref = q.length; i > 0 ? _i < _ref : _i > _ref; j = _i += i) {
      _results.push(q.slice(j, j + i));
    }
    return _results;
  });

  this['<:'] = polymorphic(function(n) {
    return Math.floor(n);
  }, function(n1, n2) {
    var q;

    return [(q = Math.floor(n1 / n2)), n1 - q * n2];
  });

  this['>:'] = polymorphic(function(n) {
    return Math.ceil(n);
  }, function(n1, n2) {
    var q;

    return [(q = Math.ceil(n1 / n2)), n1 - q * n2];
  });

  this['|:'] = polymorphic(round = function(n) {
    var d, x;

    x = Math.floor(n);
    d = n - x;
    if (d < .5) {
      return x;
    } else if (d > .5) {
      return x + 1;
    } else {
      return x + Math.abs(x) % 2;
    }
  }, function(n1, n2) {
    var q;

    return [(q = round(n1 / n2)), n1 - q * n2];
  });

  this['<'] = polymorphic(function(n1, n2) {
    return n1 < n2;
  }, function(s1, s2) {
    return s1 < s2;
  }, function(i, q) {
    if (i >= 0) {
      return q.slice(0, i);
    } else {
      return q.slice(-i);
    }
  }, function(f, q) {
    var i, r, _i, _ref;

    if (q.length) {
      r = q[q.length - 1];
      for (i = _i = _ref = q.length - 2; _i >= 0; i = _i += -1) {
        r = f([q[i], r]);
      }
      return r;
    } else {
      return null;
    }
  }, function(f) {
    throw Error('<.f is not implemented');
  });

  this['<='] = polymorphic(function(n1, n2) {
    return n1 <= n2;
  }, function(s1, s2) {
    return s1 <= s2;
  });

  this['='] = polymorphic(function(x1, x2) {
    return eq(x1, x2);
  });

  this['<>'] = polymorphic(function(x1, x2) {
    return !eq(x1, x2);
  });

  this['>='] = polymorphic(function(n1, n2) {
    return n1 >= n2;
  }, function(s1, s2) {
    return s1 >= s2;
  });

  this['>'] = polymorphic(function(n1, n2) {
    return n1 > n2;
  }, function(s1, s2) {
    return s1 > s2;
  }, function(i, q) {
    if (i >= 0) {
      return q.slice(Math.max(0, q.length - i));
    } else {
      return q.slice(0, Math.max(0, q.length + i));
    }
  }, function(f, q) {
    var i, r, _i, _ref;

    if (q.length) {
      r = q[0];
      for (i = _i = 1, _ref = q.length; _i < _ref; i = _i += 1) {
        r = f([r, q[i]]);
      }
      return r;
    } else {
      return null;
    }
  }, function(f) {
    throw Error('>.f is not implemented');
  });

  this['|'] = polymorphic(function(n) {
    return Math.abs(n);
  }, function(b1, b2) {
    return b1 || b2;
  }, function(n1, n2) {
    return Math.max(n1, n2);
  }, function(s1, s2) {
    var r, x, _i, _len;

    r = s1;
    for (_i = 0, _len = s2.length; _i < _len; _i++) {
      x = s2[_i];
      if (r.indexOf(x) === -1) {
        r += x;
      }
    }
    return r;
  }, function(q1, q2) {
    var found, r, x, y, _i, _j, _len, _len1;

    r = q1.slice(0);
    for (_i = 0, _len = q2.length; _i < _len; _i++) {
      x = q2[_i];
      found = false;
      for (_j = 0, _len1 = r.length; _j < _len1; _j++) {
        y = r[_j];
        if (!(eq(y, x))) {
          continue;
        }
        found = true;
        break;
      }
      if (!found) {
        r.push(x);
      }
    }
    return r;
  }, function(f) {
    return function(a) {
      if (!(a instanceof Array) || a.length < 2) {
        return null;
      } else {
        return f([a[1], a[0]].concat(a.slice(2)));
      }
    };
  });

  this['&'] = polymorphic(function(b1, b2) {
    return b1 && b2;
  }, function(n1, n2) {
    return Math.min(n1, n2);
  }, function(s1, s2) {
    var r, x, _i, _len;

    r = '';
    for (_i = 0, _len = s1.length; _i < _len; _i++) {
      x = s1[_i];
      if (s2.indexOf(x) !== -1) {
        r += x;
      }
    }
    return r;
  }, function(q1, q2) {
    var r, x, y, _i, _j, _len, _len1;

    r = [];
    for (_i = 0, _len = q1.length; _i < _len; _i++) {
      x = q1[_i];
      for (_j = 0, _len1 = q2.length; _j < _len1; _j++) {
        y = q2[_j];
        if (!(eq(x, y))) {
          continue;
        }
        r.push(x);
        break;
      }
    }
    return r;
  });

  this[','] = polymorphic(function(n1, n2) {
    var _i, _results;

    return (function() {
      _results = [];
      for (var _i = n1; n1 <= n2 ? _i < n2 : _i > n2; n1 <= n2 ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this);
  }, function(n1, q) {
    var i, n2, n3, _i, _ref, _ref1, _results;

    if (!(q instanceof Array) || q.length !== 2 || ((_ref = typeof q[0]) !== 'number' && _ref !== 'boolean') || ((_ref1 = typeof q[1]) !== 'number' && _ref1 !== 'boolean')) {
      throw Error('The signature of "," is either "n1,n2" or "n1,[n2;n3]".');
    }
    n2 = +q[0];
    n3 = +q[1];
    _results = [];
    for (i = _i = n1; n3 > 0 ? _i < n2 : _i > n2; i = _i += n3) {
      _results.push(i);
    }
    return _results;
  });

  this[',,'] = polymorphic(function(n1, n2) {
    var _i, _results;

    return (function() {
      _results = [];
      for (var _i = n1; n1 <= n2 ? _i <= n2 : _i >= n2; n1 <= n2 ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this);
  }, function(n1, q) {
    var i, n2, n3, _i, _ref, _ref1, _results;

    if (!(q instanceof Array) || q.length !== 2 || ((_ref = typeof q[0]) !== 'number' && _ref !== 'boolean') || ((_ref1 = typeof q[1]) !== 'number' && _ref1 !== 'boolean')) {
      throw Error('The signature of "," is either "n1,n2" or "n1,[n2;n3]".');
    }
    n2 = +q[0];
    n3 = +q[1];
    _results = [];
    for (i = _i = n1; n3 > 0 ? _i <= n2 : _i >= n2; i = _i += n3) {
      _results.push(i);
    }
    return _results;
  });

  this['#'] = polymorphic(function(q) {
    return q.length;
  });

  this['\\'] = polymorphic(function(x, s) {
    if (typeof x !== 'string' || x.length !== 1) {
      throw Error('In the expression "x\\s" where "s" is a string, "x" must be a string of length 1.');
    }
    return x + s;
  }, function(x, q) {
    return [x].concat(q);
  }, function(x1, x2) {
    return [x1, x2];
  });

  this['/'] = polymorphic(function(s, x) {
    if (typeof x !== 'string' || x.length !== 1) {
      throw Error('In the expression "s/x" where "s" is a string, "x" must be a string of length 1.');
    }
    return s + x;
  }, function(q, x) {
    return q.concat([x]);
  }, function(x1, x2) {
    return [x1, x2];
  });

  this['~'] = polymorphic(function(b) {
    return !b;
  }, function(f) {
    return function(a) {
      var r;

      if (typeof (r = f(a)) === 'boolean') {
        return !r;
      } else {
        return null;
      }
    };
  }, function(s) {
    return s.split('').reverse().join('');
  }, function(q) {
    return q.slice(0).reverse();
  });

  this['!'] = polymorphic(function(f, q) {
    var x, _i, _len, _results;

    _results = [];
    for (_i = 0, _len = q.length; _i < _len; _i++) {
      x = q[_i];
      _results.push(f(x));
    }
    return _results;
  }, function(q1, q2) {
    var f, p, x, _i, _len, _ref, _results;

    if (!(q1 instanceof Array) || q1.length !== 2 || !((typeof q1[0] === (_ref = typeof q1[1]) && _ref === 'function'))) {
      throw Error('When "!" is used in the form "q1!q2", "q1" must be a sequence of two functions.');
    }
    p = q1[0], f = q1[1];
    _results = [];
    for (_i = 0, _len = q2.length; _i < _len; _i++) {
      x = q2[_i];
      if (p(x)) {
        _results.push(f(x));
      }
    }
    return _results;
  });

  this['%'] = polymorphic(function(f, s) {
    return s.replace(/[^]/g, function(x) {
      if (f(x)) {
        return x;
      } else {
        return '';
      }
    });
  }, function(f, q) {
    var x, _i, _len, _results;

    _results = [];
    for (_i = 0, _len = q.length; _i < _len; _i++) {
      x = q[_i];
      if (f(x)) {
        _results.push(x);
      }
    }
    return _results;
  });

  this['%%'] = polymorphic(function(f, s) {
    var r, x, _i, _len;

    r = ['', ''];
    for (_i = 0, _len = s.length; _i < _len; _i++) {
      x = s[_i];
      r[+(!f(x))] += x;
    }
    return r;
  }, function(f, q) {
    var r, x, _i, _len;

    r = [[], []];
    for (_i = 0, _len = q.length; _i < _len; _i++) {
      x = q[_i];
      r[+(!f(x))].push(x);
    }
    return r;
  });

  this['||'] = polymorphic(function(q) {
    var a, i, m, _i, _j, _len, _results;

    if (!(q instanceof Array)) {
      throw Error('The argument to || must be a sequence.');
    }
    if (q.length === 0) {
      return [];
    }
    m = Infinity;
    for (_i = 0, _len = q.length; _i < _len; _i++) {
      a = q[_i];
      if (!(a instanceof Array)) {
        throw Error('The argument to || must be a sequence of sequences.');
      }
      m = Math.min(m, a.length);
    }
    _results = [];
    for (i = _j = 0; 0 <= m ? _j < m : _j > m; i = 0 <= m ? ++_j : --_j) {
      _results.push((function() {
        var _k, _len1, _results1;

        _results1 = [];
        for (_k = 0, _len1 = q.length; _k < _len1; _k++) {
          a = q[_k];
          _results1.push(a[i]);
        }
        return _results1;
      })());
    }
    return _results;
  });

  this['.'] = polymorphic(function(f, x) {
    return f(x);
  }, function(q, i) {
    if ((0 <= i && i < q.length)) {
      return q[i];
    } else if ((-q.length <= i && i < 0)) {
      return q[q.length + i];
    } else {
      return null;
    }
  }, function(q, f) {
    var i, x, _i, _len;

    for (i = _i = 0, _len = q.length; _i < _len; i = ++_i) {
      x = q[i];
      if (f(x)) {
        return i;
      }
    }
    return null;
  });

  this['=>'] = polymorphic(function(x, f) {
    return f(x);
  });

  this['>>'] = polymorphic(function(f1, f2) {
    return function(a) {
      return f2(f1(a));
    };
  });

  this['<<'] = polymorphic(function(f1, f2) {
    return function(a) {
      return f1(f2(a));
    };
  });

  this.int = polymorphic(function(n) {
    if (n >= 0) {
      return Math.floor(n);
    } else {
      return Math.ceil(n);
    }
  });

  this.gcd = gcd = polymorphic(function(n1, n2) {
    var _ref;

    if (n1 !== ~~n1 || n2 !== ~~n2 || n1 <= 0 || n2 <= 0) {
      throw Error('"gcd" is implemented only for positive integers');
    }
    while (n2) {
      _ref = [n2, n1 % n2], n1 = _ref[0], n2 = _ref[1];
    }
    return n1;
  });

  this.lcm = polymorphic(function(n1, n2) {
    return n1 * (n2 / gcd([n1, n2]));
  });

  this.diag = polymorphic(function(q) {
    var r, x, _i, _len;

    r = 0;
    for (_i = 0, _len = q.length; _i < _len; _i++) {
      x = q[_i];
      if (typeof x !== 'number') {
        throw Error('diag\'s argument must consist of numbers.');
      }
      r += x * x;
    }
    return Math.sqrt(r);
  });

  this.sin = polymorphic(function(n) {
    return Math.sin(n);
  });

  this.cos = polymorphic(function(n) {
    return Math.cos(n);
  });

  this.tan = polymorphic(function(n) {
    return Math.tan(n);
  });

  this.asin = polymorphic(function(n) {
    return Math.asin(n);
  });

  this.acos = polymorphic(function(n) {
    return Math.acos(n);
  });

  this.atan = polymorphic(function(n1, n2) {
    return Math.atan2(n1, n2);
  });

  this.log = polymorphic(function(n1, n2) {
    return Math.log(n2) / Math.log(n1);
  });

  this.empty = function(x) {
    return (x instanceof Array || typeof x === 'string') && x.length === 0;
  };

  this.fst = polymorphic(function(q) {
    if (q.length) {
      return q[0];
    } else {
      return null;
    }
  });

  this.bst = polymorphic(function(q) {
    if (q.length) {
      return q[q.length - 1];
    } else {
      return null;
    }
  });

  this.butf = polymorphic(function(q) {
    return q.slice(1);
  });

  this.butb = polymorphic(function(q) {
    return q.slice(0, -1);
  });

  this.rol = polymorphic(function(q) {
    return q.slice(1).concat(q.slice(0, 1));
  });

  this.ror = polymorphic(function(q) {
    return q.slice(-1).concat(q.slice(0, -1));
  });

  this.cut = polymorphic(function(i, q) {
    return [q.slice(0, i), q.slice(i)];
  }, function(f, q) {
    var i;

    i = 0;
    while (i < q.length && f(q[i])) {
      i++;
    }
    return [q.slice(0, i), q.slice(i)];
  });

  this.update = polymorphic(function(q1, q2) {
    var f, i, p, r, u, x, _i, _len, _ref;

    if (typeof q2 === 'string') {
      throw Error('Second argument to "update" cannot be a string.');
    }
    if (q1.length === 2 && q1[0] === ~~q1[0] && typeof q1[1] === 'function') {
      i = q1[0], f = q1[1];
      if (i < 0) {
        i += q2.length;
      }
      if ((0 <= i && i < q2.length)) {
        return q2.slice(0, i).concat([f(q2[i])], q2.slice(i + 1));
      } else {
        return null;
      }
    } else if (q1.length === 3 && (typeof q1[0] === (_ref = typeof q1[1]) && _ref === 'function')) {
      p = q1[0], f = q1[1], u = q1[2];
      r = null;
      for (i = _i = 0, _len = q2.length; _i < _len; i = ++_i) {
        x = q2[i];
        if (!(p(x))) {
          continue;
        }
        r = q2.slice(0, i).concat([f(x)], q2.slice(i + 1));
        break;
      }
      return r || q2.concat([u]);
    } else {
      throw Error('Invalid first argument to "update"');
    }
  });

  this.before = polymorphic(function(q1, q2) {
    var f, i, p, r, u, x, _i, _len, _ref;

    if (typeof q2 === 'string') {
      throw Error('Second argument to "before" cannot be a string.');
    }
    if (q1.length === 2 && q1[0] === ~~q1[0]) {
      i = q1[0], u = q1[1];
      if (i < 0) {
        i += q2.length;
      }
      if ((0 <= i && i < q2.length)) {
        return q2.slice(0, i).concat([u], q2.slice(i));
      } else {
        return null;
      }
    } else if (q1.length === 3 && (typeof q1[0] === (_ref = typeof q1[1]) && _ref === 'function')) {
      p = q1[0], f = q1[1], u = q1[2];
      r = null;
      for (i = _i = 0, _len = q2.length; _i < _len; i = ++_i) {
        x = q2[i];
        if (p(x)) {
          return q2.slice(0, i).concat([f(x)], q2.slice(i));
        }
      }
      return q2.concat([u]);
    } else {
      throw Error('Invalid first argument to "before"');
    }
  });

  this.after = polymorphic(function(q1, q2) {
    var f, i, p, r, u, x, _i, _len, _ref;

    if (typeof q2 === 'string') {
      throw Error('Second argument to "after" cannot be a string.');
    }
    if (q1.length === 2 && q1[0] === ~~q1[0]) {
      i = q1[0], u = q1[1];
      if (i < 0) {
        i += q2.length;
      }
      if ((0 <= i && i < q2.length)) {
        return q2.slice(0, i + 1).concat([u], q2.slice(i + 1));
      } else {
        return null;
      }
    } else if (q1.length === 3 && (typeof q1[0] === (_ref = typeof q1[1]) && _ref === 'function')) {
      p = q1[0], f = q1[1], u = q1[2];
      r = null;
      for (i = _i = 0, _len = q2.length; _i < _len; i = ++_i) {
        x = q2[i];
        if (p(x)) {
          return q2.slice(0, i + 1).concat([f(x)], q2.slice(i + 1));
        }
      }
      return [u].concat(q2);
    } else {
      throw Error('Invalid first argument to "after"');
    }
  });

  this.count = polymorphic(function(f, q) {
    var r, x, _i, _len;

    r = 0;
    for (_i = 0, _len = q.length; _i < _len; _i++) {
      x = q[_i];
      if (f(x)) {
        r++;
      }
    }
    return r;
  });

  isNodeJS = typeof window === "undefined" || window === null;

  fmt = function(x) {
    if (x instanceof Array) {
      return _(x).map(fmt).join(' ');
    } else if (x === null) {
      return '$';
    } else if (typeof x === 'boolean') {
      return '$' + 'ft'[+x];
    } else {
      return '' + x;
    }
  };

  writeHelper = function(filename, data, flag) {
    var content;

    content = fmt(data);
    if (filename === '') {
      if (isNodeJS) {
        process.stdout.write(content);
      } else {
        alert(content);
      }
    } else if (typeof filename === 'string') {
      if (isNodeJS) {
        require('fs').writeFileSync(filename, content, {
          flag: flag
        });
      } else {
        localStorage.setItem(filename, flag === 'a' ? (localStorage.getItem(filename) || '') + content : content);
      }
    } else if (filename !== null) {
      throw Error('First argument to "write" or "writa" must be a string or $');
    }
    return content;
  };

  this.write = polymorphic(function(x, q) {
    return writeHelper(x, q);
  });

  this.writa = polymorphic(function(x, q) {
    return writeHelper(x, q, 'a');
  });

  this.readf = polymorphic(function(s, q) {
    var content;

    content = (function() {
      if (s) {
        if (isNodeJS) {
          return require('fs').readFileSync(s);
        } else {
          return localStorage.getItem(s);
        }
      } else {
        if (isNodeJS) {
          throw Error('Cannot read synchronously from stdin in NodeJS');
        } else {
          return prompt('Input:');
        }
      }
    })();
    if (content != null) {
      return reads([content, q]);
    } else {
      return null;
    }
  });

  this.reads = reads = polymorphic(function(s, q) {
    var item, m, r, t, _i, _ignore, _len;

    s = s.replace(/^(.*)[^]*$/, '$1');
    r = [];
    for (_i = 0, _len = q.length; _i < _len; _i++) {
      t = q[_i];
      if (!(m = s.match(/^[ \t]*([^ \t]+)(.*)$/))) {
        break;
      }
      _ignore = m[0], item = m[1], s = m[2];
      if (t === 'str') {
        r.push(item);
      } else if (t === 'num') {
        if (!/^\d+$/.test(item)) {
          return null;
        }
        r.push(parseInt(item, 10));
      } else {
        throw Error("Invalid type, " + (JSON.stringify(t)) + ".  Only \"num\" and \"str\" are allowed.");
      }
    }
    r.push(s);
    return r;
  });

  for (k in this) {
    v = this[k];
    if (typeof v === 'function') {
      v.uName = k;
    }
  }

}).call(this);
}});
