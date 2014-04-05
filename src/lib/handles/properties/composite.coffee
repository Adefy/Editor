define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  HandleProperty = require "handles/properties/property"

  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"

  ###
  # Composite property, keeps a list of child properties and handles graceful
  # serialization/deserialization
  ###
  class CompositeProperty extends HandleProperty

    @PropertyTypes: [
      NumericProperty
      BooleanProperty
    ]

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
    # Our serialization is a bit different, since we need to serialize each
    # of our child properties
    #
    # @return [String] data
    ###
    serialize: ->
      data = {}

      for id, property of @_properties
        data[id] = property.serialize()

      JSON.stringify data

    ###
    # Clears our property array and fills it up using the supplied serialized
    # data
    #
    # @param [String] raw
    ###
    deserialize: (raw) ->
      @_properties = {}
      raw = JSON.parse raw

      for id, propertyJSON of raw
        property = JSON.parse propertyJSON

        type = _.find CompositeProperty.PropertyTypes, (p) ->
          p.type == property.type

        unless type
          AUtilLog.error "Unknown property type, deserialize: #{property.type}"
        else
          newProperty = new type
          newProperty.deserialize propertyJSON
          @addProperty id, newProperty

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
