###
# Awesome saving class (wrote this while high, YOLO)
###
define (require) ->

  Storage = require "storage"
  AUtilLog = require "util/log"

  BaseActor = require "handles/actors/base"

  class EditorStateSave

    constructor: (@ui) ->
      @updateState()

    updateState: ->
      @data =
        time: @dumpTimeInformation()
        actors: @dumpActorStates()

    dumpActorStates: ->
      @ui.workspace.getActors().map (actor) -> actor.serialize()

    dumpTimeInformation: ->
      {
        duration: @ui.timeline.getDuration()
        current: @ui.timeline.getCursorTime()
      }

    dumpState: ->
      JSON.stringify @data

    saveState: ->
      @updateState()
      Storage.set "quicksave", @dumpState()

    ###
    # Load saved state from Storage
    # NOTE: The editor should be reset before this is called!
    ###
    loadState: ->
      savedState = Storage.get "quicksave"
      return unless savedState

      try
        @data = JSON.parse savedState
      catch e
        return AUtilLog.error "Failed to load state. [#{e}]"

      @loadTimeInformation @data.time
      @loadActorStates @data.actors

    loadTimeInformation: (timeData) ->
      @ui.timeline.setDuration timeData.duration
      @ui.timeline.setCursorTime timeData.current

    loadActorStates: (actorData) ->
      for actor in actorData
        newActor = window[actor.type].load @ui, actor
        @ui.workspace.addActor newActor

      @ui.timeline.updateAllActorsInTime()

    saveExists: ->
      !!Storage.get("quicksave")
