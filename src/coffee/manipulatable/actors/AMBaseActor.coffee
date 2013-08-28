# Base manipulateable class for actors
class AMBaseActor extends AManipulatable

  # Defines a raw actor, with no shape information or any other presets.
  # This serves as the base for the other actor classes
  constructor: ->

    # Set up properties object (global defaults set)
    super()

    # Default actor properties, common to all actors
    @_properties["position"] =
      x: 0
      y: 0

    @_properties["rotation"] = 0
    @_properties["color"] =
      r: 0
      g: 0
      b: 0

    @_properties["psyx"] = false
    @_properties["verts"] = []

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

    _css =
      width: "100px"
      height: "100px"
      "background-color": "red"
      border: "2px solid black"
      "border-radius": "5px"
      left: "#{x}px"
      top: "#{y}px"

    super "<div #{@_convertCSS(_css)}>#{inner}</div>"
