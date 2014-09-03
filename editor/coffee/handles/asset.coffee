define (require) ->

  param = require "util/param"
  ID = require "util/id"

  EditorObject = require "editor_object"
  Dumpable = require "mixin/dumpable"

  class Asset extends EditorObject

    @include Dumpable

    ###
    # @param [Asset, null] parent
    # @param [Hash] options
    ###
    constructor: (parent, options) ->
      options = param.optional options, {}

      @_parent = parent

      @_id = ID.prefID "asset"

      @_name = param.required options.name
      #@_color = param.optional options.color, [198, 198, 198]

      @_isDirectory = param.optional options.isDirectory, false

      @_disabled = param.optional options.disabled, []

      if @_isDirectory
        @_expanded = param.optional options.expanded, false
        @_entries = param.optional options.entries, []
        for entry in @_entries
          # convert pure objects to Asset
          unless entry instanceof Asset
            oldEntry = entry
            entry = new Asset oldEntry

          entry._parent = @

        @_fileType = "directory"
      else
        @_fileType = param.optional options.fileType, "file"

    ###
    # Ensures that this Asset is a directory
    # @return [Void]
    ###
    _checkIsDirectory: ->
      unless @_isDirectory
        throw new Error "This operation cannot be done on a file"

    ###
    # Ensures that this Asset is a file
    # @return [Void]
    ###
    _checkIsFile: ->
      if @_isDirectory
        throw new Error "This operation cannot be done on a directory"

    ###
    # @param [Id] id
    ###
    findByID: (id) ->
      for asset in @_entries
        return asset if asset.getID() == id
        if asset.isDirectory()
          if found = asset.findByID(id)
            return found

      return null

    ###
    # Pushes new entries into a directory
    # @param [Asset] asset
    ###
    addAsset: (asset) ->
      @_checkIsDirectory()
      asset._parent = @
      @_entries.push asset

    ###
    # Remove the asset from the list
    # @param [Asset] asset
    ###
    removeAsset: (asset) ->
      @_entries = _.without @_entries, asset

    ###
    # Is this Asset a file?
    # @return [Boolean] isFile
    ###
    isFile: -> !@_isDirectory

    ###
    # Is this Asset a directory?
    # @return [Boolean] isDirectory
    ###
    isDirectory: -> @_isDirectory

    ###
    # Get this Asset's id
    # @return [Id] id
    ###
    getID: -> @_id

    ###
    # Get this Asset's selector
    # @return [String] CSSSelector
    ###
    getSelector: -> "##{@_id}"

    ###
    # Get this Asset's full backward selector
    # @return [String] CSSSelector
    ###
    getFullSelector: ->
      if @_parent
        "#{@_parent.getFullSelector()} ##{@_id}"
      else
        "##{@_id}"

    ###
    # Get this Asset's full parent selector
    # @return [String] CSSSelector
    ###
    getFullParentSelector: ->
      if @_parent
        @_parent.getFullSelector()
      else
        null

    ###
    # Returns the Asset's directory entries
    # @return [Array<Asset>] entries
    ###
    getEntries: ->
      @_checkIsDirectory()
      @_entries

    ###
    # Get this Asset's name
    # @return [String] name
    ###
    getName: -> @_name

    ###
    # @param [String] name
    ###
    setName: (name) ->
      @_name = name
      @

    ###
    # @return [String]
    ###
    getFileType: -> @_fileType

    ###
    # @return [String]
    ###
    setFileType: (fileType) ->
      @_checkIsFile()
      @_fileType = fileType
      @

    ###
    # Get the directory expanded state
    # @return [Boolean] expanded
    ###
    getExpanded: ->
      @_expanded

    ###
    # Sets a directory expanded state
    # @param [Boolean] expanded
    ###
    setExpanded: (expanded) ->
      @_checkIsDirectory()
      @_expanded = expanded

    ###
    # ContextMenu functions
    #
    # Add Directory
    # @param [Asset] asset expected to be the parent directory
    # @param [String] name
    ###
    contextFuncAddDirectory: (asset, name) ->
      child = new Asset asset, name: name, isDirectory: true
      asset.addAsset child
      window.AdefyEditor.ui.pushEvent "add.asset", parent: asset, child: child
      @

    ###
    # Add File
    #
    # @param [Asset] asset expected to be the parent directory
    # @param [String] name
    ###
    contextFuncAddFile: (asset, name) ->
      child = new Asset(@, name: name)
      asset.addAsset child
      window.AdefyEditor.ui.pushEvent "add.asset", parent: asset, child: child
      @

    ###
    # Remove
    #
    # @param [Asset] asset
    ###
    contextFuncRemoveAsset: (asset) ->
      if parent = asset._parent
        parent.removeAsset asset

        window.AdefyEditor.ui.pushEvent "remove.asset",
          parent: parent,
          child: asset

      @

    ###
    # Rename
    # @param [Asset] asset
    ###
    contextFuncRenameAsset: (asset) ->
      window.AdefyEditor.ui.modals.showRename asset
      @

    ###
    # @return [Object]
    ###
    getContextProperties: ->
      functions = {}

      if @_isDirectory
        functions.addDir =
          name: "Add Directory"
          cb: => @contextFuncAddDirectory @, "New Folder"
        functions.addFile =
          name: "Add File"
          cb: => @contextFuncAddFile @, "New File"

      unless _.contains @_disabled, "delete"
        functions.del =
          name: "Delete"
          cb: => @contextFuncRemoveAsset @

      unless _.contains @_disabled, "rename"
        functions.rename =
          name: "Rename ..."
          cb: => @contextFuncRenameAsset @

      {
        name: @getName()
        functions: functions
      }

    ###
    # @return [Object] renderParams
    ###
    toRenderParams: ->
      if @isDirectory()
        {
          id: @getID()
          name: @getName()
          entries: @_entries.map (e) -> e.toRenderParams()
          expanded: @getExpanded()
        }
      else
        {
          id: @getID()
          name: @getName()
          fileType: @getFileType()
        }

    ###
    # Serializing function
    # @return [Object]
    ###
    dump: ->
      data = _.extend Dumpable::dump.call(@),
        assetVersion: "1.1.0"
        id: @_id # will be ignored on load though
        name: @_name
        isDirectory: @_isDirectory
        disabled: @_disabled
        fileType: @_fileType

      if @_isDirectory
        data = _.extend data,
          expanded: @_expanded
          entries: @_entries.map (asset) =>
            asset.dump()

      data

    ###
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      Dumpable::load.call @, data
      @

    @load: (data) ->

      # data.assetVersion
      # for now we don't have to handle different project versions
      # since assets remain relatively the same
      asset = new Asset null, data
      # done to have Dumpable load properly
      asset.load data
      asset

###
@Changelog

  - "1.0.0": Initial
  - "1.1.0":
    version has been renamed to assetVersion this is to prevent name clashes
    with super classes who use "version" for their dumps as well

###