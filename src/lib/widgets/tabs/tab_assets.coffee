define (require) ->

  ID = require "util/id"
  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"

  Tab = require "widgets/tabs/tab"
  Asset = require "handles/asset"
  TemplateAssetDirectory = require "templates/tabs/asset_directory"
  TemplateAssetFile = require "templates/tabs/asset_file"
  ContextMenu = require "widgets/context_menu"

  class AssetsTab extends Tab

    ###
    # @param [UIManager] ui
    # @param [SidebarPanel] parent
    ###
    constructor: (@ui, parent) ->
      super
        id: ID.prefID("tab-assets")
        parent: parent
        classes: ["tab-assets"]

      @_regListeners()

    ###
    # @return [String]
    ###
    cssAppendParentClass: ->
      "files"

    ###
    # Callback for directory visiblity content toggle
    # @param [HTMLElement] element
    ###
    _onToggleDirectory: (element) ->
      assetElementId = element[0].id
      asset = @ui.editor.project.assets.findByID(assetElementId)
      if asset
        asset.setExpanded !asset.getExpanded()
        @_updateAssetState asset
      else
        throw new Error "could not find asset(id: #{assetElementId})"

      @_parent.onChildUpdate(@) if @_parent.onChildUpdate

    ###
    # @private
    ###
    _bindContextClick: ->
      $(document).on "contextmenu", ".files .asset", (e) =>
        assetElement = $(e.target).closest(".asset")
        if asset = @ui.editor.project.assets.findByID(assetElement[0].id)
          new ContextMenu e.pageX, e.pageY, asset.getContextProperties()
        e.preventDefault()
        false

      $(document).on "contextmenu", ".files", (e) =>
        new ContextMenu e.pageX, e.pageY, @ui.editor.project.assets.getContextProperties()
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
    # @param [Array<Object>] assets
    # @return [String] html
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
    # @return [String] html
    ###
    render: ->
      @_renderAssets @ui.editor.project.assets.getEntries()

    ###
    # @param [Asset] asset
    ###
    _updateAssetState: (asset) ->
      elementId = asset.getSelector()

      expanded = asset.getExpanded()

      $("#{elementId}.asset").toggleClass("expanded", expanded)

      icon = $("#{elementId}.asset > .toggle-directory i")
      icon.toggleClass("fa-caret-right", !expanded)
      icon.toggleClass("fa-caret-down",  expanded)

    ###
    # @param [Asset] asset
    ###
    _updateAsset: (asset) ->
      elementId = asset.getSelector()
      $("#{elementId}.asset > dd > label.name").text asset.getName()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      AUtilEventLog.egot "tab.assets", type
      switch type
        when "update.asset", "renamed.asset"
          @updateAsset params.asset
        when "add.asset"
          @refresh()
        when "remove.asset"
          @refresh()
