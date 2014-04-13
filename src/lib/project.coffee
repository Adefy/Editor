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
    @PROJECT_VERSION: "0.2.0"

    ###
    # Current Editor.ui instance
    # @type [UIManager]
    ###
    @ui: null

    constructor: (@ui) ->

      @__id = ID.objId "project"
      @id = @__id.id

      @version = Project.PROJECT_VERSION

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

    ###
    # Dumps the current Project state to basic Object for stringify-ing#
    # @return [Object]
    ###
    dump: ->
      ##
      # This is a v0.1.0 dump
      _.extend Dumpable::dump.call(@),
        version: @version
        textures: _.map @textures, (texture) -> texture.dump()
        assets: @assets.dump()
        timeline: @ui.timeline.dump()
        workspace: @ui.workspace.dump()

    ###
    # Load the current Project state to basic Object for stringify-ing#
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      Dumpable::load.call @, data
      ##
      # we may need to handle different project version in the future
      # for backward compatability.
      # so its best to tag the project version from early in production
      projver = data.version

      AUtilLog.info "Loading a v#{projver} Project dump"

      ##
      # assets have remained the same thus far
      @assets = Asset.load data.assets

      ##
      # now this is where stuff goes nutty
      # this is mostly an example of what should/could happen in the future
      switch projver
        when "0.1.0", "0.2.0"

          ##
          # Luckily for us, textures are very similar when they where dumped
          # back in 0.1.0
          @textures = _.map data.textures, (data) -> Texture.load data
          for texture in @textures
            texture.project = @

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
      Storage.set "project.quicksave", JSON.stringify @dump()
      AUtilLog.info "quicksave created"
      @

    ###
    # save the current project
    # for now, name does nothing, and save will perform a quicksave
    # instead of a hard save
    # @param [String] name
    ###
    save: (name) ->
      @quicksave()

    ###
    # Reload a project from a given data structure
    # NOTE* DO NOT SEND A JSON STRING
    # @param [Object] data
    ###
    @load: (data) ->
      project = new Project @ui
      project.load data
      ##
      # and there you have it, your awesome project reloaded
      project

    ###
    # Attempt to load an existing quicksave
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
  Changelog
    "0.1.0"
      Array<Object> textures

    "0.2.0"
      texures is now an Array<Texture>
###