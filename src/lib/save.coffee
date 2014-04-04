###
# Awesome saving class (wrote this while high, YOLO)
###
define (require) ->

  class EditorStateSave

    constructor: (@ui) ->
      @updateState()

    updateState: ->
      @data = {}

      @updateActorState()

    updateActorState: ->
      @data.actors = @ui.workspace.getActors().map (actor) ->
        actor.serialize()

    dumpState: ->
      @updateState()
