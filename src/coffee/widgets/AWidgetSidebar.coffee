# Generic sidebar, needs to be specialized to be useful
#
# @depend AWidget.coffee
class AWidgetSidebar extends AWidget

  # Creates a new sidebar with a given origin. The element's id is randomized
  # to sbar#{Math.floor(Math.random() * 1000)}
  #
  # @param [String] parent parent element selector
  # @param [String] origin 'left' or 'right', default is left
  # @param [Number] width
  constructor: (parent, origin, width) ->

    @_origin = param.optional origin, "left", [ "left", "right" ]
    @_width = param.optional width, 300

    # Assign ourselves a pseudo-unique id
    @_id = "sbar#{Math.floor(Math.random() * 1000)}"
    @_sel = "##{@_id}"

    param.required parent
    super @_id, parent, [ "asidebar" ]

    @_hiddenX = 0
    @_visibleX = 0

    # Calculate X offsets
    @onResize()

    # Set us up as initially visible
    @show()

    @setWidth @_width

  # Take the navbar into account, and always position ourselves below it
  onResize: ->

    # Re-size
    $(@_sel).height $(window).height() - $("#amainbar").height()
    $(@_sel).css { top: $("#amainbar").height() }

    # Re-position
    if @_origin == "right"
      @_hiddenX = $(window).width()
      @_visibleX = $(window).width() - @_width

  # Set sidebar width, sets internal offset values
  #
  # @param [Number] width
  setWidth: (width) ->
    param.required width
    @_width = width

    if @_origin == "left"
      @_hiddenX = - @_width
      @_visibleX = 0
    else
      @_hiddenX = $(window).width()
      @_visibleX = $(window).width() - @_width

    $(@_sel).width @_width

  # Toggle visibility of the sidebar with an optional animation
  #
  # @param [Method] cb callback
  # @param [Boolean] animate defaults to true
  toggle: (cb, animate) ->
    animate = param.optional animate, true

    # Keep in mind this can cause issues with code that depends on the
    # visibility state. I'm not sure if we should update it immediately,
    # or after the animation is finished. For the time being, we'll do so
    # immediately.

    # Cheese.
    if animate then AUtilLog.warn "Animation not yet supported"

    if @_visiblity
      @hide cb, animate
    else
      @show cb, animate

  # Show the sidebar with an optional animation
  #
  # @param [Method] cb callback
  # @param [Boolean] animate defaults to true
  show: (cb, animate) ->
    animate = param.optional animate, true

    if @_visiblity == true
      if cb then cb()
      return

    # And
    if animate then AUtilLog.warn "Animation not yet supported"

    $(@_sel).css { left: @_visibleX }

    console.log "displayed at #{@_visibleX}"

    @_visiblity = true

  # Hide the sidebar with an optional animation
  #
  # @param [Method] cb callback
  # @param [Boolean] animate defaults to true
  hide: (cb, animate) ->
    animate = param.optional animate, true

    if @_visiblity == false
      if cb then cb()
      return

    # Ham
    if animate then AUtilLog.warn "Animation not yet supported"

    $(@_sel).css { left: @_hiddenX }

    @_visiblity = false
