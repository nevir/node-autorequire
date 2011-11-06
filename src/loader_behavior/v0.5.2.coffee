path   = require 'path'
Module = require 'module'
vm     = require 'vm'

# Behavioral functions that mirror parts of the official Module.prototype._compile function.
#
# This adheres to Node v0.5.2 - v0.6.0
module.exports =
  # Performs sanitization on content to mirror the default behavior.  Just tweaks the shebang atm.
  _cleanContent: (content) ->
    content.replace /^\#\!.*/, ''

  # Builds the require() function for this module, and any properties on to duplicate the default
  # Node behavior.
  _buildRequire: ->
    self    = this
    require = (path) => @require path

    require.resolve = (request) -> Module._resolveFilename(request, self)[1]

    Object.defineProperty require, 'paths', get: ->
      throw new Error 'require.paths is removed. Use node_modules folders, or the NODE_PATH environment variable instead.'

    require.main = process.mainModule

    require.extensions = Module._extensions
    require.registerExtension = ->
      throw new Error 'require.registerExtension() removed. Use require.extensions instead.'

    require.cache = Module._cache

    require

  # Builds the default sandbox for a module, mirroring default behavior
  _buildSandbox: (filename) ->
    sandbox = vm.createContext {}
    for k, v of global
      sandbox[k] = v

    sandbox.require    = @_buildRequire()
    sandbox.exports    = @exports
    sandbox.__filename = filename
    sandbox.__dirname  = path.dirname filename
    sandbox.module     = @
    sandbox.global     = sandbox
    sandbox.root       = root

    sandbox
