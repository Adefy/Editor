define (require) ->

  ID = require "util/id"
  Tab = require "widgets/tabs/tab"
  Asset = require "handles/asset"
  Modal = require "widgets/modal"
  TemplateAssetDirectory = require "templates/asset_directory"
  TemplateAssetFile = require "templates/asset_file"
  TemplateModalRename = require "templates/modal/rename"
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

      @_assets = []
      ###
      [
        new Asset @,
          isDirectory: true,
          name: "I'm a directory"
          entries: [
            new Asset @, name: "A"
          ,
            new Asset @, name: "B"
          ]
      ,
        new Asset @, name: "A"
      ,
        new Asset @, name: "B"
      ,
        new Asset @, name: "C"
      ,
        new Asset @, name: "D"
      ]
      ###

      @_regListeners()

    ###
    # And an asset to the assets list
    # @param [Asset] asset
    ###
    pushEntry: (asset) ->
      asset._parent = null
      @_assets.push asset

    ###
    # @param [Array<Asset>] assets
    # @param [Id] id
    ###
    _searchAssetsById: (assets, id) ->
      for asset in assets
        return asset if asset.getId() == id
        if asset.isDirectory()
          if found = @_searchAssetsById(asset.getEntries(), id)
            return found

      return null

    ###
    # @param [Id] id
    ###
    findAssetById: (id) ->
      @_searchAssetsById @_assets, id

    ###
    # Callback for directory visiblity content toggle
    # @param [HTMLElement] element
    ###
    _onToggleDirectory: (element) ->
      assetElementId = element[0].id
      asset = @findAssetById(assetElementId)
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
        if asset = @findAssetById(assetElement[0].id)
          new ContextMenu e.pageX, e.pageY, asset
        e.preventDefault()
        false

      $(document).on "contextmenu", ".files", (e) =>
        new ContextMenu e.pageX, e.pageY, @
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
      @_renderAssets @_assets

    ###
    # @param [Asset] asset
    ###
    refreshAssetState: (asset) ->
      elementId = asset.getSelector()

      expanded = asset.getExpanded()

      $(elementId).toggleClass("expanded", expanded)

      icon = $(elementId).find(".toggle-directory i")
      icon.toggleClass("fa-caret-right", !expanded)
      icon.toggleClass("fa-caret-down",  expanded)

    ###
    # @param [Asset] asset
    ###
    refreshAsset: (asset) ->
      elementId = asset.getSelector()
      $(elementId).find(".name").html asset.getName()

    ###
    # @return [Modal]
    ###
    showModalRename: (asset) ->
      nameId = ID.prefId "fileName"

      _html = TemplateModalRename
        nameId: nameId
        name: asset.getName()

      new Modal
        title: "Rename",
        mini: true,
        content: _html,
        modal: false,
        cb: (data) =>
          # Submission
          name = data[nameId]
          asset.setName name
          @refreshAsset asset

        validation: (data) =>
          # Validation
          name = data[nameId]
          unless name.length > 0 then return "Name must be longer than 0"
          true

        change: (deltaName, deltaVal, data) =>
          #$("input[name=\"#{nameId}\"]").val deltaVal

    ###
    # @return [Object]
    ###
    getContextFunctions: ->
      {
        "Add Directory": => @contextFuncAddDirectory @, "New Folder"
        "Add File": => @contextFuncAddFile @, "New File"
      }

    ###
    # ContextMenu functions
    #
    # Add Directory
    # @param [Asset] asset
    # @param [String] name
    ###
    contextFuncAddDirectory: (asset, name) ->
      asset.pushEntry new Asset(@, name: name, isDirectory: true)
      @refresh()
      @

    ###
    # Add File
    #
    # @param [Asset] asset
    # @param [String] name
    ###
    contextFuncAddFile: (asset, name) ->
      asset.pushEntry new Asset(@, name: name)
      @refresh()
      @

    ###
    # Remove
    #
    # @param [Asset] asset
    ###
    contextFuncRemoveAsset: (asset) ->
      if parent = asset._parent
        parent.removeEntry asset
      else
        @_assets = _.without @_assets, asset

      @refresh()
      @

    ###
    # Rename
    # @param [Asset] asset
    ###
    contextFuncRenameAsset: (asset) ->
      # TODO
      @showModalRename asset
      @