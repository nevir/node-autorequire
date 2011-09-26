(function() {
  var Default;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Default = (function() {
    function Default() {}
    Default.prototype.directoryToProperty = function(directoryName, parentPath) {
      return this.camelCase(directoryName);
    };
    Default.prototype.fileToProperty = function(fileName, parentPath) {
      return this.camelCase(this.stripFileExtension(fileName));
    };
    Default.prototype.modifySandbox = function(sandbox, module) {
      module._globalLazyLoads = this.globalLazyLoads(module);
      module._require = sandbox.require;
      return sandbox;
    };
    Default.prototype.modifySource = function(source, module) {
      return "for (var key in module._globalLazyLoads) {\n  try {\n    Object.defineProperty(global, key, {\n      enumerable: false, configurable: true, get: module._globalLazyLoads[key]\n    });\n  } catch (err) {}\n}\ndelete module._globalLazyLoads;" + source;
    };
    Default.prototype.modifyExports = function(exports, module) {
      return exports;
    };
    Default.prototype.globalModules = ['assert', 'buffer', 'child_process', 'constants', 'crypto', 'dgram', 'dns', 'events', 'freelist', 'fs', 'http', 'https', 'net', 'os', 'path', 'querystring', 'readline', 'repl', 'stream', 'string_decoder', 'sys', 'timers', 'tls', 'tty', 'url', 'util', 'vm'];
    Default.prototype.extraGlobalModules = [];
    Default.prototype.globalLazyLoads = function(module) {
      var result;
      result = {};
      this.appendGlobalModules(result, module);
      this.appendSameLevelModules(result, module);
      this.appendParentModules(result, module);
      return result;
    };
    Default.prototype.appendGlobalModules = function(lazyLoads, module) {
      var mod, _i, _len, _ref, _results;
      _ref = this.globalModules.concat(this.extraGlobalModules);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        mod = _ref[_i];
        _results.push(__bind(function(mod) {
          return lazyLoads[this.directoryToProperty(mod)] = function() {
            return module._require(mod);
          };
        }, this)(mod));
      }
      return _results;
    };
    Default.prototype.appendSameLevelModules = function(lazyLoads, module) {
      var key, _results;
      _results = [];
      for (key in module.autorequireParent) {
        _results.push(key !== module.id ? (function(key) {
          return lazyLoads[key] = function() {
            return module.autorequireParent[key];
          };
        })(key) : void 0);
      }
      return _results;
    };
    Default.prototype.appendParentModules = function(lazyLoads, module) {};
    Default.prototype.stripFileExtension = function(fileName) {
      return /(.+?)(\.[^.]*$|$)/(fileName)[1];
    };
    Default.prototype.camelCaps = function(pathComponent) {
      return pathComponent.split(/[-_]+/).map(function(val) {
        return val[0].toLocaleUpperCase() + val.slice(1);
      }).join('');
    };
    Default.prototype.camelCase = function(pathComponent) {
      var result;
      result = this.camelCaps(pathComponent);
      return result[0].toLocaleLowerCase() + result.slice(1);
    };
    Default.prototype.underscore = function(pathComponent) {
      return pathComponent.split(/[-_]+/).join('_');
    };
    return Default;
  })();
  module.exports = Default;
}).call(this);
