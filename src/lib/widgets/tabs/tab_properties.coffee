define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Tab = require "widgets/tabs/tab"

  NumericControlTemplate = require "templates/sidebar/controls/numeric"
  BooleanControlTemplate = require "templates/sidebar/controls/boolean"
  TextControlTemplate = require "templates/sidebar/controls/text"

  CompositeProperty = require "handles/properties/composite"

  ###
  # Properties widget, dynamically refreshable
  ###
  class PropertiesTab extends Tab

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
      if PropertiesTab.__exists
        AUtilLog.warn "A properties tab already exists, refusing to initialize!"
        return false

      PropertiesTab.__exists = true

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
        @ui.pushEvent "tab.properties.update.actor", actor: @targetActor

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

      if propType == "number"
        parsedProperties[propName].value = Number $(control).val()
      else if propType == "text"
        parsedProperties[propName].value  = $(control).val()
      else if propType == "checkbox"
        parsedProperties[propName].value = $(control).is ":checked"

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
      param.required value.getType(), ["composite"]

      return unless @["renderControl_#{value.getType()}"]

      @["renderControl_#{value.getType()}"] @prepareNameForDisplay(name), value

    ###
    # Capitalize first letter of name
    #
    # @param [String] name
    # @return [String] displayName
    ###
    prepareNameForDisplay: (name) ->
      name.charAt(0).toUpperCase() + name.substring 1

    renderControl_composite: (displayName, value) ->
      param.required value.getType(), ["composite"]

      label = """
        <h1 data-name="#{displayName.toLowerCase()}">#{displayName}</h1>
        <div>
      """

      # Build the control by recursing and concating the result
      label + _.pairs(value.getProperties()).map (component) =>
        return "" unless @["renderControl_#{component[1].getType()}"]

        # Note that we handle the "Basic" composite differently here
        componentCount = _.keys(value.getProperties()).length
        if componentCount <= 3 and displayName.toLowerCase() != "basic"
          width = "#{100 / _.keys(value.getProperties()).length}%"
        else
          width = "100%"

        name = @prepareNameForDisplay component[0]
        type = component[1].getType()

        unless displayName.toLowerCase() == "basic"
          parent = displayName.toLowerCase()
        else
          parent = ""

        @["renderControl_#{type}"] name, component[1], width, parent

      .join("") + "</div>"

    renderControl_number: (displayName, value, width, parent) ->
      width = param.optional width, "100%"
      parent = param.optional parent, false

      NumericControlTemplate
        name: displayName.toLowerCase()
        max: value.getMax()
        min: value.getMin()
        float: value.getFloat()
        placeholder: value.getPlaceholder()
        value: value.getValue()
        width: width
        parent: parent

    renderControl_bool: (displayName, value, width, parent) ->
      width = param.optional width, "100%"
      parent = param.optional parent, false

      BooleanControlTemplate
        name: displayName.toLowerCase()
        value: value.getValue()
        width: width
        parent: parent

    renderControl_text: (displayName, value, width, parent) ->
      width = param.optional width, "100%"
      parent = param.optional parent, false

      TextControlTemplate
        name: displayName.toLowerCase()
        placeholder: value.getPlaceholder()
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
      nonComposites = _.filter properties, (p) -> p[1].getType() != "composite"
      composites = _.filter properties, (p) -> p[1].getType() == "composite"

      if nonComposites.length > 0
        fakeControl = new CompositeProperty()
        fakeControl.setProperties _.object nonComposites

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
    # @param [BaseActor] actor
    ###
    updateActor: (actor) ->
      @targetActor = param.optional actor, @targetActor
      return unless @targetActor

      return @refresh @targetActor unless @_builtHMTL

      for property, value of @targetActor.getProperties()

        if value.getType() == "composite"
          parent = "h1[data-name=#{property}]"
        else
          parent = "h1[data-name=basic]"

        if value.getType() == "composite"
          for cName, cValue of value.getProperties()

            input = $("#{@_sel} #{parent} + div > dl input[name=#{cName}]")
            value = cValue.getValue()

            if $(input).attr("type") == "number"
              value = Number value

              if $(input).attr("data-float") == "true"
                value = value.toFixed 2
              else
                value = value.toFixed 0

            $(input).val value

        else
          input = $("#{@_sel} #{parent} + div > dl input[name=#{property}]")
          value = value.getValue()

          if $(input).attr("type") == "number"
            value = Number value

            if $(input).attr("data-float") == "true"
              value = value.toFixed 2
            else
              value = value.toFixed 0

          $(input).val value

    ###
    #
    ###
    clearActor: (actor) ->
      if actor && @targetActor
        if actor.getActorId() == @targetActor.getActorId()
          @clear()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      switch type
        when "workspace.selected.actor", "timeline.selected.actor", "workspace.add.actor"
          @updateActor params.actor
        when "workspace.remove.actor"
          @clearActor params.actor
        when "selected.actor.changed"
          @updateActor()
