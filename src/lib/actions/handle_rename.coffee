define (require) ->

  Action = require "actions/action"

  class ActionHandleRename extends Action

    constructor: ->
      super "handle.rename"
      @newname = null
      @oldname = null

    setup: (@oldname, @newname) -> @

    execute: (handle) ->
      handle.setName(@newname)
      @

    revert: (handle) ->
      handle.setName(@oldname)
      @
