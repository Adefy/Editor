define (require) ->

  ID = require "util/id"
  Tab = require "widgets/tabs/tab"
  AssetDirectoryTemplate = require "templates/asset_directory"
  AssetFileTemplate = require "templates/asset_file"

  class AssetsTab extends Tab

    ###
    # @param [UIManager] ui
    # @param [SidebarPanel] parent
    ###
    constructor: (@ui, parent) ->
      super
        id: ID.prefId("tab-assets")
        parent: parent
        classes: ["tab-assets"]

      @_assets = [
        directory:
          name: "I'm a directory"
          assets: [
            file:
              name: "A"
          ,
            file:
              name: "B"
          ]
      ,
        file:
          name: "A"
      ,
        file:
          name: "B"
      ,
        file:
          name: "C"
      ,
        file:
          name: "D"
      ]

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
      assets.map (asset) =>
        return AssetFileTemplate file: asset.file unless asset.directory

        directoryStateIcon = "fa-caret-right"
        content = ""

        if asset.directory.unfolded
          directoryStateIcon = "fa-caret-down"
          content = @_renderAssets asset.directory.assets

        AssetDirectoryTemplate
          directoryStateIcon: directoryStateIcon
          directory: asset.directory
          content: content

      .join ""

    ###
    # @return [String]
    ###
    render: ->
      @_renderAssets @_assets
