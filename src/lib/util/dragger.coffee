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
      @_tolerance = param.optional tolerance, 5
      @_sel = param.required selector

      @_delta = x: 0, y: 0
      @_start = x: 0, y: 0
      @_active = false
      @_target = null
      @_udata = null

      @onDragStart = null

      @bindListeners()

    ###
    # Set up drag event listeners
    ###
    bindListeners: ->
      $(document).on "mousedown", @_sel, (e) =>
        @_delta = x: 0, y: 0
        @_start = x: e.pageX, y: e.pageY
        @_target = e.target
        @_active = true

        @onDragStart @ if @onDragStart

      $(document).mousemove (e) =>
        return unless @_active

        dX = e.pageX - @_start.x
        dY = e.pageY - @_start.y

        return unless Math.abs(dX) > @_tolerance or Math.abs(dY) > @_tolerance

        @_delta = x: dX, y: dY
        @onDrag @, dX, dY if @onDrag

      $(document).mouseup (e) =>
        return unless @_active

        @_active = false

        @onDragEnd @ if @onDragEnd

        @_delta = x: 0, y: 0
        @_start = x: 0, y: 0
        @_target = null

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
    # Get the start position of the current drag
    #
    # @return [Object] position
    ###
    getStartPosition: -> @_start

    ###
    # Gets the current drag status
    #
    # @return [Boolean] isDragging
    ###
    isDragging: -> @_active

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
