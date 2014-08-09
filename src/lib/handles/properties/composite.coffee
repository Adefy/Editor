define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  HandleProperty = require "handles/properties/property"

  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"

  Dumpable = require "mixin/dumpable"

  ###
  # Composite property, keeps a list of child properties and handles graceful
  # serialization/deserialization
  ###
  class CompositeProperty extends HandleProperty

    @PropertyTypes:
      number: NumericProperty
      boolean: BooleanProperty
      composite: @

    @type: "composite"

    ###
    # @NOTE: We don't store any temporal data! We expect to have the same
    # children throughout our lifetime. All calls to seekToTime() fall through
    # to our children. Our own birth and death are never modified by @setBirth
    # or @setDeath, the calls simply pass through to all children.
    #
    # @param [Object] options
    ###
    constructor: (options) ->
      super CompositeProperty.type, options.birth, options.death
      @_properties = {}

    addProperty: (id, property) ->
      @_properties[id] = property

    getProperty: (id) ->
      @_properties[id]

    getProperties: ->
      @_properties

    setProperties: (properties) ->
      @_properties = properties

    seekToTime: (time) ->
      for id, property of @_properties
        property.seekToTime time

    ###
    # Calls @moveKeyFrame() on all of our child properties with the provided
    # times.
    #
    # Any existing keyframes at the target time are overwritten!
    #
    # @param [Number] sourceTime
    # @param [Number] targetTime
    ###
    moveKeyframe: (sourceTime, targetTime) ->
      for id, property of @_properties
        property.moveKeyframe sourceTime, targetTime

    ###
    # Set birth time for all of our children. The first set that fails causes
    # us to return false.
    #
    # @param [Number] birth
    # @return [Boolean] success
    ###
    setBirth: (birth) ->
      for id, property of @_properties
        unless property.setBirth birth
          return false

      @_birth = birth
      true

    ###
    # Set death time for all of our children. The first set that fails causes
    # us to return false.
    #
    # @param [Number] death
    # @return [Boolean] success
    ###
    setDeath: (death) ->
      for id, property of @_properties
        unless property.setDeath death
          return false

      @_death = death
      true

    ###
    # Requests an update for each child property
    ###
    requestUpdate: ->
      for id, property of @_properties
        property.requestUpdate()

    ###
    # Get an array of our keyframes, sorted in ascending order. This is a
    # combination of the keyframe times on our child properties.
    #
    # @return [Array<Number>] keyframes
    ###
    getKeyframeTimes: ->
      compiledTimes = _.values(@_properties).map (v) -> v.getKeyframeTimes()
      times = _.reduce compiledTimes, (reduced, set) ->
        reduced = _.union reduced, set
      times.sort()
      times

    ###
    # Get our keyframe time/value hash. Extracted from our children.
    #
    # @return [Object] keyframes
    ###
    getKeyframes: ->
      keyframes = {}

      for name, property of @_properties
        keys = property.getKeyframes()

        for time, entry of keys
          keyframes[time] ||= {}
          keyframes[time][name] = entry

      keyframes

    ###
    # Pass a new value to each child property through a hash, of the form
    # { id: value }
    #
    # @NOTE: We don't store or update our own temporal data!
    #
    # @param [Object] data
    ###
    setValue: (data) ->
      for id, value of data
        @_properties[id]?.setValue value

    ###
    # Get the values of all children in a hash, stored by ID
    #
    # @return [Object] data
    ###
    getValue: ->
      data = {}

      for id, property of @_properties
        data[id] = property.getValue()

      data

    ###
    # Composite update method; pass in a value for each child by id, and
    # onUpdate() will be triggered for each child
    #
    # @param [Object] data
    ###
    onUpdate: (data) ->
      for id, value of data
        if @_properties[id]
          @_properties[id].onUpdate value, batch: true

    validateValue: null
    processValue: null

    ###
    # Create an object suitable for inclusion in a prop buffer entry
    #
    # @return [Object] snapshot
    ###
    getBufferSnapshot: ->
      snapshot = components: {}

      for cName, cValue of @getProperties()
        snapshot.components[cName] = value: cValue.getValue()

      snapshot

    ###
    # Dumps as a basic Object
    # @return [Object] data
    ###
    dump: ->
      #data = super()
      data = _.extend Dumpable::dump.call(@),
        type: "composite"

      for id of @_properties
        data[id] = @_properties[id].dump()

      data

    ###
    # Loads from a basic Object
    # @params [Object] data
    # @return [self]
    ###
    load: (data) ->
      Dumpable::load.call @, data
      #super data
      for id, property of data
        continue if id == "dumpVersion" # we don't want the dump version
        continue if id == "type" # we don't want the type

        if @_properties[id]
          @_properties[id].load property
        else
          unless CompositeProperty.PropertyTypes[property.type]
            AUtilLog.error "Unknown property type: #{property.type}"
          else
            newProperty = new CompositeProperty.PropertyTypes[property.type]
            newProperty.load property
            @addProperty id, newProperty

      @
