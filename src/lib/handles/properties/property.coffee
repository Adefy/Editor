define (require) ->

  param = require "util/param"

  Dumpable = require "mixin/dumpable"

  ###
  # Property wrapper, to facilitate HTML control generation and serialization
  #
  # This should never be initialized directly, instead one of the specialized
  # properties should be used.
  ###
  class HandleProperty extends Dumpable

    constructor: (type) ->

      @data_type = type
      @data_value = null

    ###
    # Fetch type
    #
    # @param [String] type
    ###
    getType: ->
      @data_type

    ###
    # Fetch our value; requests an update before returning
    #
    # @return [Object] value
    ###
    getValue: ->
      @requestUpdate()
      @data_value

    ###
    # Sets our type, used by deserialization (loading state)
    #
    # @param [String] type
    ###
    setType: (type) ->
      @data_type = type

    ###
    # Update our value. Validation and processing is done, and onUpdate() called
    #
    # @param [Object] value
    ###
    setValue: (value) ->
      return unless @validateValue value
      value = @processValue value

      @data_value = value
      @onUpdate value

    ###
    # This is what should be implemented for the property to be useful
    ###
    onUpdate: (value) ->

    ###
    # Attempt to update our value from an external source. This should be
    # overriden to fetch data from our handle, or AJSActor. Called at the start
    # of getValue()
    ###
    requestUpdate: ->

    ###
    # Ensure that the provided value is valid for useage
    #
    # @param [Object] value
    # @return [Boolean] valid
    ###
    validateValue: (value) -> true

    ###
    # Transform a value before it is applied
    #
    # @param [Object] value
    # @return [Object] processed
    ###
    processValue: (value) -> value

    ###
    # Capitalize the first letter of a string, and make the rest lowercase
    #
    # @param [String] string
    # @return [String] result
    ###
    capitalize: (str) ->
      str[0].toUpperCase() + str[1...].toLowerCase()

    ###
    # Copy internal data values from another property
    #
    # @param [HandleProperty] property
    ###
    clone: (property) ->
      @load property.dump()

    ###
    # The genAnimationOpts method needs to return an animations object suitable
    # for export, that can be passed to AJS.animate when animating the property
    # using the provided animation object.
    #
    # The genAnimationOpts method is only required if the property is not
    # natively supported by the engine.
    #
    # @param [Object] animation
    # @param [Object] options existing animation options
    # @return [Object] options final options
    ###
    genAnimationOpts: (animation, options) -> options

    ###
    # Dumps the property as a basic Object
    #
    # @return [Object] data
    ###
    dump: ->
      data = super()

      data.propertyVersion = "1.0.0"

      for key, value of @
        splitKey = key.split("get")

        if splitKey.length == 2
          data[splitKey[1].trim().toLowerCase()] = @[key]()

      data

    ###
    # Loads the property from a basic Object
    #
    # @param [Object] data
    ###
    load: (data) ->
      super data

      # data.propertyVersion >= "1.0.0"
      for key, value of data
        setter = "set#{@capitalize key}"
        @[setter] value if @[setter]

      @