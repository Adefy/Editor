# Properties widget, dynamically refreshable
#
# @depend AWidgetSidebarItem.coffee
class AWidgetSidebarProperties extends AWidgetSidebarItem

  # Prevents us from binding event listeners twice
  @__exists: false

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

    # Object that we are displaying properties for
    @_curObject = null

    if AWidgetSidebarProperties.__exists == false
      AWidgetSidebarProperties.__exists = true
      me = @

      # Event listeners!
      $(document).ready ->

        # Save
        $(document).on "click", ".asp-save", -> me.save @

        # Numeric drag modification
        # This is very similar to actor dragging, see AWidgetWorkspace
        __drag_start_x = 0      # Keeps track of the initial drag point, so
        __drag_start_y = 0      # we know when to start listening

        __drag_target = null      # Input we need to effect
        __drag_orig_val = -1      # Value of the input when dragging started

        __drag_tolerance = 5  # How far the mouse should move before we pick up
        __drag_sys_active = true

        # Start of dragging
        $(document).on "mousedown", ".drag_mod", (e) ->

          # Attempt to find a valid target input
          __drag_target = $(@).parent().find("> input")[0]

          if __drag_target == null
            AUtilLog.warn "Drag start on a label with no input!"
          else

            # Store initial cursor position
            __drag_start_x = e.pageX
            __drag_start_y = e.pageY

            # Store our target's value
            __drag_orig_val = Number($(__drag_target).val())

            # Enable mousemove listener
            __drag_sys_active = true

            # Tack on a permanent drag cursor, which is taken off when the drag
            # ends
            $("body").css "cursor", "e-resize"

            # Prevent highlighting of the page and whatnot
            e.preventDefault()
            return false

        # The following are global listeners, since mouseup and mousemove can
        # happen anywhere on the page, yet still relate to us
        $(document).mousemove (e) ->
          if __drag_sys_active

            e.preventDefault()

            if Math.abs(e.pageX - __drag_start_x) > __drag_tolerance \
            or Math.abs(e.pageY - __drag_start_y) > __drag_tolerance

              # Set val!
              $(__drag_target).val __drag_orig_val + (e.pageX - __drag_start_x)

            return false

        $(document).mouseup ->
          __drag_sys_active = false
          __drag_target = null
          $("body").css "cursor", "auto"

  # Called either externally, or when our save button is clicked. The
  # clicked object is passed in as our 'clicked'
  #
  # @param [Object] clicked clicked object
  save: (clicked) ->
    param.required clicked

    if @_curObject == null
      AUtilLog.warn "Save requested with no associated object!"
      return

    # Iterate over each parent control, calling our @saveControl method
    me = @
    $(clicked).parent().find(".asp-control-group > .asp-control").each ->
      me.saveControl @

  # Called either externally, or when a control is changed and preview is
  # enabled. This method applies the state of the control to our current object
  #
  # Internally, we just build an object of property:value pairs, and then
  # pass it to the object we are representing, at which points it uses the
  # values how it sees fit. For composites, we loop through and do the
  # same for each sub control, and just add those as an object on the composite
  #
  # @param [Object] control control to save
  saveControl: (control, _recurse) ->
    param.required control

    if @_curObject == null
      AUtilLog.warn "Save requested with no associated object!"
      return

    # Note that we have an undocumented parameter! When _recurse is et to true,
    # that signifies that we have been called by ourselves. Knowing this, we
    # will return our results instead of shipping them to the object.
    _recurse = param.optional _recurse, false

    type = $(control).attr "data-type"

    # Saves space below, expects a single result, throws an error otherwise
    #
    # @param [Object] result jquery element search result
    # @param [String] type type of what we are looking for, used in messages
    # @return [Boolean] success true if there is a single result
    _formatCheck = (result, type) ->
      if result.length == 0
        AUtilLog.error "No #{type} found! #{control}"
        return false
      else if result.length > 1
        AUtilLog.error "Too many of type #{type} found! #{control}"
        return false
      true

    _valCheck = (value) -> _formatCheck value, "value"
    _labelCheck = (label) -> _formatCheck label, "label"

    # This is what we pass to our current object in the end, at which point
    # it does as it pleases with the values
    _retValues = {}

    # All field types have a label
    # NOTE: We don't break out the value as well, since not all fields use
    #       the same element for value manipulation. select/input/textarea/etc
    label = $(control).find "> label"

    # Integrity check, bail if necessary
    if not _labelCheck(label) then return

    # Pull out the actual label
    label = $(label[0]).attr("data-name")

    # Standard input field .val()
    if type == "number" or type == "text"
      value = $(control).find "> input"

      # Verify integrity, then ship
      if _valCheck value
        if type == "number"
          _retValues[label] = Number($(value[0]).val())
        else
          _retValues[label] = $(value[0]).val()

    # Still an input field, but requires .is() to check
    else if type == "bool"
      value = $(control).find "> input"

      if _valCheck value
        _retValues[label] = $(value[0]).is ":checked"

    # For composites, we just recurse for each individual control, and build
    # our result set out of that.
    else if type == "composite"
      _subControls = $(control).find(".asp-control")

      # Set up object
      _retValues[label] = {}

      # Merge results with our own collection
      for c in _subControls
        $.extend _retValues[label], @saveControl(c, true)

    # If we are recursing, just return what we've parsed so far
    if _recurse
      return _retValues
    else

      # Ship the results to our object
      @_curObject.updateProperties _retValues

  # Refresh widget data using a manipulatable, not that this function is
  # not where injection occurs! We request a refresh from our parent for that
  #
  # @param [AHandle] obj
  refresh: (obj) ->
    @_curObject = param.required obj

    properties = obj.getProperties()

    # Generate html to inject
    @_builtHMTL = "<ul id=\"#{@_id}\" class=\"as-properties\">"

    for p of properties
      _controlHTML = @_generateControl p, properties[p]
      @_builtHMTL += "<li class=\"asp-control-group\">#{_controlHTML}</li>"

    @_builtHMTL += "<button class=\"asp-save\">Save</button>"
    @_builtHMTL += "</ul>"

    @_parent.render()

  # Clear the property widget
  clear: ->
    @_builtHMTL = ""
    @_curObject = null
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

    # We might capitalize the first letter of the name for display purposes,
    # make a new var for this so we keep track of the original name
    displayName = name

    # Capitalize first letter if appropriate
    if name.length > 3
      displayName = name.charAt(0).toUpperCase() + name.substring 1

    _html =  ""
    _html += "<div data-type=\"#{value.type}\" class=\"asp-control\">"

    # Iterate
    if value.type == "composite"
      param.required value.components
      _data = "data-name=\"#{name}\""
      _class = "class=\"aspc-composite-name\""

      _html += "<label #{_data} #{_class} >#{displayName}</label>"

      # Update component values
      value.getValue()

      # Build the control by recursing and concating the result
      for p of value.components
        _html += @_generateControl p, value.components[p], true

    else

      # Generate a unique name for the input, to properly target its' label
      _inputName = prefId "aspc"
      _opts = "data-name=\"#{name}\""

      # Give ourselves the drag_mod class, for drag manipulation
      if value.type == "number" then _opts += " class=\"drag_mod\""

      _html += "<label #{_opts} for=\"#{_inputName}\">#{displayName}</label>"

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
        _html +=   "placeholder=\"#{value.default}\" "
        _html +=   "value=\"#{value.getValue()}\" "
        _html += " />"

      else if value.type == "bool"

        if value.default == undefined then value.default = false

        _html += "<input "
        _html +=   "name=\"#{_inputName}\" "
        _html +=   "type=\"checkbox\" "
        _html +=   "data-control=\"bool\" "
        _html +=   value.getValue() ? "checked " : ""
        _html += " />"

      else if value.type == "text"

        if value.default == undefined then value.default = ""

        _html += "<input "
        _html +=   "name=\"#{_inputName}\" "
        _html +=   "type=\"text\" "
        _html +=   "data-control=\"text\" "
        _html +=   "placeholder=\"#{value.default}\" "
        _html +=   "value=\"#{value.getValue()}\" "
        _html += " />"

      else
        AUtilLog.warn "Unrecognized property type #{value.type}"

    if not __recurse and value.preview
      _html += "<div class=\"aspc-preview\">"
      _html +=   "<label for=\"preview-#{name}\">Preview</label>"
      _html +=   "<input name=\"preview-#{name}\" type=\"checkbox\">"
      _html += "</div>"

    _html += "</div>"
