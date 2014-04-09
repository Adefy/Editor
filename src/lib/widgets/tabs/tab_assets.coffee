define (require) ->

  ID = require "util/id"
  Tab = require "widgets/tabs/tab"
  Asset = require "handles/asset"
  AssetDirectoryTemplate = require "templates/asset_directory"
  AssetFileTemplate = require "templates/asset_file"
  ContextMenu = require "widgets/context_menu"

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
        new Asset
          isDirectory: true,
          name: "I'm a directory"
          entries: [
            new Asset
              name: "A"
          ,
            new Asset
              name: "B"
          ]
      ,
        new Asset name: "A"
      ,
        new Asset name: "B"
      ,
        new Asset name: "C"
      ,
        new Asset name: "D"
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

      @_parent.onChildUpdate(@) if @_parent.onChildUpdate

    ###
    # @private
    ###
    _bindContextClick: ->
      $(document).on "contextmenu", ".files .asset", (e) =>
        console.log e

        new ContextMenu e.pageX, e.pageY, $(e.target).closest(".asset")
        e.preventDefault()
        false

    ###
    # @private
    ###
    _regListeners: ->

      @_bindContextClick()

      $(document).on "click", ".files .toggle-directory", (e) =>
        @_onToggleDirectory $(e.target).closest(".asset.directory")

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
      assets.map (org_asset) =>
        asset = org_asset.toRenderParams()
        return AssetFileTemplate file: asset unless org_asset.isDirectory()

        directoryStateIcon = "fa-caret-right"
        content = @_renderAssets org_asset.getEntries()

        AssetDirectoryTemplate
          directoryStateIcon: directoryStateIcon
          directory: asset
          content: content

      .join ""

    ###
    # @return [String]
    ###
    render: ->
      @_renderAssets @_assets
