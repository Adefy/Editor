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

      @_regListeners()

    _onToggleDirectory: (element) ->
      $(element).toggleClass("expanded")

      icon = $(element).find(".toggle-directory i")

      if $(element).hasClass("expanded")
        icon.removeClass("fa-caret-right")
        icon.addClass("fa-caret-down")
      else
        icon.removeClass("fa-caret-down")
        icon.addClass("fa-caret-right")

    ###
    # @private
    ###
    _regListeners: ->

      $(document).on "click", ".files .toggle-directory", (e) =>
        @_onToggleDirectory $(e.target).closest(".asset-directory")

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
        content = @_renderAssets asset.directory.assets

        if asset.directory.unfolded
          directoryStateIcon = "fa-caret-down"

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
