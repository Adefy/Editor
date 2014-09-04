define (require) ->

  Action = require "actions/action"

  class MoveActor extends Action

    constructor: ->
      super()
      @handle = null
      @source = null
      @target = null

    setup: (@handle, @target) ->
      @source = @handle.getPosition()
      @

    execute: ->
      @handle.setPosition(@target) if @handle
      @

    revert: ->
      @handle.setPosition(@source) if @handle
      @
