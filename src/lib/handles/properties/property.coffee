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

    ###
    # @param [String] type
    # @param [Number] birth
    # @param [Number] death
    ###
    constructor: (type, birth, death) ->

      @data_type = type
      @data_value = null
      @_buffer = {}
      @_birth = birth or 0
      @_death = death or 1000
      @_currentTime = @_birth
      @visible_in_sidebar = false

    seekToTime: (time) ->
      time = Number time

      # Snap to the nearest buffered time to our left
      time = @getNearestTime time
      return unless time != @_currentTime

      @setValue @_buffer[time], true
      @_currentTime = time

    ###
    # Finds the closest time in the left direction from the specified time.
    # Returns -1 if no such time is found (birth, or no left state)
    #
    # @param [Number] time
    # @return [Number] nearest
    ###
    getNearestTime: (time) ->
      if time < @_birth or time > @_death
        console.warn "Can't find nearest time, outside of lifetime: #{time}"
        return -1

      if !!@_buffer[time]
        time
      else

        # At birth, no other times to our left
        return @_birth if time == @_birth

        times = _.keys @_buffer
        times.sort (a, b) -> b - a
        startTimeIndex = _.findIndex times, (t) -> t == time

        # No other times to our left
        if startTimeIndex >= times.length - 1
          times[startTimeIndex]
        else
          times[startTimeIndex + 1]

    ###
    # Check if we have more keyframes besides our birth
    #
    # @return [Boolean] hasKeyframes
    ###
    hasKeyframes: ->
      _.keys(@_buffer).length > 1

    ###
    # Get an array of our keyframes, sorted in ascending order
    #
    # @return [Array<Number>] keyframes
    ###
    getKeyframeTimes: ->
      times = _.keys(@_buffer).map (t) -> Number t
      times.sort()

    ###
    # Get our keyframe time/value hash
    #
    # @return [Object] keyframes
    ###
    getKeyframes: ->
      @_buffer

    ###
    # Fetch our birth time
    #
    # @return [Number] birth
    ###
    getBirth: -> @_birth

    ###
    # Fetch our death time
    #
    # @return [Number] death
    ###
    getBirth: -> @_death

    ###
    # Set a new birth time. Keyframes occuring before this point are destroyed.
    #
    # @param [Number] birth
    # @return [Boolean] success
    ###
    setBirth: (birth) ->
      return false if birth < 0 or birth >= @_death

      # @todo...

      @_birth = birth
      true

    ###
    # Set a new death time. Keyframes occuring after this point are destroyed.
    #
    # @param [Number] death
    # @return [Boolean] success
    ###
    setBirth: (death) ->
      return false if death <= @_birth

      # @todo...

      @_death = death
      true

    ###
    # Fetch type
    #
    # @param [String] type
    ###
    getType: ->
      @data_type

    ###
    # Check if we should be shown in the sidebar
    #
    # @return [Boolean] visible
    ###
    showInSidebar: -> @visible_in_sidebar

    ###
    # Set if we should be displayed in the sidebar
    #
    # @param [Boolean] visible
    ###
    setVisibleInSidebar: (visible) ->
      @visible_in_sidebar = visible

    ###
    # Fetch our value; requests an update before returning
    #
    # @return [Object] value
    ###
    getValue: ->
      @requestUpdate()
      @data_value

    ###
    # @return [String]
    ###
    getValueString: ->
      String @getValue()

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
    # @param [Boolean] skipBuffer optionally skip our temporal buffer
    ###
    setValue: (value, skipBuffer) ->
      return unless @validateValue value
      value = @processValue value

      @_buffer[@_currentTime] = value unless skipBuffer

      @data_value = value
      @onUpdate value

    ###
    # This is what should be implemented for the property to be useful
    ###
    onUpdate: (value) ->

    ###
    # Attempt to update our value from an external source. This should be
    # overriden to fetch data from our handle, or AREActor. Called at the start
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
    # Create an object suitable for inclusion in a prop buffer entry
    #
    # @return [Object] snapshot
    ###
    getBufferSnapshot: ->
      { value: @getValue() }

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

###
@Changlog

  - "1.0.0": Initial

###
