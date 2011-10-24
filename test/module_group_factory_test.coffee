test = require './common'


commonGroupVows =
  'should not expose introspective properties as enumerable properties': (moduleGroup) ->
    properties = [k for k,v of moduleGroup]

    test.assert.exclude properties, '__path__'
    test.assert.exclude properties, '__name__'

test.vows.describe('ModuleGroupFactory').addBatch
  'module groups':
    topic: ->
      convention = new test.autorequire.conventions.Default
      groupPath  = test.path.resolve './test/examples/mixed_tastes/lib'

      test.autorequire.ModuleGroupFactory.buildModuleGroup convention, groupPath

    '(root level)':
      topic: (moduleGroup) -> moduleGroup

      'common behavior': commonGroupVows

      "should allow introspection of the module group's path": (moduleGroup) ->
        test.assert.equal moduleGroup.__path__, test.path.resolve './test/examples/mixed_tastes/lib'

      'should have a name of __root__': (moduleGroup) ->
        test.assert.equal moduleGroup.__name__, '__root__'

      'should not have a __parent__': (moduleGroup) ->
        test.assert.equal moduleGroup.__parent__, null

      'should expose child directories/files as enumerable properties on the module group': (moduleGroup) ->
        test.assert.keysEqual moduleGroup, ['imbibables', 'legumes', 'meatyGoodness']

    '(sub-groups)':
      topic: (moduleGroup) -> moduleGroup.imbibables

      'common behavior': commonGroupVows

      "should allow introspection of the module group's path": (moduleGroup) ->
        test.assert.equal moduleGroup.__path__, test.path.resolve './test/examples/mixed_tastes/lib/imbibables'

      'should have their name appended to that of the parent group': (moduleGroup) ->
        test.assert.equal moduleGroup.__name__, '__root__.imbibables'

      'should expose their parent module group via __parent__': (moduleGroup) ->
        test.assert.isObject moduleGroup.__parent__
        test.assert.equal    moduleGroup.__parent__.__name__, '__root__'
        test.assert.equal    moduleGroup.__parent__.__path__, test.path.resolve './test/examples/mixed_tastes/lib'

      'should expose child directories/files as enumerable properties on the module group': (moduleGroup) ->
        test.assert.keysEqual moduleGroup, ['coffee', 'highlyDistilledCactusJuice', 'tea']

.export(module)
