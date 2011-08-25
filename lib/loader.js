(function() {
  var Loader, Module, assert, fs, path, vm;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  assert = require('assert');
  fs = require('fs');
  path = require('path');
  vm = require('vm');
  Module = require('module');
  Loader = (function() {
    __extends(Loader, Module);
    function Loader(componentName, autorequireParent, convention) {
      Loader.__super__.constructor.call(this, componentName);
      this.convention = convention;
      this.autorequireParent = autorequireParent;
    }
    Loader.loadModule = function(componentName, modulePath, autorequireParent, convention) {
      var loader;
      loader = new this(componentName, autorequireParent, convention);
      loader.load(modulePath);
      return loader.exports;
    };
    Loader.prototype._compile = function(content, filename) {
      var sandbox;
      if (this.id === '.') {
        throw new Error('Compiling a root module is not supported by autorequire.');
      }
      content = this._cleanContent(content);
      sandbox = this._buildSandbox(filename);
      if (this.convention.modifySandbox) {
        sandbox = this.convention.modifySandbox(sandbox, this);
      }
      if (this.convention.modifySource) {
        content = this.convention.modifySource(content, this);
      }
      vm.runInContext(content, sandbox, filename, true);
      this.sandbox = sandbox;
      if (this.convention.modifyExports) {
        return this.exports = this.convention.modifyExports(this.exports, this);
      }
    };
    Loader.prototype._cleanContent = function(content) {
      return content.replace(/^\#\!.*/, '');
    };
    Loader.prototype._buildSandbox = function(filename) {
      var k, sandbox, v;
      sandbox = vm.createContext({});
      for (k in global) {
        v = global[k];
        sandbox[k] = v;
      }
      sandbox.require = this._buildRequire();
      sandbox.exports = this.exports;
      sandbox.__filename = filename;
      sandbox.__dirname = path.dirname(filename);
      sandbox.module = this;
      sandbox.global = sandbox;
      sandbox.root = root;
      return sandbox;
    };
    Loader.prototype._buildRequire = function() {
      var require, self;
      self = this;
      require = function(path) {
        return Module._load(path, self);
      };
      require.resolve = function(request) {
        return Module._resolveFilename(request, self)[1];
      };
      require.paths = Module._paths;
      require.main = process.mainModule;
      require.extensions = Module._extensions;
      require.registerExtension = function() {
        throw new Error('require.registerExtension() removed. Use require.extensions instead.');
      };
      require.cache = Module._cache;
      return require;
    };
    Loader.prototype.load = function(filename) {
      var extension;
      assert.ok(!this.loaded);
      this.filename = filename;
      this.paths = Module._nodeModulePaths(path.dirname(filename));
      extension = path.extname(filename);
      if (!Module._extensions[extension]) {
        extension = '.js';
      }
      (this._extensions[extension] || Module._extensions[extension])(this, filename);
      return this.loaded = true;
    };
    Loader.prototype._extensions = {
      '.coffee': function(module, filename) {
        var content;
        content = require('coffee-script').compile(fs.readFileSync(filename, 'utf8'), {
          filename: filename,
          bare: true
        });
        return module._compile(content, filename);
      }
    };
    return Loader;
  })();
  module.exports = Loader;
}).call(this);
