define (require) ->

  config = require "config"
  param = require "util/param"
  ID = require "util/id"

  AUtilLog = require "util/log"
  Widget = require "widgets/widget"

  TemplateBoundingBox = require "templates/workspace/bounding_box"

  # Bounding box widget for actors
  class BoundingBox extends Widget

    ###
    # Creates and renders a new bounding box. The properties of the box must be
    # explicitly set afterwards.
    #
    # @param [UIManager] ui
    ###
    constructor: (@ui) ->

      @_lastRotation = 0
      @_lastPosition = x: 0, y: 0

      super @ui,
        id: ID.prefID("bounding-box")
        parent: config.selector.content
        classes: ["bounding-box"]
        prepend: true

      # We render ourselves immediately; refreshStub creates our outer container
      @refreshStub()
      @refresh()

      @_registerListeners()

    _registerListeners: ->

    ###
    # Update our visual with a new position and rotation. Position is inferred
    # as relative to our top-left corner
    #
    # @param [Object] update
    # @option update [Object] position
    # @option update [Number] rotation
    ###
    updateOrientation: (update) ->
      update ||= {}

      @updatePosition update.position if update.position
      @updateRotation update.rotation if update.rotation

    updatePosition: (position) ->
      @_lastPosition = position
      elm = @getElement()

      elm.css transform: "rotate(0deg)"
      elm.offset
        top: position.y - (elm.height() / 2) - 1
        left: position.x - (elm.width() / 2) - 1
      elm.css transform: "rotate(#{@_lastRotation}rad)"

    updateWidth: (width) ->
      @getElement().width(width + 2)
      @updatePosition @_lastPosition

    updateHeight: (height) ->
      @getElement().height(height + 2)
      @updatePosition @_lastPosition

    updateBounds: (bounds) ->
      @getElement().width(bounds.w + 2)
      @getElement().height(bounds.h + 2)
      @updatePosition @_lastPosition

    updateRotation: (rotation) ->
      @_lastRotation = rotation
      @getElement().css transform: "rotate(#{rotation}rad)"

    render: ->
      super() + TemplateBoundingBox items: @_items
