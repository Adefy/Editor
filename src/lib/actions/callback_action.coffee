define (require) ->

  param = require "util/param"

  Action = require "actions/action"

  class CallbackAction extends Action

    constructor: (options) ->
      super()
      @execute = param.required options.executeCB
      @revert = param.required options.revertCB
