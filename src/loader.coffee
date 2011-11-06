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

  # Overrides the built in load so that we can perform extension-specific behavior.
  #
  # It will not override an extension that isn't already registered with require.extensions.
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

version = (parseInt(v) for v in process.version.match(/v(\d+)\.(\d+)\.(\d+)/)[1..3])

# Include behavior appropriate for the current version of node
behavior =
  if      version[1] == 6                     then require './loader_behavior/v0.5.2'
  else if version[1] == 5 and version[2] >= 2 then require './loader_behavior/v0.5.2'
  else if version[1] == 5 and version[2] == 1 then require './loader_behavior/v0.5.1'
  else if version[1] == 5 and version[2] == 0 then require './loader_behavior/v0.4.0'
  else if version[1] == 4                     then require './loader_behavior/v0.4.0'
  else throw new Error "No autorequire.Loader behavior defined for node #{process.version}"

for k, v of behavior
  Loader::[k] = v

module.exports = Loader
