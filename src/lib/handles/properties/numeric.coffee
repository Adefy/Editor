define (require) ->

  param = require "util/param"
  HandleProperty = require "handles/properties/property"

  ###
  # Numeric property, implements min/max checking, boolean float/integer state
  ###
  class NumericProperty extends HandleProperty

    @type: "number"

    constructor: (options) ->
      options ||= {}

      super NumericProperty.type

      setVal = (v, def) -> if v != undefined && v != null then v else def

      @data_min = setVal options.min, -Infinity
      @data_max = setVal options.max, Infinity
      @data_float = setVal options.float, true
      @data_precision = setVal options.precision, 2
      @data_placeholder = setVal options.placeholder, 0
      @data_value = setVal options.value, 0

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

    setMin: (min) ->
      if min == null
        @data_min = -Infinity
      else
        @data_min = min

    setMax: (max) ->
      if max == null
        @data_max = Infinity
      else
        @data_max = max

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
    # @return [Number] value
    ###
    getValue: ->
      Number super()

    ###
    # @return [String]
    ###
    getValueString: ->
      Number(@getValue()).toFixed @data_precision
