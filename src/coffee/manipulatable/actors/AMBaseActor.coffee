# Base manipulateable class for actors
class AMBaseActor extends AManipulatable

  # Defines a raw actor, with no shape information or any other presets.
  # This serves as the base for the other actor classes
  constructor: ->

    # Set up properties object (global defaults set)
    super()

    # Default actor properties, common to all actors
    @_properties["position"] =
      type: "composite"
      components:
        x:
          type: "number"
          float: true
          default: 0
        y:
          type: "number"
          float: true
          default: 0

    @_properties["rotation"] =
      type: "number"
      min: 0
      max: 360
      float: true
      default: 0

    @_properties["color"] =
      type: "composite"
      components:
        r:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 0
        g:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 0
        b:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 0

    @_properties["psyx"] =
      type: "bool"
      default: false

    #@_properties["verts"] = []

    # Register our click and deselect handlers
    me = @
    $(document).on "click", "##{@_id}", -> me._onClick()
    $(document).mouseup (e) ->

      us = $("##{me._id}")

      if us != undefined
        if !us.is(e.target) && us.has(e.target).length == 0
          $("##{me.getId} .amba-selected").removeClass "active"

  # Our onclick handler. It's broken out so we can make a call to super(), and
  # therefore have some global click functionality. Namely, property editing
  #
  # The special part of this is setting up an indicator of selection
  _onClick: ->
    $("##{@_id} .amba-selected").addClass "active"
    super()

  # We require an extra step upon destruction, namely a call to unbind our
  # click listener. We call through to super at the end
  destroy: ->
    $(document).off "click", "##{@_id}"
    # TODO: Clear the properties panel if necessary
    super()

  # Returns the html representation to show when dropped on the workspace.
  # Note that anyone extending us should also extend this method! The
  # AManipulatable base class offers a version of this method that wraps us
  # in a div with a recognizable class. All calls to this function should
  # propogate all the way down to the AManipulatable implementation for
  # wrapping.
  #
  # As such, 'inner' is the content to be wrapped by the next function down.
  # If that function is not AManipulatable's, then it normally shouldn't do
  # anything but pass 'inner' one level deeper.
  #
  # To summarize, the result of this function is passed to super(), and the
  # result of that is returned.
  #
  # @param [String] inner html to wrap
  # @param [Number] x x coordinate of resulting object
  # @param [Number] y y coordinate of resulting object
  # @return [String] html visible representation
  renderWorkspace: (inner, x, y) ->
    param.required x
    param.required y

    inner = param.optional inner, ""
    _html = ""

    # If inner content is provided, then just pass it down
    if inner.length > 0
      _html = inner
    else

      # Provide a default inner, an obnoxious red box
      _css =
        width: "100px"
        height: "100px"
        "background-color": "red"
        border: "2px solid black"
        "border-radius": "5px"
        left: "#{x}px"
        top: "#{y}px"

      # We have a surrounding div, which we use to display our selected state
      _html =  "<div #{@_convertCSS(_css)}>"
      _html +=   "<div class=\"amba-selected\">#{inner}</div>"
      _html += "</div>"

    super _html
