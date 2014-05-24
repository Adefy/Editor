define (require) ->

  ###
  # Helper class to make responding to drag events easier
  ###
  class Dragger

    ###
    # Initializes listeners
    #
    # @param [String] selector selector to listen for mouse movements on
    # @param [Number] tolerance drag tolerance in pixels, default 5
    ###
    constructor: (selector, tolerance) ->
      @_tolerance = tolerance || 5
      @_sel = param.required selector

      @clearUserData()
      @disableDragging()

      @bindListeners()

      @modifiers = {}
      @checkDrag = (e) -> true

    ###
    # @param [Function] checkDrag
    ###
    setCheckDrag: (@checkDrag) -> @

    ###
    # Set up drag event listeners
    ###
    bindListeners: ->
      console.log "Bound dragger listeners"
      $(document).on "mousedown", @_sel, (e) =>
        return unless @checkDrag e

        @modifiers.shiftKey = e.shiftKey
        @modifiers.ctrlKey = e.ctrlKey
        @modifiers.altKey = e.altKey
        @modifiers.superKey = e.superKey

        @_delta = x: 0, y: 0
        @_start = x: e.pageX, y: e.pageY
        @_target = e.target
        @_active = true

        @clearUserData()

      $(document).mousemove (e) =>
        return unless @_active

        dX = e.pageX - @_start.x
        dY = e.pageY - @_start.y

        return unless Math.abs(dX) > @_tolerance or Math.abs(dY) > @_tolerance

        unless @_dragStartFired
          @onDragStart @ if @onDragStart
          @_dragStartFired = true

        @_delta = x: dX, y: dY
        @onDrag @, dX, dY if @onDrag

      $(document).mouseup (e) =>
        return unless @_active

        @onDragEnd @ if @onDragEnd
        @disableDragging()

    ###
    # Set the drag start listener, called with ourselves as the first argument
    #
    # @param [Method] onDragStart
    ###
    setOnDragStart: (method) -> @onDragStart = method

    ###
    # Set the drag end listener, called with ourselves as the first argument
    #
    # @param [Method] onDragEnd
    ###
    setOnDragEnd: (method) -> @onDragEnd = method

    ###
    # Set the drag event listener, called with ourselves, dx, and dy
    #
    # @param [Method] onDrag
    ###
    setOnDrag: (method) -> @onDrag = method

    ###
    # Get the drag delta, split up into x/y component values
    #
    # @return [Object] delta
    ###
    getDelta: -> @_delta

    ###
    # Get the target element of the current drag
    #
    # @return [Object] target
    ###
    getTarget: -> @_target

    ###
    # Set a custom target element
    #
    # @param [Object] target
    ###
    setTarget: (target) -> @_target = target

    ###
    # Get the start position of the current drag
    #
    # @return [Object] position
    ###
    getStart: -> @_start

    ###
    # Returns true if our threshold has been passed, and we are dragging
    #
    # @return [Boolean] isDragging
    ###
    isDragging: -> @_dragStartFired

    ###
    # Get the active status; this is true even if the threshold hasn't been hit
    #
    # @return [Boolean] isActive
    ###
    isActive: -> @_active

    ###
    # Store user data; we don't touch this at all
    #
    # @param [Object] data
    ###
    setUserData: (data) -> @_udata = data

    ###
    # Retrieve user data
    #
    # @return [Object] data
    ###
    getUserData: -> @_udata

    ###
    # Helper, sets a user data key (assumes user data is an object!)
    #
    # @param [String] key
    # @param [Object] value
    ###
    setUserDataValue: (key, value) ->
      return unless @_udata and typeof @_udata == "object"
      @_udata[key] = value

    ###
    # Helpers, gets a user data value by key (assumes user data is an object!)
    #
    # @param [String] key
    # @return [Object] value
    ###
    getUserDataValue: (key) ->
      return unless @_udata and typeof @_udata == "object"
      @_udata[key]

    ###
    # Set user data to null
    ###
    clearUserData: -> @_udata = null

    ###
    # Manually disable dragging
    ###
    disableDragging: ->
      @_active = false
      @_dragStartFired = false
      @_delta = x: 0, y: 0
      @_start = x: 0, y: 0
      @_target = null

    ###
    # Forcefully ends the drag by clearing user data and disabling ourselves
    ###
    forceDragEnd: ->
      @clearUserData()
      @disableDragging()
