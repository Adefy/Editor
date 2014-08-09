define (require) ->

  ID = require "util/id"
  Storage = require "storage"
  AUtilLog = require "util/log"
  Asset = require "handles/asset"
  Texture = require "handles/texture"
  EditorSuperClass = require "superclass"
  Dumpable = require "mixin/dumpable"

  class Project extends EditorSuperClass

    @include Dumpable

    ###
    # This accompanies every save state, and helps with the reloading process
    #
    # Note that every sub object has an internal save version as well, as the
    # sub objects can change structure within the project
    #
    # PROJECT_VERSION should only change if the Project contents itself
    # changes, not the sub objects.
    #
    # @type [String]
    ###
    @PROJECT_VERSION: "0.4.0"

    @current: null

    ###
    # Ensure that the provided save is of a proper format
    #
    # @param [Object] creative
    # @return [Boolean] valid
    ###
    @validateCreative: (creative) ->

      fieldCheck = (field) ->
        unless creative[field]
          AUtilLog.warning "Expected field #{field}"
          return false
        true

      return false unless fieldCheck "name"
      return false unless fieldCheck "owner"
      return false unless fieldCheck "slugifiedName"
      return false unless fieldCheck "saves"
      return false unless fieldCheck "exports"

      for save in creative.saves
        return false unless Project.validateSave save

      true

    ###
    # Ensure that the provided save is of a proper format
    #
    # @param [Object] save
    # @return [Boolean] valid
    ###
    @validateSave: (save) ->

      fieldCheck = (field) ->
        unless save[field]
          AUtilLog.warning "Expected field #{field}"
          false
        true

      return false unless fieldCheck "timestamp"
      return false unless fieldCheck "dump"

      true

    ###
    # @param [UIManager] ui
    # @param [Object] creative initial creative payload
    # @param [Method] onLoad cb called after the initial project load
    ###
    constructor: (@ui, creative, onLoad) ->

      unless Project.validateCreative creative
        return AUtilLog.error "Creative payload is not valid!"

      # Save creative properties on ourselves
      _.extend @, creative

      Project.current = @
      @version = Project.PROJECT_VERSION

      ###
      # @type [Array<Object>]
      #   @property [String] url
      #   @property [String] filename
      ###
      @textures = []

      # Load active save, if there is one, but do it after the current chain
      # of execution; otherwise, we won't be tied to objects like the current
      # Editor class
      if creative.activeSave and creative.saves.length > 0
        save = _.find creative.saves, (s) ->
          s.timestamp == new Date(creative.activeSave).getTime()

        if save
          @load save
        else
          AUtilLog.error "Invalid creative payload, active save not found"

      onLoad(@) if onLoad

    ###
    # Get S3 folder prefix
    #
    # @return [String] prefix
    ###
    getS3Prefix: ->
      "creatives/#{@owner}/#{@slugifiedName}-#{@id}/"

    ###
    # Get CDN url
    #
    # @return [String] prefix
    ###
    getCDNUrl: ->
      "http://cdn.adefy.com"

    ###
    # Get S3 folder prefix for active project
    #
    # @return [String] prefix
    ###
    @getS3Prefix: ->
      Project.current.getS3Prefix()

    ###
    # Get CDN url for active project
    #
    # @return [String] url
    ###
    @getCDNUrl: ->
      Project.current.getCDNUrl()

    ###
    # Returns the string prefix used to identify us in local storage
    #
    # @return [String] prefix
    ###
    getStoragePrefix: ->
      "project.#{@slugifiedName}"

    ###
    # Get project ID. This is what identifies us to the platform
    #
    # @return [String] id
    ###
    getId: -> @id

    ###
    # Get project texture array
    #
    # @return [Array<Texture>] textures
    ###
    getTextures: -> @textures or []

    ###
    # Generate a packed save object, ready for sending to a remote, or storing
    # locally. These objects are what we can @load()
    #
    # @return [Object] save
    ###
    generateSave: ->
      {
        timestamp: Date.now()
        version: @version
        dump: JSON.stringify @dump()
      }

    ###
    # Save the current project
    #
    # @param [Method] cb
    # @param [Method] errcb
    # @return [Project] self
    ###
    save: (cb, errcb) ->
      $.post "/api/v1/creatives/#{@id}/save", @generateSave(), ->
        console.log "Saved!"
        cb() if cb
      .fail ->
        AUtilLog.error "Failed to save to server"
        errcb() if errcb

      @

    ###
    # Takes a snapshot and saves it in localStorage. A snapshot is loaded on
    # start if one is found with a newer timestamp than the provided payload.
    #
    # Snapshots are NOT propogated to the server, unless a @save() is issued!
    #
    # @return [Project] self
    ###
    snapshot: ->
      snapshotCount = window.AdefyEditor.settings.autosave.maxcount

      snapshots = Storage.get("#{@getStoragePrefix()}.snapshots") || []
      snapshots.push @generateSave()

      if snapshots.length > snapshotCount
        snapshots = snapshots.slice snapshots.length-snapshotCount, -1

      Storage.set "#{@getStoragePrefix()}.snapshots", snapshots

      @

    ###
    # Return the local snapshot array.
    #
    # @return [Array<Object>] snapshots
    ###
    getSnapshots: ->
      Storage.get("#{@getStoragePrefix()}.snapshots") || []

    ###
    # @param [Number] timestamp snapshot timestamp
    # @return [Project] project
    ###
    loadSnapshot: (timestamp) ->

      snapshots = @getSnapshots()
      snapshotIndex = _.findIndex snapshots, (s) -> s.timestamp == timestamp

      if snapshotIndex
        console.log "Loading snapshot: #{timestamp} - #{new Date timestamp}"
        @load snapshots[snapshotIndex]
      else
        AUtilLog.warn "Local snapshot #{timestamp} does not exist"

    ###
    # Helper to find and load the newset snapshot by timestamp
    ###
    loadNewestSnapshot: ->
      snapshots = @getSnapshots()
      return unless snapshots.length > 0

      timestamps = _.pluck snapshots, "timestamp"
      timestamps.sort (a, b) -> b - a

      if timestamps[0] < @saveTimestamp
        return AUtilLog.warning "Refusing to load snapshot older than our save"

      @loadSnapshot timestamps[0]

    ###
    # Dumps the current Project state to basic Object for stringify-ing
    #
    # @return [Object]
    ###
    dump: ->
      _.extend Dumpable::dump.call(@),
        textures: _.map @textures, (texture) -> texture.dump() # v0.2.0
        workspace: @ui.workspace.dump()                        # v0.1.0
        timeline: @ui.timeline.dump()                          # v0.1.0

    ###
    # Load the current Project state to basic Object for stringify-ing
    #
    # @param [Object] dump raw creative dump, in object form
    # @return [self]
    ###
    load: (data) ->
      return unless Project.validateSave data

      try
        dump = JSON.parse data.dump
      catch e
        return AUtilLog.error "Failed to parse save dump [#{e}]"

      # What does this do?
      # Dumpable::load.call @, data.dump

      @ui.workspace.reset()

      AUtilLog.info "Loading v#{data.version} Project::dump"

      @saveTimestamp = data.timestamp
      @textures = _.map dump.textures, (texData) => Texture.load @, texData
      texture.project = @ for texture in @textures

      @ui.workspace.loadTextures @textures

      ##
      # We reload the workspace state BEFORE the timeline state
      # that way we update the timeline correctly.
      @ui.workspace.load dump.workspace

      ##
      # This is a timeline load, on the instance level,
      # rather than the class level, I guess we could treat it as
      # a singleton object in that essence.
      @ui.timeline.load dump.timeline

      @
