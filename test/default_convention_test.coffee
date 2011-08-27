test = require './common'


subModulesShouldMatch = (opts) ->
  topic: opts.topic

  'we should be given an object with a camelCase key per submodule': (package) ->
    test.assert.keysEqual package, opts.keys

  'each exported property should match the exports of each submodule': (package) ->
    test.assert.valuesEqual package, ({DAS_MODULE: m} for m in opts.bases)


test.vows.describe('Default Convention').addBatch

  'when we autorequire the example package "fuzzy"': subModulesShouldMatch
    topic: -> test.autorequire('./examples/fuzzy')
    keys:  ['babyThing',  'kitten', 'puppy', 'squidlet']
    bases: ['baby-thing', 'kitten', 'puppy', 'squidlet']

  'when we require the example autorequired package "mixed_tastes"':
    topic: -> require('./examples/mixed_tastes')

    'we should be given an object with a camelCase key per namespace': (package) ->
      test.assert.keysEqual package, ['imbibables', 'meatyGoodness']

    'and we traverse into the "imbibables" namespace': subModulesShouldMatch
      topic: (package) -> package.imbibables
      keys:  ['coffee', 'highlyDistilledCactusJuice',   'tea']
      bases: ['coffee', 'highly_distilled_cactus_juice', 'tea']

    'and we traverse into the "meatyGoodness" namespace': subModulesShouldMatch
      topic: (package) -> package.meatyGoodness
      keys:  ['bacon', 'bloodSausage']
      bases: ['bacon', 'blood-sausage']

.export(module)
