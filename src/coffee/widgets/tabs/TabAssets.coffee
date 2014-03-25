##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# @depend Tab.coffee
class AWidgetTabAssets extends AWidgetTab

  constructor: (parent) ->
    super prefId("tab-assets"), parent, ["tab-assets"]

    @_assets = []

  ###
  # @return [String]
  ###
  cssAppendParentClass: ->
    "files"

  ###
  # @param [Array<Object>] assets
  # @private
  ###
  _renderAssets: (assets) ->
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

  ###
  # @return [String]
  ###
  render: ->
    @_renderAssets @_assets