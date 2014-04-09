define (require) ->

  param = require "util/param"
  ID = require "util/id"

  class Asset

    ###
    # @param [Hash] options
    ###
    constructor: (options) ->

      options = param.optional options, {}

      @_id = ID.prefId "asset"

      @_name = param.required options.name
      #@_color = param.optional options.color, [198, 198, 198]

      @_isDirectory = param.optional options.isDirectory, false

      if @_isDirectory
        @_entries = param.optional options.entries, []
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
    # Pushes new entries into a directory
    # @param [Asset] asset
    ###
    pushEntry: (asset) ->
      @_checkIsDirectory()
      @_entries.push asset

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
    getId: -> @_id

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
    # @return [Object] renderParams
    ###
    toRenderParams: ->
      if @isDirectory()
        {
          id: @getId()
          name: @getName()
          entries: @_entries.map (e) -> e.toRenderParams()
          expanded: @getExpanded()
        }
      else
        {
          id: @getId()
          name: @getName()
          fileType: @getFileType()
        }
