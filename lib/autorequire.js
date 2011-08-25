(function() {
  var Loader, autorequire, convention, conventions, file, fs, lazyLoad, path, walkDirectory, _i, _len, _ref;
  fs = require('fs');
  path = require('path');
  Loader = require('./loader');
  autorequire = function(requirePath, convention) {
    var CustomConvention, conventionPrototype;
    if (convention == null) {
      convention = 'default';
    }
    conventionPrototype = (function() {
      switch (typeof convention) {
        case 'function':
          return convention;
        case 'string':
          if (!conventions[convention]) {
            throw new TypeError("There is no built-in '" + "' convention");
          }
          return conventions[convention];
        case 'object':
          return CustomConvention = (function() {
            function CustomConvention() {}
            CustomConvention.prototype = convention;
            return CustomConvention;
          })();
        default:
          return raise(Error, "autorequire doesn't know how to handle a convention of " + convention);
      }
    }).call(this);
    return walkDirectory(requirePath, new conventionPrototype);
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
  conventions = {};
  _ref = fs.readdirSync(path.join(__dirname, 'conventions'));
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    file = _ref[_i];
    if (file !== '.') {
      convention = path.basename(file, path.extname(file));
      (function(convention) {
        return lazyLoad(conventions, convention, function() {
          return require("./conventions/" + convention);
        });
      })(convention);
    }
  }
  module.exports = autorequire;
  autorequire.conventions = conventions;
}).call(this);
