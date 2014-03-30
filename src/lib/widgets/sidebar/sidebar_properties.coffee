define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Tab = require "widgets/tabs/tab"

  NumericControlTemplate = require "templates/sidebar/controls/numeric"
  BooleanControlTemplate = require "templates/sidebar/controls/boolean"
  TextControlTemplate = require "templates/sidebar/controls/text"

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

      @targetActor = null
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
      $(document).on "input", "dl > dd > input", (e) =>
        @saveControl e.target

        # @ui.pushEvent "actor.property.change",
        #   property: $(e.target).find("input")[0]
        #   value: $(e.target).val()

      $(document).on "mousedown", "input[type=number]", (e) ->

        # Attempt to find a valid target input
        __drag_target = e.target

        # Store initial cursor position
        __drag_start_x = e.pageX
        __drag_start_y = e.pageY

        # Store our target's value
        __drag_orig_val = Number($(__drag_target).val())

        # Enable mousemove listener
        __drag_sys_active = true

        setTimeout ->
          if __drag_target
            $(__drag_target).css "cursor", "e-resize"
        , 100

      # The following are global listeners, since mouseup and mousemove can
      # happen anywhere on the page, yet still relate to us
      $(document).mousemove (e) =>
        return unless __drag_sys_active

        if Math.abs(e.pageX - __drag_start_x) > __drag_tolerance \
        or Math.abs(e.pageY - __drag_start_y) > __drag_tolerance

          # Set val!
          $(__drag_target).val __drag_orig_val + (e.pageX - __drag_start_x)

          @saveControl $(__drag_target)[0]

      $(document).mouseup (e) ->
        $(__drag_target).css "cursor", "auto"
        __drag_sys_active = false
        __drag_target = null

    ###
    # This method applies the state of the control to our current object, by
    # parsing its value and calling updateProperties() on the current object.
    #
    # For composites, we loop through and do the same for each sub control, and
    # just add those as an object on the composite.
    #
    # @param [Object] control input field to save
    # @param [Boolean] apply if false, returns results without applying
    ###
    saveControl: (control, apply) ->
      param.required control
      apply = param.optional apply, true

      return unless @targetActor

      propType = $(control).attr "type"
      propName = $(control).attr "name"

      parsedProperties = {}
      parsedProperties[propName] =
        parent: $(control).attr "data-parent"
        value: null

      # Standard input field .val()
      if propType == "number" or propType == "text"
        value = $(control).val()

        if propType == "number"
          value = Number value

          _pOffX = (@ui.workspace.getCanvasWidth() - @ui.workspace.getPhoneWidth())/2
          _pOffY = @ui.workspace.getCanvasHeight() - @ui.workspace.getPhoneHeight()-35

          if propName == "x"
            parsedProperties[propName].value = value + _pOffX
          else if propName == "y"
            parsedProperties[propName].value  = value + _pOffY
          else
            parsedProperties[propName].value  = value

        else
          parsedProperties[propName].value  = value

      # Still an input field, but requires .is() to check
      else if propType == "checkbox"
        value = $(control).is ":checked"

        parsedProperties[propName].value  = value

      ###

      # For composites, we just recurse for each individual control, and build
      # our result set out of that.
      else if propType == "composite"
        _subControls = $(control).find(".control")

        # Set up object
        parsedProperties[propName] = {}

        # Merge results with our own collection
        for c in _subControls
          $.extend parsedProperties[propName], @saveControl(c, true)

      ###

      unless apply
        parsedProperties
      else
        @targetActor.updateProperties parsedProperties

    ###
    # Generates a mini HTML control widget for the property in question
    #
    # @param [String] name
    # @param [Object] value
    # @return [String] html rendered widget
    # @private
    ###
    generateControl: (name, value) ->
      param.required name
      param.required value
      param.required value.type

      return unless @["renderControl_#{value.type}"]

      @["renderControl_#{value.type}"] @prepareNameForDisplay(name), value

    ###
    # Capitalize first letter of name
    #
    # @param [String] name
    # @return [String] displayName
    ###
    prepareNameForDisplay: (name) ->
      name.charAt(0).toUpperCase() + name.substring 1

    renderControl_composite: (displayName, value) ->
      param.required value.components

      # TODO: Document/rename/refactor this method call
      value.getValue()

      label = "<h1>#{displayName}</h1>"

      # Build the control by recursing and concating the result
      label + _.pairs(value.components).map (component) =>
        return "" unless @["renderControl_#{component[1].type}"]

        # Note that we handle the "Basic" composite differently here
        if _.keys(value.components).length <= 3 and displayName != "Basic"
          width = "#{100 / _.keys(value.components).length}%"
        else
          width = "100%"

        name = @prepareNameForDisplay component[0]
        type = component[1].type

        unless displayName == "Basic"
          parent = displayName.toLowerCase()
        else
          parent = ""

        @["renderControl_#{type}"] name, component[1], width, parent

      .join ""

    renderControl_number: (displayName, value, width, parent) ->
      width = param.optional width, "100%"
      parent = param.optional parent, false

      value.max = param.optional value.max, Infinity
      value.min = param.optional value.min, -Infinity
      value.default = param.optional value.default, ""
      value.float = param.optional value.float, false

      NumericControlTemplate
        name: displayName
        max: value.max
        min: value.min
        float: value.float
        placeholder: value.default
        value: value.getValue()
        width: width
        parent: parent

    renderControl_bool: (displayName, value, width, parent) ->
      width = param.optional width, "100%"
      parent = param.optional parent, false

      BooleanControlTemplate
        name: displayName
        value: value.getValue()
        width: width
        parent: parent

    renderControl_text: (displayName, value, width, parent) ->
      width = param.optional width, "100%"
      value.default = param.optional value.default, ""
      parent = param.optional parent, false

      TextControlTemplate
        name: displayName
        placeholder: value.default
        value: value.getValue()
        parent: parent

    ###
    # Refresh widget data using a manipulatable, not that this function is
    # not where injection occurs! We request a refresh from our parent for that
    #
    # @param [Handle] obj
    ###
    refresh: (obj) ->
      @targetActor = param.required obj

      properties = _.pairs obj.getProperties()

      # Bring together all non-composites and render them under the "Basic"
      # label
      nonComposites = _.filter properties, (p) -> p[1].type != "composite"
      composites = _.filter properties, (p) -> p[1].type == "composite"

      if nonComposites.length > 0
        fakeControl =
          type: "composite"
          components: _.object nonComposites
          getValue: ->
            c.getValue() for c in @components

        nonCompositeHTML = @generateControl "basic", fakeControl
      else
        nonCompositeHTML = ""

      compositeHTML = composites.map (p) =>
        @generateControl p[0], p[1]
      .join ""

      @_builtHMTL = nonCompositeHTML + compositeHTML

      @getSidebar().render()

    ###
    # Clear the property widget
    ###
    clear: ->
      @_builtHMTL = ""
      @targetActor = null
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
        if @targetActor then return @targetActor.getActorId()

      null

    ###
    # @param [BaseActor] actor
    ###
    updateActor: (actor) ->
      @targetActor = param.required actor

      @refresh actor unless @_builtHMTL

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

      physics = properties["physics"]
      physics.getValue()
      @getElement("#physics #enabled input").val physics.components.enabled.getValue()
      @getElement("#physics #mass input").val physics.components.mass.getValue()
      @getElement("#physics #elasticity input").val physics.components.elasticity.getValue()
      @getElement("#physics #friction input").val physics.components.friction.getValue()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      if type == "selected.actor"
        @updateActor params.actor
