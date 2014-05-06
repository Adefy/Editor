define (require) ->

  Actors = require "handles/actors"
  Action = require "actions/action"

  class ActionActorDelete extends Action

    constructor: ->
      super "actor.delete"
      @handle = null

    setup: (@handle) -> @

    execute: ->
      window.AdefyEditor.ui.workspace.removeActor(@handle) if @handle
      @

    revert: ->
      window.AdefyEditor.ui.workspace.addActor(@handle) if @handle
      @

    dump: ->
      _.extend super(),
        handle: @handle.dump()

    load: (data) ->
      super data
      @handle = Actors[data.type].load data
      @