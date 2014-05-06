define (require) ->

  param = require "util/param"

  Action = require "actions/action"

  class ActionCallback extends Action

    constructor: (options) ->
      super "callback"
      @execute = param.required options.executeCB
      @revert = param.required options.revertCB
