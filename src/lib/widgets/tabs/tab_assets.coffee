define (require) ->

  ID = require "util/id"
  Tab = require "widgets/tabs/tab"
  Asset = require "handles/asset"
  Modal = require "widgets/modal"
  TemplateAssetDirectory = require "templates/asset_directory"
  TemplateAssetFile = require "templates/asset_file"
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

      @_regListeners()

    ###
    # Callback for directory visiblity content toggle
    # @param [HTMLElement] element
    ###
    _onToggleDirectory: (element) ->
      assetElementId = element[0].id
      asset = @ui.workspace.project.assets.findById(assetElementId)
      if asset
        asset.setExpanded !asset.getExpanded()
        @refreshAssetState asset
      else
        throw new Error "could not find asset(id: #{assetElementId})"

      @_parent.onChildUpdate(@) if @_parent.onChildUpdate

    ###
    # @private
    ###
    _bindContextClick: ->
      $(document).on "contextmenu", ".files .asset", (e) =>
        assetElement = $(e.target).closest(".asset")
        if asset = @ui.workspace.project.assets.findById(assetElement[0].id)
          new ContextMenu e.pageX, e.pageY, asset
        e.preventDefault()
        false

      $(document).on "contextmenu", ".files", (e) =>
        new ContextMenu e.pageX, e.pageY, @ui.workspace.project.assets
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
        return TemplateAssetFile file: asset unless org_asset.isDirectory()

        content = @_renderAssets org_asset.getEntries()

        expanded = ""
        directoryStateIcon = "fa-caret-right"

        if org_asset.getExpanded()
          expanded = "expanded"
          directoryStateIcon = "fa-caret-down"

        TemplateAssetDirectory
          directoryStateIcon: directoryStateIcon
          expanded: expanded
          directory: asset
          content: content

      .join ""

    ###
    # @return [String]
    ###
    render: ->
      @_renderAssets @ui.workspace.project.assets.getEntries()

    ###
    # @param [Asset] asset
    ###
    refreshAssetState: (asset) ->
      elementId = asset.getSelector()

      expanded = asset.getExpanded()

      $("#{elementId}.asset").toggleClass("expanded", expanded)

      icon = $("#{elementId}.asset > .toggle-directory i")
      icon.toggleClass("fa-caret-right", !expanded)
      icon.toggleClass("fa-caret-down",  expanded)

    ###
    # @param [Asset] asset
    ###
    refreshAsset: (asset) ->
      elementId = asset.getSelector()
      $("#{elementId}.asset > dd > label.name").text asset.getName()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      switch type
        when "update.asset", "renamed.asset"
          @refreshAsset params.asset
        when "add.asset"
          @refresh()
        when "remove.asset"
          @refresh()