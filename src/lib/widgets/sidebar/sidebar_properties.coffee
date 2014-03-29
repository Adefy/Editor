define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Tab = require "widgets/tabs/tab"

  NumericControlTemplate = require "templates/sidebar/controls/numeric"
  BooleanControlTemplate = require "templates/sidebar/controls/boolean"
  TextControlTemplate = require "templates/sidebar/controls/text"
  SidebarPropertiesTemplate = require "templates/sidebar/properties"

  # Properties widget, dynamically refreshable
  #
  # @depend SidebarItem.coffee
  class SidebarProperties extends Tab

    ###
    # Prevents us from binding event listeners twice
    # @type [Boolean]
    ###
    @__exists: false

    ###
    # Instantiates, but does not set data!
    #
    # @param [UIManager] ui
    # @param [Sidebar] parent sidebar parent
    ###
    constructor: (@ui, parent) ->
      return unless @enforceSingleton()

      super
        id: ID.prefId("tab-properties")
        parent: parent
        classes: ["tab-properties"]

      # We cache our internal built state, since we require an object to show
      # anything meaningful. Our state is refreshed externally, after which
      # we save the HTML in this property, request a render from our parent,
      # and then pass it down once our parent responds
      @_builtHMTL = ""

      # Automatically register self as the default properties widget if none yet
      # exists
      $("body").data "default-properties", @

      # Object that we are displaying properties for
      @_curObject = null
      @_regListeners()

    ###
    # Checks if a menu bar has already been created, and returns false if one
    # has. Otherwise, sets a flag preventing future calls from returning true
    ###
    enforceSingleton: ->
      if SidebarProperties.__exists
        AUtilLog.warn "A properties tab already exists, refusing to initialize!"
        return false

      SidebarProperties.__exists = true

    ###
    # @private
    ###
    _regListeners: ->

      # Numeric drag modification
      # This is very similar to actor dragging, see Workspace
      __drag_start_x = 0      # Keeps track of the initial drag point, so
      __drag_start_y = 0      # we know when to start listening

      __drag_target = null      # Input we need to effect
      __drag_orig_val = -1      # Value of the input when dragging started

      __drag_tolerance = 5  # How far the mouse should move before we pick up
      __drag_sys_active = false

      # Start of dragging
      $(document).on "mousedown", ".drag_mod", (e) ->

        # Attempt to find a valid target input
        __drag_target = $(@).parent().find("> input")[0]

        if __drag_target == null
          return AUtilLog.warn "Drag start on a label with no input!"

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
        false

      # The following are global listeners, since mouseup and mousemove can
      # happen anywhere on the page, yet still relate to us
      $(document).mousemove (e) =>
        return unless __drag_sys_active

        if Math.abs(e.pageX - __drag_start_x) > __drag_tolerance \
        or Math.abs(e.pageY - __drag_start_y) > __drag_tolerance

          # Set val!
          $(__drag_target).val __drag_orig_val + (e.pageX - __drag_start_x)

          @_executeLive $(__drag_target).parent().find("> input")[0]

        e.preventDefault()
        false

      $(document).mouseup ->
        __drag_sys_active = false
        __drag_target = null
        $("body").css "cursor", "auto"

      # Property update listeners, used when live is active
      $(document).on "input", ".asp-control > input", ->
        me._executeLive $(@).parent().find("> input")[0]

    ###
    # @private
    # Updates an input on change, called either as a result of a drag, or
    # manual manipulation. Only works if the input has a checked live box!
    #
    # @param [Object] input updated input
    ###
    _executeLive: (input) ->

      # Traverse upwards until we find the proper parent
      control = $(input).parent()
      while $(control).parent().hasClass("asp-control")
        control = $(control).parent()

      # Check if we have the live option, and if it is enabled
      _live = $(control).find ".aspc-live input"

      # Continue if live is checked
      if _live.length == 1
        @saveControl control if $(_live[0]).is(":checked")

    ###
    # Called either externally, or when our save button is clicked. The
    # clicked object is passed in as our 'clicked'
    #
    # @param [Object] clicked clicked object
    ###
    save: (clicked) ->
      param.required clicked

      if @_curObject == null
        AUtilLog.warn "Save requested with no associated object!"
        return

      # Iterate over each parent control, calling our @saveControl method
      me = @
      $(clicked).parent().find(".asp-control-group > .asp-control").each ->
        me.saveControl @

    ###
    # Called either externally, or when a control is changed and live is
    # enabled. This method applies the state of the control to our current object
    #
    # Internally, we just build an object of property:value pairs, and then
    # pass it to the object we are representing, at which points it uses the
    # values how it sees fit. For composites, we loop through and do the
    # same for each sub control, and just add those as an object on the composite
    #
    # @param [Object] control control to save
    ###
    saveControl: (control, _recurse) ->
      param.required control

      if @_curObject == null
        AUtilLog.warn "Save requested with no associated object!"
        return

      # Note that we have an undocumented parameter! When _recurse is set to true
      # that signifies that we have been called by ourselves. Knowing this, we
      # will return our results instead of shipping them to the object.
      _recurse = param.optional _recurse, false

      type = $(control).attr "data-type"

      ###
      # Saves space below, expects a single result, throws an error otherwise
      #
      # @param [Object] result jquery element search result
      # @param [String] type type of what we are looking for, used in messages
      # @return [Boolean] success true if there is a single result
      # @private
      ###
      _formatCheck = (result, type) ->
        if result.length == 0
          AUtilLog.error "No #{type} found! #{control}"
          false
        else if result.length > 1
          AUtilLog.error "Too many of type #{type} found! #{control}"
          false
        else
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
      return unless _labelCheck(label)

      # Pull out the actual label
      label = $(label[0]).attr("data-name")

      # Standard input field .val()
      if type == "number" or type == "text"
        value = $(control).find "> input"

        # Verify integrity, then ship
        if _valCheck value
          if type == "number"
            _pOffX = (@ui.workspace.getCanvasWidth() - @ui.workspace.getPhoneWidth())/2
            _pOffY = @ui.workspace.getCanvasHeight() - @ui.workspace.getPhoneHeight()-35
            if label == "x"
              _retValues[label] = Number($(value[0]).val()) + _pOffX
            else
              if label == "y"
                _retValues[label] = Number($(value[0]).val()) + _pOffY
              else _retValues[label] = Number($(value[0]).val())
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
      return _retValues if _recurse

      # Ship the results to our object
      @_curObject.updateProperties _retValues

    ###
    # Generates a mini HTML control widget for the property in question
    #
    # @param [String] name
    # @param [Object] value
    # @return [String] html rendered widget
    # @private
    ###
    _generateControl: (name, value, __recurse) ->
      # Note we have an extra, undocumented parameter! It is set to true when
      # the method is called by itself.
      __recurse = param.optional __recurse, false
      param.required name
      param.required value

      # We require a type to do anything
      param.required value.type

      # Capitalize first letter
      displayName = name.charAt(0).toUpperCase() + name.substring 1

      _html =  ""
      _html += "<dl id=\"#{name}\"
                    data-type=\"#{value.type}\"
                    class=\"asp-control\">"

      # Iterate
      if value.type == "composite"
        param.required value.components
        _data = "data-name=\"#{name}\""
        # _class = "class=\"aspc-composite-name\""

        _html += "<dt #{_data} >#{displayName}</dt>"

        # Update component values
        value.getValue()

        # Build the control by recursing and concating the result
        for p of value.components
          _html += @_generateControl p, value.components[p], true

      else

        # Generate a unique name for the input, to properly target its' label
        _inputName = ID.prefId "aspc"
        _opts = "data-name=\"#{name}\""

        # Give ourselves a class to notify the user of draggability on hover,
        # and prepend a drag icon
        if value.type == "number"
          _opts += " class=\"drag_mod\""
          displayName = "<i class=\"icon-resize-horizontal\"></i> #{displayName}"

        _html += "<dt #{_opts} >#{displayName}</dt>"

        # Set up optional values
        if value.max == undefined then value.max = null
        if value.min == undefined then value.min = null
        if value.live == undefined then value.live = false

        if value.type == "number"

          if value.default == undefined then value.default = 0
          if value.float == undefined then value.float = true

          if name == "x" or name == "y"
            _pOffX = (@ui.workspace.getCanvasWidth() - @ui.workspace.getPhoneWidth())/2
            _pOffY = @ui.workspace.getCanvasHeight() - @ui.workspace.getPhoneHeight()-35

          if name == "x"
            controlValue = value.getValue() - _pOffX
          else if name == "y"
            controlValue = value.getValue() - _pOffY
          else
            controlValue = value.getValue()

          _html += NumericControlTemplate
            name: _inputName
            max: value.max or Infinity
            min: value.min or -Infinity
            float: value.float or false
            placeholder: value.default or ""
            value: controlValue

        else if value.type == "bool"

          if value.default == undefined then value.default = false

          _html += BooleanControlTemplate
            name: _inputName
            value: value.getValue()

        else if value.type == "text"

          if value.default == undefined then value.default = ""

          _html += TextControlTemplate
            name: _inputName
            placeholder: value.default
            value: value.getValue()

        else
          AUtilLog.warn "Unrecognized property type #{value.type}"

      # Note that live defaults to on!
      #if not __recurse and value.live
      #  _html += "<div class=\"aspc-live\">"
      #  _html +=   "<label for=\"live-#{name}\">Live</label>"
      #  _html +=   "<input name=\"live-#{name}\" type=\"checkbox\" checked>"
      #  _html += "</div>"

      _html += "</dl>"

    ###
    # Refresh widget data using a manipulatable, not that this function is
    # not where injection occurs! We request a refresh from our parent for that
    #
    # @param [Handle] obj
    ###
    refresh: (obj) ->
      @_curObject = param.required obj

      properties = obj.getProperties()

      # Generate html to inject
      controls = []
      for p of properties
        controls.push(@_generateControl p, properties[p])

      @_builtHMTL = SidebarPropertiesTemplate controls: controls

      @getSidebar().render()

    ###
    # Clear the property widget
    ###
    clear: ->
      @_builtHMTL = ""
      @_curObject = null
      @_parent.render()

    ###
    # Return internally pre-rendered HTML. We need to pre-render since we rely
    # upon object data to be meaningful (note comment in the constructor)
    #
    # @return [String] html
    ###
    render: -> @_builtHMTL

    ###
    # The following is only meant to be called by the workspace when updating
    # object information, or objects when they die! As such, parameters are not
    # documented.
    ###
    privvyIface: (action, val1, val2) ->
      param.required action

      # "action" can either be "update_position" or "get_id"
      #
      # This can be expanded in the future, but for now it works. Note that
      # this is a tad fugly on purpose; Haveing multiple methods purely to
      # serve the workspace seems wrong, as does documenting them.
      if action == "update_position"
        _pOffX = (@ui.workspace.getCanvasWidth() - @ui.workspace.getPhoneWidth())/2
        _pOffY = @ui.workspace.getCanvasHeight() - @ui.workspace.getPhoneHeight()-35

        # Note mapping
        x = param.required val1 - _pOffX
        y = param.required val2 - _pOffY

        # We don't assume we actually have a position control, the update simply
        # doesn't occur if jquery can't find it
        #
        # Grab labels
        _xL = @getElement("label[data-name=\"x\"]")
        _yL = @getElement("label[data-name=\"y\"]")

        if _xL.length > 0 and _yL.length > 0
          $(_xL).parent().find("input")[0].value = x
          $(_yL).parent().find("input")[0].value = y

      # If we have a current object, return its' id
      else if action == "get_id"
        if @_curObject then return @_curObject.getActorId()

      null

    ###
    # @param [BaseActor] actor
    ###
    updateActor: (actor) ->
      @_curObject = param.required actor

      if !@_builtHMTL
        @refresh actor

      properties = actor.getProperties()
      pos = properties["position"]
      pos.getValue()
      @getElement("#position #x input").val pos.components.x.getValue()
      @getElement("#position #y input").val pos.components.y.getValue()

      rotation = properties["rotation"]
      @getElement("#rotation input").val rotation.getValue()

      color = properties["color"]
      color.getValue()
      @getElement("#color #r input").val color.components.r.getValue()
      @getElement("#color #g input").val color.components.g.getValue()
      @getElement("#color #b input").val color.components.b.getValue()

      psyx = properties["psyx"]
      psyx.getValue()
      @getElement("#psyx #enabled input").val psyx.components.enabled.getValue()
      @getElement("#psyx #mass input").val psyx.components.mass.getValue()
      @getElement("#psyx #elasticity input").val psyx.components.elasticity.getValue()
      @getElement("#psyx #friction input").val psyx.components.friction.getValue()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      if type == "selected.actor"
        @updateActor params.actor
