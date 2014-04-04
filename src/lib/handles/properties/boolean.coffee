define (require) ->

  param = require "util/param"
  HandleProperty = require "handles/properties/property"

  ###
  # Boolean property, nothing fancy
  ###
  class BooleanProperty extends HandleProperty

    @type: "boolean"

    constructor: ->
      super BooleanProperty.type

      @data_placeholder = true

    setValue: (value) ->
      return unless @validateValue value

      @data_value = value
      @onUpdate value

    validateValue: (value) ->
      return false if value != false and value != true
      true

    setPlaceholder: (placeholder) -> @data_placeholder = placeholder
    getPlaceholder: (placeholder) -> @data_placeholder
