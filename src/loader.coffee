assert = require 'assert'
fs     = require 'fs'
path   = require 'path'
vm     = require 'vm'
Module = require 'module'


# Loader injects extra behavior into the standard module loader to honor the current convention.
class Loader extends Module
  constructor: (componentName, autorequireParent, convention) ->
    super componentName

    @convention        = convention
    @autorequireParent = autorequireParent

  # Load a module and return its exports, adhering to the given convention.
  @loadModule: (componentName, modulePath, autorequireParent, convention) ->
    loader = new this(componentName, autorequireParent, convention)
    loader.load(modulePath)

    loader.exports

  # Unfortunately, Node's Module prototype doesn't break _compile into meaningful chunks, so we're
  # stuck re-implementing parts of it.
  #
  # Note, however, that we put our foot down and **only** support sandboxed module evaluation.
  # This allows us to mess with a module's global context with out messing up global for everyone
  # else.
  _compile: (content, filename) ->
    throw new Error 'Compiling a root module is not supported by autorequire.' if @id == '.'

    content = @_cleanContent content
    sandbox = @_buildSandbox filename

    sandbox = @convention.modifySandbox sandbox, this if @convention.modifySandbox
    content = @convention.modifySource  content, this if @convention.modifySource

    vm.runInContext content, sandbox, filename, true

    @sandbox = sandbox
    @exports = @convention.modifyExports @exports, this if @convention.modifyExports

  # ## Compatibility Helpers

  # Performs sanitization on content to mirror the default behavior.  Just tweaks the shebang atm.
  #
  # This mirrors v0.4.11.
  _cleanContent: (content) ->
    content.replace /^\#\!.*/, ''

  # Builds the default sandbox for a module, mirroring default behavior
  #
  # This mirrors v0.4.11.
  _buildSandbox: (filename) ->
    sandbox = vm.createContext {}
    for k, v of global
      sandbox[k] = v

    sandbox.require    = @_buildRequire()
    sandbox.exports    = @exports
    sandbox.__filename = filename
    sandbox.__dirname  = path.dirname filename
    sandbox.module     = this
    sandbox.global     = sandbox
    sandbox.root       = root

    sandbox

  # Builds the require() function for this module, and any properties on to duplicate the default
  # Node behavior.
  #
  # This mirrors v0.4.11.
  _buildRequire: ->
    self    = this
    require = (path) -> Module._load path, self

    require.resolve = (request) -> Module._resolveFilename(request, self)[1]
    require.paths   = Module._paths
    require.main    = process.mainModule

    require.extensions = Module._extensions
    require.registerExtension = ->
      throw new Error 'require.registerExtension() removed. Use require.extensions instead.'

    require.cache = Module._cache

    require

  # Overrides the built in load so that we can perform extension-specific behavior.
  #
  # It will not override an extension that isn't already registered with require.extensions.
  #
  # This mirrors v0.4.11.
  load: (filename) ->
    assert.ok not @loaded

    @filename = filename
    @paths    = Module._nodeModulePaths path.dirname filename

    extension = path.extname filename
    extension = '.js' if not Module._extensions[extension]

    (@_extensions[extension] || Module._extensions[extension])(this, filename)

    @loaded = true

  # ## Extension Specific Helpers

  _extensions:
    # We want to load coffeescript sources without the wrapper - we're already evaluating them within
    # a context, so they won't leak into the global context.  This lets conventions pull defined
    # properties out of the context w/o having to resort to module.exports.
    #
    # This mirrors coffee-script v1.1.2.
    '.coffee': (module, filename) ->
      content = require('coffee-script').compile fs.readFileSync(filename, 'utf8'),
        filename: filename, bare: true
      module._compile content, filename

module.exports = Loader
