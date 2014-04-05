define (require) ->

  param = require "util/param"
  HandleProperty = require "handles/properties/property"

  ###
  # Numeric property, implements min/max checking, boolean float/integer state
  ###
  class NumericProperty extends HandleProperty

    @type: "number"

    constructor: ->
      super NumericProperty.type

      @data_min = -Infinity
      @data_max = Infinity
      @data_float = true
      @data_precision = 2
      @data_placeholder = 0
      @data_value = 0

    setValue: (value) ->
      return unless @validateValue value
      value = @processValue value

      @data_value = value
      @onUpdate value

    validateValue: (value) ->
      return false if isNaN value
      return false unless value >= @getMin()
      return false unless value <= @getMax()
      true

    processValue: (value) ->
      if @getFloat()
        value = Number value.toFixed @getPrecision()
      else
        value = Number value.toFixed 0

      value

    setMin: (min) -> @data_min = min
    setMax: (max) -> @data_max = max
    setFloat: (float) -> @data_float = float
    setPrecision: (precision) -> @data_precision = precision
    setPlaceholder: (placeholder) -> @data_placeholder = placeholder

    getMin: (min) -> @data_min
    getMax: (max) -> @data_max
    getFloat: (float) -> @data_float
    getPrecision: (precision) -> @data_precision
    getPlaceholder: (placeholder) -> @data_placeholder

    ###
    # Returns formatted value (enforcing precision)
    #
    # @return [Object] value
    ###
    getValue: ->
      Number super().toFixed @data_precision
