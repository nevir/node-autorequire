test = require './common'


test.vows.describe('autorequire API').addBatch
  'conventions':
    topic: -> test.autorequire.conventions

    'should be exposed as classes following the CamelCaps scheme': (conventions) ->
      test.assert.keysEqual conventions, ['Classical', 'Default', 'Ruby']

.export(module)
