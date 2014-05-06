define (require) ->

  Dumpable = require "mixin/dumpable"

  class Action extends Dumpable

    constructor: (type) ->
      @type = param.required type

    ###
    # @return [self]
    ###
    execute: ->
      @

    ###
    # @return [self]
    ###
    revert: ->
      @
