define (require) ->

  Action = require "actions/action"

  class RenameHandle extends Action

    constructor: ->
      super()
      @handle = null
      @newname = null
      @oldname = null

    setup: (@handle, @newname) ->
      @oldname = @handle.getName()
      @

    execute: ->
      @handle.setName(@newname) if @handle
      @

    revert: ->
      @handle.setName(@oldname) if @handle
      @
