fs   = require 'fs'
path = require 'path'

Loader = require './loader'


# ## autorequire()
# Set up an autorequired module at the specified path.  The path must be a relative or absolute
# file system path.  autorequire does not honor require's pathing.
#
# Conventions that are bundled with the autorequire package can be specified by string; they are
# loaded by looking up the class by the same name underneath 'autorequire.conventions'.
#
# Otherwise, you can specify a convention by passing its constructor - or, you can pass an options
# hash with instance methods to be overridden.  For a full reference of the methods available to a
# convention, take a look at [conventions.default](conventions/default.html).
autorequire = (requirePath, convention='default') ->
  raise TypeError, "autorequire only supports ./relative paths for now." unless requirePath[0] == '.'

  workingDir = getCallingDirectoryFromStack()
  rootPath   = path.normalize workingDir + '/' + requirePath

  conventionPrototype = switch typeof convention
    when 'function' then convention

    when 'string'
      throw new TypeError "There is no built-in '#{}' convention" unless conventions[convention]
      conventions[convention]

    when 'object'
      class CustomConvention
        this:: = convention

    else
      raise TypeError, "autorequire doesn't know how to handle a convention of #{convention}"

  walkDirectory rootPath, new conventionPrototype

# ## Internal Helpers

# Iterate a path, and populate it with autorequire'ing components/properties.
#
# Returns the object describing that path and its sub-hierarchy.
walkDirectory = (basePath, convention) ->
  result = {}

  for pathComponent in fs.readdirSync basePath when pathComponent[0] != '.'
    fullPath = path.join(basePath, pathComponent)
    pathStats = fs.statSync(fullPath)

    do (fullPath) ->
      # Directories recurse (upon lazy-load).
      if pathStats.isDirectory()
        lazyLoad result, convention.directoryToProperty(pathComponent, basePath), ->
          walkDirectory fullPath, convention

      # Files are considered to be components, they're rquired upon lazy-load.
      else if pathStats.isFile()
        componentName = convention.fileToProperty(pathComponent, basePath)
        lazyLoad result, componentName, ->
          Loader.loadModule componentName, fullPath, result, convention

  result

# Helper to define lazy-loading properties on an object that fill themselves in after the first
# call.
lazyLoad = (object, property, getter) ->
  Object.defineProperty object, property,
    enumerable: true
    configurable: true # We need to be able to write over it
    get: ->
      result = getter()
      # Overwrite the property now that it's loaded
      Object.defineProperty object, property, enumerable: true, value: result

      result

STACK_PATH_EXTRACTOR = /\((.+)\:\d+\:\d+\)/

# Helper to allow autorequire calls to support the same kind of relative pathing that require does.
#
# There has to be a better way of doing this than parsing a stack trace, though.  The offset
# indicates how many calls we should go back in the stack to find a caller.  0 is the function that
# is calling `getCallingDirectoryFromStack`.
#
# Passing __dirname from the caller is something I'd like to avoid in order to provide a more
# consistent interface with require().  Lower cognitive load, and all that.
getCallingDirectoryFromStack = (offset = 1) ->
  stackLines = new Error().stack.split "\n"

  # first line is the exception, second line is this method
  match = STACK_PATH_EXTRACTOR stackLines[offset + 2]

  # Fall back to the current directory if we don't have a valid caller.  They're likely in a REPL.
  (match and path.dirname match[1]) or process.cwd()

# Set up all our conventions to be lazy-loaded so that they can be inherited from with minimal
# performance hit.
conventions = {}
for file in fs.readdirSync path.join(__dirname, 'conventions') when file != '.'
  convention = path.basename(file, path.extname(file))
  do (convention) ->
    lazyLoad conventions, convention, ->
      require "./conventions/#{convention}"

module.exports = autorequire
autorequire.conventions = conventions
