define (require) ->

  ID = require "util/id"
  param = require "util/param"
  Widget = require "widgets/widget"
  Draggable = require "util/draggable"

  ###
  # Generic floating widget class, offers awesome functionality like dragging,
  # close on loss of focus, and a bunch of other stuff :D
  ###
  class FloatingWidget extends Widget

    ###
    # List of all living floating widgets (both visible and not). We use this
    # to keep track of what needs closing when the user clicks outside of
    # certain zones, etc.
    ###
    @allWidgets: []

    ###
    # Creates and draws us
    #
    # @param [String] title
    # @param [Array<String>] extraClasses optional array of extra classes
    ###
    constructor: (@ui, options) ->
      title = param.required options.title
      extraClasses = options.extraClasses || []

      super @ui,
        id: ID.prefID("floating-widget")
        classes: _.union ["floating-widget"], extraClasses

      @_closeOnFocusLoss = false
      @_visible = false
      @_animateSpeed = 100
      @_drag = null

      # By default, we are not visible; this just injects our HTML into the DOM
      # ready for showing
      @refreshStub()
      @refresh()

      @_registerBaseListeners()
      @registerListeners() if @registerListeners

    ###
    # Registers generic listeners for ourselves, including clicks on .close
    # and .minimize, along with the loss-of-focus listener
    ###
    _registerBaseListeners: ->

      # Loss of focus listener
      $(document).on "click", (e) =>
        if !$(@_sel).is(e.target) and $(@_sel).has(e.target).length == 0

          @kill() if @_closeOnFocusLoss

      # Generic close listener
      $(document).on "click", "#{@_sel} .close", (e) =>
        @kill()

      # Generic hide listener
      $(document).on "click", "#{@_sel} .hide", (e) =>
        @hide()

      # Generic minimize listener
      $(document).on "click", "#{@_sel} .minimize", (e) =>
        @minimize()

    ###
    # Sets up a draggable element for us (because YAY!)
    #
    # @param [String] dragSelector selector of the element we are dragged by
    ###
    makeDraggable: (dragSelector) ->
      return if @_drag

      @_drag = new Draggable dragSelector
      @_drag.setDragSelector @_sel

    ###
    # Set animation speed in ms (for show/hide)
    #
    # @param [Number] speed
    ###
    setAnimateSpeed: (speed) ->
      @_animateSpeed = speed

    ###
    # Designate if we should close (die!) once focus is lost (user clicks out
    # of us)
    #
    # @param [Boolean] close
    ###
    setCloseOnFocusLoss: (close) ->
      @_closeOnFocusLoss = close

    ###
    # Either animate visible, or invisible depending on the flag
    #
    # @param [Boolean] visible
    ###
    setVisible: (visible) ->
      if visible
        @show()
      else
        @hide()

    ###
    # Animate us visible. Coordinates are optional, defaulting to the center of
    # the screen
    #
    # @param [Number] x
    # @param [Number] y
    ###
    show: (x, y) ->
      return if @_visible

      w = @getElement().width()
      h = @getElement().height()
      x ||= (window.innerWidth / 2) - (w / 2)
      y ||= (window.innerHeight / 2) - (h / 2)

      @getElement().offset top: y, left: x
      @getElement().animate opacity: 1, @_animateSpeed, =>
        @_visible = true

    ###
    # Animate us invisible
    ###
    hide: ->
      return unless @_visible
      @getElement().animate opacity: 0, @_animateSpeed, =>
        @_visible = false

    ###
    # Check if we are visible
    #
    # @return [Boolean] visible
    ###
    isVisible: ->
      @_visible

    ###
    # Removes our HTML from the document; from this point onwards, we should
    # be deleted!
    ###
    kill: ->
      @hide()

      setTimeout =>
        @removeElement()
      , @_animateSpeed * 2

    minimize: ->

    restore: ->

    ###
    # Override these methods to do anything useful
    ###
    render: null
    registerListeners: null
