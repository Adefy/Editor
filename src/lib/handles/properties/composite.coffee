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

    constructor: ->
      super CompositeProperty.type
      @_properties = {}

    addProperty: (id, property) ->
      @_properties[id] = property

    getProperty: (id) ->
      @_properties[id]

    getProperties: ->
      @_properties

    setProperties: (properties) ->
      @_properties = properties

    ###
    # Requests an update for each child property
    ###
    requestUpdate: ->
      for id, property of @_properties
        property.requestUpdate()

    ###
    # Pass a new value to each child property through a hash, of the form
    # { id: value }
    #
    # @param [Object] data
    ###
    setValue: (data) ->
      for id, value of data
        if @_properties[id]
          @_properties[id].setValue value

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

