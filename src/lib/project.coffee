define (require) ->

  ID = require "util/id"

  Storage = require "storage"
  AUtilLog = require "util/log"

  Asset = require "handles/asset"
  Texture = require "handles/texture"
  BaseActor = require "handles/actors/base"

  EditorObject = require "editor_object"
  Dumpable = require "mixin/dumpable"

  class Project extends EditorObject

    @include Dumpable

    ###
    # this defines the current editor project version, this accompanies
    # every save state, and helps with the reloading process
    # note that every sub object has an internal save version as well
    # as the sub objects can change structure within the project
    # PROJECT_VERSION should only change if the Project contents itself
    # changes, not the sub objects.
    # @type [String]
    ###
    @PROJECT_VERSION: "0.3.1"

    ###
    # Current Editor.ui instance
    # @type [UIManager]
    ###
    @ui: null

    @current: null

    constructor: (@ui) ->

      @__id = ID.objId "project"
      @id = @__id.id

      @version = Project.PROJECT_VERSION

      @uid = ID.uID()
      @name = "Untitled #{@id}"

      @dateStarted = Date.now()

      @saveCount = 0

      ###
      # @type [Array<Object>]
      #   @property [String] url
      #   @property [String] filename
      ###
      @textures = []

      @assets = new Asset @,
        name: "top",
        disabled: ["delete", "rename"],
        isDirectory: true

      Project.current = @

    ###
    # Dumps the current Project state to basic Object for stringify-ing#
    # @return [Object]
    ###
    dump: ->
      ##
      # This is a v0.1.0 dump
      _.extend Dumpable::dump.call(@),
        version: @version                                      # v0.1.0
        uid: @uid                                              # v0.3.0
        dateStarted: @dateStarted                              # v0.3.1
        dateDumped: Date.now()                                 # v0.3.1
        name: @name                                            # v0.3.1
        saveCount: @saveCount+1                                # v0.3.1
        #textures: @textures                                   # v0.1.0
        assets: @assets.dump()                                 # v0.1.0
        textures: _.map @textures, (texture) -> texture.dump() # v0.2.0
        workspace: @ui.workspace.dump()                        # v0.1.0
        timeline: @ui.timeline.dump()                          # v0.1.0

    ###
    # Load the current Project state to basic Object for stringify-ing#
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      Dumpable::load.call @, data

      @ui.workspace.reset()

      ##
      # we may need to handle different project version in the future
      # for backward compatability.
      # so its best to tag the project version from early in production
      projver = data.version

      AUtilLog.info "Loading v#{projver} Project::dump"

      ##
      # assets have remained the same thus far
      @assets = Asset.load data.assets                     # v0.1.0
      @uid = data.uid || ID.uID()                          # v0.3.0
      @name = data.name || "Untitled #{projver} (project)" # v0.3.1
      @dateStarted = data.dateStarted || Date.now()        # v0.3.1
      @saveCount = data.saveCount || 1                     # v0.3.1

      ##
      # Luckily for us, textures are very similar when they where dumped
      # back in 0.1.0
      @textures = _.map data.textures, (data) -> Texture.load data
      for texture in @textures
        texture.project = @

      @ui.workspace.loadTextures @textures

      ##
      # We reload the workspace state BEFORE the timeline state
      # that way we update the timeline correctly.
      @ui.workspace.load data.workspace

      ##
      # This is a timeline load, on the instance level,
      # rather than the class level, I guess we could treat it as
      # a singleton object in that essence.
      @ui.timeline.load data.timeline

      @

    ###
    # Save the current project state to Storage
    # @return [self]
    ###
    quicksave: ->
      data = @dump()
      Storage.set "project.quicksave", JSON.stringify data
      AUtilLog.info "Project(uid: #{data.uid}) quicksave created"
      @

    ###
    # save the current project
    # for now, name does nothing, and save will perform a quicksave
    # instead of a hard save
    # @param [String] name
    # @return [self] project
    ###
    save: (name) ->
      @quicksave()
      @snapshot()
      @

    ###
    # Saves the current project to the project.snapshots Storage
    #
    # @param [String] name
    # @return [self] project
    ###
    snapshot: (name) ->
      snapshotCount = window.AdefyEditor.settings.autosave.maxcount

      snapshots = Storage.get("project.snapshots") || []
      snapshots.push JSON.stringify(@dump())

      if snapshots.length > snapshotCount
        snapshots = snapshots.slice snapshots.length-snapshotCount, -1

      Storage.set("project.snapshots", snapshots)

      @

    ###
    # @return [self] project
    ###
    autosave: ->
      @snapshot @name
      @

    ###
    # Reload a project from a given data structure
    # NOTE* DO NOT SEND A JSON STRING
    # @param [Object] data
    # @return [Project] project
    ###
    @load: (data) ->
      project = new Project @ui
      project.load data
      ##
      # and there you have it, your awesome project reloaded
      project

    ###
    # Attempt to load an existing quicksave
    # @return [Project] project
    ###
    @quickload: ->
      if quicksaveState = Storage.get("project.quicksave")
        data = null
        try
          data = JSON.parse quicksaveState
        catch e
          return AUtilLog.error "Failed to load state. [#{e}]"

        return @load data
      else
        AUtilLog.warn "quicksave does not exist"

    ###
    # Does a quicksave exist?
    # @return [Boolean]
    ###
    @quicksaveExists: ->
      !!Storage.get("project.quicksave")

    ###
    #
    # @return [Array<String>] snapshots an Array of JSON strings
    ###
    @snapshots: ->
      Storage.get("project.snapshots") || []

    ###
    # @return [Project] project
    ###
    @loadSnapshot: (index) ->
      if snapshot = @snapshots()[index]
        @load JSON.parse(snapshot)
      else
        AUtilLog.warn "project.snapshot(index: #{index}) does not exist"

###
  Changelog
    "0.1.0"
      Array<Object> textures

    "0.2.0"
      texures is now an Array<Texture>
###