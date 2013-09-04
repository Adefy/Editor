# Properties widget, dynamically refreshable
#
# @depend AWidgetSidebarItem.coffee
class AWidgetSidebarProperties extends AWidgetSidebarItem

  # Instantiates, but does not set data!
  #
  # @param [AWidgetSidebar] parent sidebar parent
  constructor: (parent) ->
    param.required parent
    super parent

    # We cache our internal built state, since we require an object to show
    # anything meaningful. Our state is refreshed externally, after which
    # we save the HTML in this property, request a render from our parent,
    # and then pass it down once our parent responds
    @_builtHMTL = ""

    # Automatically register self as the default properties widget if none yet
    # exists
    $("body").data "default-properties", @

    # Add ourselves to the sidebar. We don't request a render since we haven't
    # been notified of an object with any properties
    @_parent.addItem @

  # Refresh widget data using a manipulatable, not that this function is
  # not where injection occurs! We request a refresh from our parent for that
  #
  # @param [AManipulatable] obj
  refresh: (obj) ->
    param.required obj

    properties = obj.getProperties()

    # Generate html to inject
    @_builtHMTL = "<ul class=\"as-properties\">"

    for p of properties
      _controlHTML = @_generateControl p, properties[p]
      @_builtHMTL += "<li class=\"asp-control-group\">#{_controlHTML}</li>"

    @_builtHMTL += "<button class=\"asp-save\">Save</button>"
    @_builtHMTL += "</ul>"

    @_parent.render()

  # Clear the property widget
  clear: ->
    @_builtHMTL = ""
    @_parent.render()

  # Return internally pre-rendered HTML. We need to pre-render since we rely
  # upon object data to be meaningful (note comment in the constructor)
  #
  # @return [String] html
  render: -> @_builtHMTL

  # Generates a mini HTML control widget for the property in question
  #
  # @param [String] name
  # @param [Object] value
  # @return [String] html rendered widget
  _generateControl: (name, value, __recurse) ->
    # Note we have an extra, undocumented parameter! It is set to true when
    # the method is called by itself.
    __recurse = param.optional __recurse, false
    param.required name
    param.required value

    # We require a type to do anything
    param.required value.type

    # Capitalize first letter if appropriate
    if name.length > 3
      name = name.charAt(0).toUpperCase() + name.substring 1

    _html =  ""
    _html += "<div class=\"asp-control\">"

    # Iterate
    if value.type == "composite"

      param.required value.components

      _html += "<div class=\"aspc-composite-name\">#{name}</div>"

      # Build the control by recursing and concating the result
      for p of value.components
        _html += @_generateControl p, value.components[p], true

    else

      # Generate a unique name for the input, to properly target its' label
      _inputName = prefId "aspc"
      _html += "<label for=\"#{_inputName}\">#{name}</label>"

      # Set up optional values
      if value.max == undefined then value.max = null
      if value.min == undefined then value.min = null
      if value.preview == undefined then value.preview = false

      if value.type == "number"

        if value.default == undefined then value.default = 0
        if value.float == undefined then value.float = true

        _html += "<input "
        _html +=   "name=\"#{_inputName}\" "
        _html +=   "type=\"text\" "
        _html +=   "data-max=\"#{value.max}\" "
        _html +=   "data-min=\"#{value.min}\" "
        _html +=   "data-control=\"number\" "
        _html +=   "data-float=\"#{value.float}\" "
        _html +=   "value=\"#{value.default}\" "
        _html += " />"

      else if value.type == "bool"

        if value.default == undefined then value.default = false

        _html += "<input "
        _html +=   "name=\"#{_inputName}\" "
        _html +=   "type=\"checkbox\" "
        _html +=   "data-control=\"bool\" "
        _html +=   value.default ? "checked " : ""
        _html += " />"

      else if value.type == "text"

        if value.default == undefined then value.default = ""

        _html += "<input "
        _html +=   "name=\"#{_inputName}\" "
        _html +=   "type=\"text\" "
        _html +=   "data-control=\"text\" "
        _html +=   "value=\"#{value.default}\" "
        _html += " />"

      else
        AUtilLog.warn "Unrecognized property type #{value.type}"

    if not __recurse and value.preview
      _html += "<div class=\"aspc-preview\">"
      _html +=   "<label for=\"preview-#{name}\">Preview</label>"
      _html +=   "<input name=\"preview-#{name}\" type=\"checkbox\">"
      _html += "</div>"

    _html += "</div>"
