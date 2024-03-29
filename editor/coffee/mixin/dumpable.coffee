define (require) ->

  param = require "util/param"

  class Dumpable

    ###
    # @return [Object] data
    ###
    dump: ->
      {
        dumpVersion: "1.1.0"
      }

    ###
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      # data.dumpVersion
      @

    ###
    # Our serialization is a bit different, since we need to serialize each
    # of our child properties
    #
    # @return [String] data
    ###
    serialize: -> JSON.stringify @dump()

    ###
    # Clears our property array and fills it up using the supplied serialized
    # data
    #
    # @param [String] raw
    ###
    deserialize: (raw) ->
      @load JSON.parse raw
