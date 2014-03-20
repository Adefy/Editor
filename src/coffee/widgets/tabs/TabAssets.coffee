# @depend Tab.coffee
class AWidgetTabAssets extends AWidgetTab

  constructor: (parent) ->
    @_assets = []
    super parent

  cssKlass: ->
    "files"

  renderAssets: (assets) ->
    result = []
    for asset in assets
      if asset.directory
        directoryStateIcon = "fa-caret-right"
        content = ""
        if asset.directory.unfolded
          directoryStateIcon = "fa-caret-down"
          content = @renderAssets asset.directory.assets

        result.push ATemplate.assetDirectory
          directoryStateIcon: directoryStateIcon
          directory: asset.directory
          content: content
      else
        result.push ATemplate.assetFile file: asset.file

    result.join ""

  render: ->
    @renderAssets @_assets