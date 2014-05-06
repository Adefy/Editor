define (require) ->

  Action = require "actions/action"

  class ActionHandleProperty extends Action

    constructor: ->
      super "handle.property"
      @property = null
      @source = null
      @target = null

    ###
    # @param [String] property  name of property
    # @param [Object] source  revert values
    # @param [Object] target  execute values
    # @return [self]
    ###
    setup: (@property, @source, @target) -> @

    ###
    # @param [Handle] handle
    # @return [self]
    ###
    execute: (handle) ->
      handle.getProperty(@property).setValue(@target)
      @

    ###
    # @param [Handle] handle
    # @return [self]
    ###
    revert: (handle) ->
      handle.getProperty(@property).setValue(@source)
      @

    dump: ->
      _.extend super(),
        property: @property
        source: @source
        target: @target

    load: (data) ->
      super data
      @property = data["property"]
      @source = data["source"]
      @target = data["target"]
      @