define (require) ->

  param = require "util/param"

  Action = require "actions/action"

  class CallbackAction extends Action

    constructor: (options) ->
      super()
      @execute = options.executeCB
      @revert = options.revertCB
