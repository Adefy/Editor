# Base class for all elements that can be manipulated by the editor
# Sexy name, eh? Didn't really know what else to call it. Watch out for
# spelling mistakes.
class AManipulatable

  # Instantiates us, should never be called directly. We serve mearly
  # as a base class. Properties are setup here, so set up the property object
  # on extending classes after calling super(). Note that you can un-set
  # properties internally after this is done
  constructor: ->

    # User modifiable properties
    # Set manipulatable-global properties here
    @_properties = {}

    # Basic right-click menu functions
    @_ctx =
      "Delete": -> alert "Not implemented yet!"

    # Give ourselves a unique id so we can be discovered on the body
    @_id = prefId "amanipulatable"

    # Attach ourselves to the body
    me = @
    $(document).ready -> $("body").data me_id, me

  # Return the html representation to show when dropped on the workspace.
  # This gets appended to the workspace, and is automatically positioned
  # at the drop point. Since we are a base class, this function is called by
  # anyone extending us, with 'inner' being their final render. We wrap that in
  # a class identifying the div as a manipulatable object.
  #
  # @param [String] inner html to wrap
  # @param [Number] x x coordinate of resulting object
  # @param [Number] y y coordinate of resulting object
  # @return [String] html visible representation
  renderWorkspace: (inner, x, y) ->

    # For us, these are optional
    x = param.optional x, 0
    y = param.optional y, 0
    inner = param.optional inner, ""

    return "<div id=\"#{@_id}\" class=\"amanipulatable\">#{inner}</div>"

  # Returns an object representing the modifiable properties the object holds,
  # in key/value form. Default values are set in the constructor, after that
  # modifications are made through the other accessor.
  getProperties: -> @_properties

  # Set property in key, value form. Note that new properties can not be
  # created!
  #
  # @param [String] key
  # @param [Object] val
  setProperty: (key, val) ->
    param.required key
    param.required val

    # Prevent creation of new properties
    if @_properties[key] != undefined then @_properties[key] = val

  # Useful function for internal use, to render CSS properties from an object
  #
  # @param [Object] css properties to be rendered
  # @return [String] style html style attribute
  _convertCSS: (css) ->
    param.required css

    _html = "style=\""
    for s of css
      _html += "#{s}:#{css[s]};"
    _html += "\""

  # Get an object containing key/value pairs of contextual functions, in the
  # form name: cb
  #
  # These will be displayed in the context menu when the object is right
  # cliecked on. Again, just like the properties, global properties may be
  # applied by ancestors
  getContextFunctions: -> @_ctx
