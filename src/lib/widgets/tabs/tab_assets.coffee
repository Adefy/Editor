define [
  "util/id"
  "widgets/tabs/tab"
  "templates/asset_directory"
  "templates/asset_file"
], (ID, Tab, AssetDirectoryTemplate, AssetFileTemplate) ->

  class TabAssets extends Tab

    constructor: (parent) ->
      super ID.prefId("tab-assets"), parent, ["tab-assets"]

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
            content = @_renderAssets asset.directory.assets

          result.push AssetDirectoryTemplate
            directoryStateIcon: directoryStateIcon
            directory: asset.directory
            content: content
        else
          result.push AssetFileTemplate file: asset.file

      result.join ""

    ###
    # @return [String]
    ###
    render: ->
      @_renderAssets @_assets
