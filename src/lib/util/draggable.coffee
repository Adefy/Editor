define (require) ->

  Dragger = require "util/dragger"

  ###
  # Defines a draggable element; wrapps Dragger and updates the element position
  # based on the deltas
  ###
  class Draggable

    ###
    # Bind listeners and initialize draggable on element
    #
    # @param [String] selector
    # @param [Number] tolerance default 1
    ###
    constructor: (selector, tolerance) ->
      @_tolerance = param.optional tolerance, 1
      @_sel = param.required selector

      # Can be "x" or "y"
      @_constrain = null
      @_bounds =
        minX: -Infinity
        minY: -Infinity
        maxX: Infinity
        maxY: Infinity

      @_boundsOrigin = x: 0, y: 0

      # If this is not null, bounds are recalculated on drag start
      @_boundsElement = null

      @_condition = -> true

      @onDrag = null
      @onDragStart = null
      @onDragEnd = null

      @_drag = new Dragger @_sel, @_tolerance
      @_drag.setOnDragStart (d) =>
        return d.forceDragEnd() unless @_condition()

        d.setUserData $(@_sel).offset()

        if @_boundsElement
          boundingElementX = $(@_boundsElement).offset().left
          boundingElementY = $(@_boundsElement).offset().top
          boundingElementW = $(@_boundsElement).width()
          boundingElementH = $(@_boundsElement).height()

          @setBoundsOrigin boundingElementX, boundingElementY
          @setBounds 0, 0, boundingElementW, boundingElementH

        @onDragStart(d) if @onDragStart

      @_drag.setOnDrag (d, deltaX, deltaY) =>
        return unless d.getUserData()

        pos =
          x: d.getUserData().left
          y: d.getUserData().top

        pos.y += deltaY unless @_constrain == "x"
        pos.x += deltaX unless @_constrain == "y"

        return unless @isInBounds pos

        if @_constrain == "x"
          $(selector).offset left: pos.x
        else if @_constrain == "y"
          $(selector).offset top: pos.y
        else
          $(selector).offset top: pos.y, left: pos.x

        @onDrag(d, deltaX, deltaY) if @onDrag

      @_drag.setOnDragEnd (d) =>
        @onDragEnd(d) if @onDragEnd

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
    # Verifies that the supplied point is within our boundaries
    #
    # @param [Object] point
    # @return [Boolean] inBounds
    ###
    isInBounds: (point) ->
      X = point.x - @_boundsOrigin.x
      Y = point.y - @_boundsOrigin.y

      return false unless X >= @_bounds.minX
      return false unless Y >= @_bounds.minY
      return false unless X <= @_bounds.maxX
      return false unless Y <= @_bounds.maxY

      true

    constrainToX: -> @_constrain = "x"
    constrainToY: -> @_constrain = "y"

    ###
    # Set drag boundaries (relative to boundary origin)
    #
    # Boundaries are defined in maxX/maxY/minX/minY pixel values
    #
    # @param [Number] minX
    # @param [Number] minY
    # @param [Number] maxX
    # @param [Number] maxY
    ###
    setBounds: (minX, minY, maxX, maxY) ->
      param.required minX
      param.required minY
      param.required maxX
      param.required maxY

      @_bounds =
        minX: minX
        minY: minY
        maxX: maxX
        maxY: maxY

    ###
    # Set boundary origin (bounds coords are interpreted relative to this point)
    #
    # @param [Number] x
    # @param [Number] y
    ###
    setBoundsOrigin: (x, y) ->
      param.required x
      param.required y

      @_boundsOrigin = x: x, y: y

    ###
    # Helper, bounds to the dimensions of the specified element
    #
    # @param [DOMElement] element
    ###
    constrainToElement: (element) ->
      @_boundsElement = param.required element

    ###
    # Calls @constrainToElement() with our selectors' immediate parent
    ###
    constrainToParent: ->
      @constrainToElement $(@_sel).parent()

    ###
    # Set drag condition (drag is cancelled if the condition returns false
    # when dragging starts)
    #
    # @param [Method] condition
    ###
    setCondition: (condition) ->
      @_condition = condition
