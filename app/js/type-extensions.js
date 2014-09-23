// Generated by CoffeeScript 1.7.1
(function() {
  var Set,
    __hasProp = {}.hasOwnProperty,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  String.prototype.m$rightOf = function(char) {
    return this.substr(this.lastIndexOf(char) + 1);
  };

  String.prototype.m$leftOf = function(char) {
    return this.substr(0, this.indexOf(char));
  };

  Array.prototype.m$first = function(predicate, includeIndex) {
    var element, index, _i, _len;
    if (includeIndex == null) {
      includeIndex = false;
    }
    for (index = _i = 0, _len = this.length; _i < _len; index = ++_i) {
      element = this[index];
      if (predicate(element)) {
        if (includeIndex) {
          return [element, index];
        } else {
          return element;
        }
      }
    }
    if (includeIndex) {
      return [null, null];
    } else {
      return null;
    }
  };

  Array.prototype.m$remove = function(predicate) {
    var modified;
    modified = false;
    while (this.m$removeFirst(predicate)) {
      modified = true;
    }
    return modified;
  };

  Array.prototype.m$removeFirst = function(predicate) {
    var element, index, _ref;
    _ref = this.m$first(predicate, true), element = _ref[0], index = _ref[1];
    if (element == null) {
      return false;
    }
    this.splice(index, 1);
    return true;
  };

  Array.prototype.m$clear = function() {
    this.splice(0, this.length);
    return this;
  };

  Array.prototype.m$unique = function() {
    var e, isNum, key, map, ret, _i, _len;
    map = {};
    for (_i = 0, _len = this.length; _i < _len; _i++) {
      e = this[_i];
      map[e] = typeof e === typeof 0.;
    }
    ret = [];
    for (key in map) {
      if (!__hasProp.call(map, key)) continue;
      isNum = map[key];
      if (isNum) {
        ret.push(+key);
      } else {
        ret.push(key);
      }
    }
    return ret;
  };

  Array.prototype.m$sortBy = function(key) {
    return this.sort(function(a, b) {
      var aVal, bVal;
      aVal = a[key];
      bVal = b[key];
      if (aVal < bVal) {
        return -1;
      }
      if (aVal > bVal) {
        return 1;
      }
      return 0;
    });
  };

  Array.prototype.m$contains = function(searchItem) {
    return this.indexOf(searchItem) > -1;
  };

  window.m$log = function(str, obj) {
    return console.log("" + str + ": %o", obj);
  };

  Set = (function() {
    function Set(initialData) {
      if (initialData == null) {
        initialData = [];
      }
      this.convertType = __bind(this.convertType, this);
      this.iter = __bind(this.iter, this);
      this.toArray = __bind(this.toArray, this);
      this.insertArray = __bind(this.insertArray, this);
      this.insert = __bind(this.insert, this);
      this.map = {};
      this.insertArray(initialData);
    }

    Set.prototype.insert = function(e) {
      if (this.map[e] != null) {
        return false;
      }
      this.map[e] = typeof e === typeof 0.;
      return true;
    };

    Set.prototype.insertArray = function(array) {
      var e, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        e = array[_i];
        _results.push(this.insert(e));
      }
      return _results;
    };

    Set.prototype.toArray = function() {
      var e, _ref, _results;
      _ref = this.map;
      _results = [];
      for (e in _ref) {
        if (!__hasProp.call(_ref, e)) continue;
        _results.push(this.convertType(e));
      }
      return _results;
    };

    Set.prototype.iter = function() {
      return this.toArray();
    };

    Set.prototype.convertType = function(e) {
      if (this.map[e]) {
        return +e;
      } else {
        return e;
      }
    };

    return Set;

  })();

  window.Set = Set;

  this.BaseCtrl = (function() {
    function BaseCtrl() {}

    BaseCtrl.register = function(app, name) {
      var _ref;
      if (name == null) {
        name = this.name || ((_ref = this.toString().match(/function\s*(.*?)\(/)) != null ? _ref[1] : void 0);
      }
      return app.controller(name, this);
    };

    BaseCtrl.inject = function() {
      var services;
      services = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.$inject = services;
    };

    return BaseCtrl;

  })();

}).call(this);

//# sourceMappingURL=type-extensions.map
