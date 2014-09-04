define (require) ->

  param = require "util/param"
  HandleProperty = require "handles/properties/property"

  ###
  # Boolean property, nothing fancy
  ###
  class BooleanProperty extends HandleProperty

    @type: "boolean"

    constructor: (options) ->
      super BooleanProperty.type, options.birth, options.death

      @data_placeholder = true
      @data_value = false

    validateValue: (value) ->
      return false if value != false and value != true
      true

    setPlaceholder: (placeholder) -> @data_placeholder = placeholder
    getPlaceholder: (placeholder) -> @data_placeholder
