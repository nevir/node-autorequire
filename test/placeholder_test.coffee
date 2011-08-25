vows   = require 'vows'
assert = require 'assert'

autorequire = require '..'

vows.describe('Placeholder').addBatch

  'Until we have actual code':
    topic: -> return true
    'we should not have to test anything': (thing) ->
      assert.equal thing, true

.export(module)

