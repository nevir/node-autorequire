(function() {
  var Loader, STACK_PATH_EXTRACTOR, autorequire, convention, conventions, file, fs, getCallingDirectoryFromStack, lazyLoad, path, walkDirectory, _i, _len, _ref;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  fs = require('fs');
  path = require('path');
  Loader = require('./loader');
  autorequire = function() {
    var CustomConvention, convention, conventionAndOrOptions, conventionPrototype, key, options, requirePath, rootPath, value, workingDir;
    requirePath = arguments[0], conventionAndOrOptions = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (requirePath[0] !== '.') {
      raise(TypeError, 'autorequire only supports ./relative paths for now.');
    }
    workingDir = getCallingDirectoryFromStack();
    rootPath = path.normalize(workingDir + '/' + requirePath);
    if (typeof conventionAndOrOptions[conventionAndOrOptions.length - 1] === 'object') {
      options = conventionAndOrOptions.pop();
    }
    convention = conventionAndOrOptions.shift() || 'Default';
    if (typeof convention === 'string') {
      if (!conventions[convention]) {
        throw new TypeError("There is no built-in '" + convention + "' convention");
      }
      conventionPrototype = conventions[convention];
    }
    if (typeof convention === 'function') {
      conventionPrototype = convention;
    }
    if (options) {
      CustomConvention = (function() {
        __extends(CustomConvention, conventionPrototype);
        function CustomConvention() {
          CustomConvention.__super__.constructor.apply(this, arguments);
        }
        return CustomConvention;
      })();
      for (key in options) {
        if (!__hasProp.call(options, key)) continue;
        value = options[key];
        CustomConvention.prototype[key] = value;
      }
      conventionPrototype = CustomConvention;
    }
    if (conventionPrototype == null) {
      throw new TypeError('autorequire was unable to determine a valid convention, please check your arguments.');
    }
    return walkDirectory(rootPath, new conventionPrototype);
  };
  walkDirectory = function(basePath, convention) {
    var fullPath, pathComponent, pathStats, result, _i, _len, _ref;
    result = {};
    _ref = fs.readdirSync(basePath);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pathComponent = _ref[_i];
      if (pathComponent[0] !== '.') {
        fullPath = path.join(basePath, pathComponent);
        pathStats = fs.statSync(fullPath);
        (function(fullPath) {
          var componentName;
          if (pathStats.isDirectory()) {
            return lazyLoad(result, convention.directoryToProperty(pathComponent, basePath), function() {
              return walkDirectory(fullPath, convention);
            });
          } else if (pathStats.isFile()) {
            componentName = convention.fileToProperty(pathComponent, basePath);
            return lazyLoad(result, componentName, function() {
              return Loader.loadModule(componentName, fullPath, result, convention);
            });
          }
        })(fullPath);
      }
    }
    return result;
  };
  lazyLoad = function(object, property, getter) {
    return Object.defineProperty(object, property, {
      enumerable: true,
      configurable: true,
      get: function() {
        var result;
        result = getter();
        Object.defineProperty(object, property, {
          enumerable: true,
          value: result
        });
        return result;
      }
    });
  };
  STACK_PATH_EXTRACTOR = /\((.+)\:\d+\:\d+\)/;
  getCallingDirectoryFromStack = function(offset) {
    var match, stackLines;
    if (offset == null) {
      offset = 1;
    }
    stackLines = new Error().stack.split("\n");
    match = STACK_PATH_EXTRACTOR(stackLines[offset + 2]);
    return (match && path.dirname(match[1])) || process.cwd();
  };
  conventions = {};
  _ref = fs.readdirSync(path.join(__dirname, 'conventions'));
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    file = _ref[_i];
    if (file !== '.') {
      convention = path.basename(file, path.extname(file));
      (function(convention) {
        var conventionName;
        conventionName = convention.split(/[-_]+/).map(function(val) {
          return val[0].toLocaleUpperCase() + val.slice(1);
        }).join('');
        conventionName = conventionName[0].toLocaleUpperCase() + conventionName.slice(1);
        return lazyLoad(conventions, conventionName, function() {
          return require("./conventions/" + convention);
        });
      })(convention);
    }
  }
  module.exports = autorequire;
  autorequire.conventions = conventions;
}).call(this);
