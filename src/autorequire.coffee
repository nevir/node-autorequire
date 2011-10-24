fs   = require 'fs'
path = require 'path'

utils  = require './utils'
Loader = require './loader'
ModuleGroupFactory = require './module_group_factory'

# ## autorequire()
#
# Set up an autorequired module at the specified path.  The path must be a relative or absolute file
# system path.  autorequire does not honor require's pathing.
autorequire = (requirePath, conventionAndOrOptions...) ->
  raise TypeError, 'autorequire only supports ./relative paths for now.' unless requirePath[0] == '.'

  workingDir = utils.getCallingDirectoryFromStack()
  rootPath   = path.normalize workingDir + '/' + requirePath

  options = conventionAndOrOptions.pop() if typeof conventionAndOrOptions[conventionAndOrOptions.length - 1] == 'object'

  # If you do not pass a convention, autorequire will default to
  # [`conventions.Default`](conventions/default.html).
  convention = conventionAndOrOptions.shift() or 'Default'

  # Conventions that are bundled with the autorequire package can be specified by string; they are
  # loaded by looking up the class by the same name underneath `autorequire.conventions`.
  if typeof convention == 'string'
    throw new TypeError "There is no built-in '#{convention}' convention" unless conventions[convention]
    conventionPrototype = conventions[convention]

  # Otherwise, you can specify a convention by passing its constructor
  if typeof convention == 'function'
    conventionPrototype = convention

  # If you pass an options hash, a custom convention will be built by inheriting the convention you
  # specified (or the Default convention), setting each propery in the hash to the new convention's
  # prototype.
  #
  # For a full reference of the methods available to a convention, take a look at
  # [`conventions.Default`](conventions/default.html).
  if options
    class CustomConvention extends conventionPrototype
    for own key, value of options
      CustomConvention::[key] = value

    conventionPrototype = CustomConvention

  unless conventionPrototype?
    throw new TypeError 'autorequire was unable to determine a valid convention, please check your arguments.'

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
        utils.lazyLoad result, convention.directoryToProperty(pathComponent, basePath), ->
          walkDirectory fullPath, convention

      # Files are considered to be components, they're rquired upon lazy-load.
      else if pathStats.isFile()
        componentName = convention.fileToProperty(pathComponent, basePath)
        utils.lazyLoad result, componentName, ->
          Loader.loadModule componentName, fullPath, result, convention

  result

# Set up all our conventions to be lazy-loaded so that they can be inherited from with minimal
# performance hit.
conventions = {}
for file in fs.readdirSync path.join(__dirname, 'conventions') when file != '.'
  convention = path.basename(file, path.extname(file))
  do (convention) ->
    # conventions are prototypes, so CamelCaps it is.
    conventionName = convention.split(/[-_]+/).map((val) -> val[0].toLocaleUpperCase() + val[1..]).join ''
    conventionName = conventionName[0].toLocaleUpperCase() + conventionName[1..]

    utils.lazyLoad conventions, conventionName, ->
      require "./conventions/#{convention}"

module.exports = autorequire
autorequire.conventions = conventions
autorequire.ModuleGroupFactory = ModuleGroupFactory
