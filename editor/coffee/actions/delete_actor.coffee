define (require) ->

  Action = require "actions/action"

  class DeleteActor extends Action

    constructor: ->
      super()
      @handle = null

    setup: (@handle) ->
      @

    execute: ->
      window.AdefyEditor.ui.workspace.removeActor(@handle) if @handle
      @

    revert: ->
      window.AdefyEditor.ui.workspace.addActor(@handle) if @handle
      @
