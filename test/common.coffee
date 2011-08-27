module.exports =
  vows:   require 'vows'
  assert: require 'assert'

  autorequire: require '..'

# We're not afraid to mangle the assert package!  We're in tests after all.
module.exports.assert.keysEqual = (obj, keys) ->
  @deepEqual (k for k of obj), keys

module.exports.assert.valuesEqual = (obj, values) ->
  @deepEqual (v for k,v of obj), values
