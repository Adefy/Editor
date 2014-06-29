define (require) ->

  config = require "config"
  param = require "util/param"
  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  ID = require "util/id"

  Widget = require "widgets/widget"
  Storage = require "storage"
  config = require "config"
  Dragger = require "util/dragger"
  CompositeProperty = require "handles/properties/composite"

  TemplateSidebar = require "templates/sidebar/sidebar"
  TemplateBooleanControl = require "templates/sidebar/controls/boolean"
  TemplateCompositeControl = require "templates/sidebar/controls/composite"
  TemplateNumericControl = require "templates/sidebar/controls/numeric"
  TemplateTextControl = require "templates/sidebar/controls/text"

  class Sidebar extends Widget

    ###
    # Creates a new sidebar with a given origin. The element's id is randomized
    # to sbar + Math.floor(Math.random() * 1000)
    #
    # @param [UIManager] ui
    ###
    constructor: (@ui) ->

      super @ui,
        id: ID.prefID("sidebar")
        parent: config.selector.content
        classes: ["sidebar"]

      @_cachedHTML =  null
      @_tagetActor = null
      @_hiddenX = 0
      @_visibleX = 0
      @_visible = !!Storage.get("sidebar.visible")

      @setWidth 250
      @_bindToggle()

      @registerInputListener()
      @setupDragger()

      # At this point, this just sets up our cached HTML. No element exists yet,
      # so it doesn't render us directly
      @setNewTargetActor null

      if @_visible
        @show()
      else
        @hide()

    ###
    # Since we are updated live without a full refresh and inject generated HTML
    # immediately, we have to cache it for when the render method is actually
    # called (aka, after we are first created).
    #
    # @return [String] html
    ###
    render: ->
      @_cachedHTML

    ###
    # Set up our ability to modify numeric input values by dragging horizontally
    # @private
    ###
    setupDragger: ->
      @dragger = new Dragger "#{@_sel} input[type=number]"

      @dragger.setOnDragStart (d) ->
        d.setUserData initialValue: Number $(d.getTarget()).val()
        $(d.getTarget()).css "cursor", "e-resize"

      @dragger.setOnDrag (d, deltaX, deltaY) =>
        $(d.getTarget()).val d.getUserData().initialValue + deltaX
        @saveControl $(d.getTarget())[0]

      @dragger.setOnDragEnd (d) ->
        $(d.getTarget()).css "cursor", "auto"

    ###
    # @private
    ###
    registerInputListener: ->
      $(document).on "change", "#{@_sel} .sb-control > input", (e) =>
        @saveControl e.target
        @ui.pushEvent "sidebar.update.actor", actor: @_targetActor

    ###
    # @private
    ###
    _bindToggle: ->
      $(document).on "click", "#{@getSel()} .button.toggle", ->

        # Find the affected sidebar
        selector = @attributes["data-sidebarid"].value
        sidebar = $("body").data "##{selector}"

        sidebar.toggle()

    ###
    # Clear the property widget
    ###
    clear: ->
      @_targetActor = null
      @getElement().html ""

    ###
    # Clear ourselves only if the supplied actor matches our target actor
    #
    # @param [BaseActor] actor
    ###
    clearActor: (actor) ->
      if actor && @_targetActor
        if actor.getActorId() == @_targetActor.getActorId()
          @clear()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      AUtilEventLog.egot "sidebar", type

      switch type
        when "workspace.selected.actor" then @updateActor params.actor
        when "timeline.selected.actor" then @updateActor params.actor
        when "workspace.add.actor" then @updateActor params.actor
        when "workspace.remove.actor" then @clearActor params.actor
        when "selected.actor.update" then @updateActor params.actor

    ###
    ###
    ## Control update logic
    ###
    ###

    ###
    # This method updates an actor property using the provided input, if
    # possible. If the input is in the left column, we manually perform a direct
    # update. Otherwise, we try to match up the input with a property and send
    # the value over accordingly.
    #
    # @param [Object] control input field to save
    # @param [Boolean] apply if false, returns results without applying
    ###
    saveControl: (control, apply) ->
      param.required control
      apply = !!apply

      return unless $(control).parent().hasClass "sb-control"
      return unless @_targetActor

      propertyId = $(control).parent().attr "data-id"
      propertyParentUL = $(control).closest "ul"
      value = Number $(control).val()

      # Direct update
      if propertyParentUL.hasClass "sb-controls-left"

        switch propertyId
          when "position-x"
            @_targetActor.getProperties().position.x.setValue value
          when "position-y"
            @_targetActor.getProperties().position.y.setValue value
          when "rotation"
            @_targetActor.getProperties().rotation.setValue value

      # Custom control, match it up
      else if propertyParentUL.hasClass "sb-controls-right"

        actorProperty = @_targetActor.getProperties()[propertyId]
        actorProperty.setValue value if actorProperty

    ###
    # Rebuild controls and update everything necessary to re-target sidebar
    #
    # @param [Handle] actor
    ###
    setNewTargetActor: (actor) ->

      if actor
        @_targetActor = actor

        # The only custom controls we render are numeric, and we display them
        # in the right input column. Everything else is handled by generic sidebar
        # functionality (appearance, etc)
        properties = _.filter _.pairs(actor.getProperties()), (p) ->
          p[1].showInSidebar() && p[1].getType() == "number"

        renderableData = properties.map (p) ->
          {
            name: p[0]
            min: p[1].getMin()
            max: p[1].getMax()
            float: p[1].getFloat()
            placeholder: p[1].getPlaceholder()
            icon: config.icon.property_basic
            value: p[1].getValue()
          }

        data =
          controls: renderableData
          actorName: @_targetActor.getName()

      else
        data = null

      # We cache the result for later calls to @render()
      @_cachedHTML = TemplateSidebar data
      @getElement().html @_cachedHTML

      # We need to perform a refresh anyways, to update the rest of the sidebar
      @refreshInputValues()

    ###
    # Update target actor. An in-place refresh is made if the actor is already
    # our target actor, otherwise the sidebar is fully updated.
    #
    # @param [BaseActor] actor
    ###
    updateActor: (actor) ->
      if @_targetActor != actor
        @setNewTargetActor actor
      else
        @refreshInputValues()

    ###
    # Pull in new input values from our target actor
    ###
    refreshInputValues: ->
      return unless !!@_targetActor
      @_refreshRawInputs()

    _refreshRawInputs: ->
      properties = @_targetActor.getProperties()

      # Refresh left inputs
      position = properties.position.getValue()
      rotation = properties.rotation.getValue()

      $("#{@getSel()} .sb-controls-left .sb-control[data-id=position-x] input").val position.x
      $("#{@getSel()} .sb-controls-left .sb-control[data-id=position-y] input").val position.y
      $("#{@getSel()} .sb-controls-left .sb-control[data-id=rotation] input").val rotation

      # Refresh right (custom) inputs
      for input in $("#{@getSel()} .sb-controls-right input")
        if properties[$(input).attr "data-id"]
          $(input).val properties[$(input).attr "data-id"].getValue()

    ###
    ###
    ## Control rendering logic
    ###
    ###

    ###
    # Generates a mini HTML control widget for the property in question
    #
    # @param [String] name
    # @param [Object] value
    # @return [String] html rendered widget
    # @private
    ###
    generateControl: (data, value) ->
      param.required data
      param.required data.name
      param.required value
      param.required value.getType(), ["composite"]

      return unless @["renderControl_#{value.getType()}"]

      ndata =
        name: @prepareNameForDisplay(data.name)
        icon: data.icon or config.icon.property_default

      @["renderControl_#{value.getType()}"] ndata, value

    ###
    # Capitalize first letter of name
    #
    # @param [String] name
    # @return [String] displayName
    ###
    prepareNameForDisplay: (name) ->
      name.charAt(0).toUpperCase() + name.substring 1

    renderControl_composite: (data, value) ->
      param.required data

      displayName = param.required data.name
      displayIcon = data.icon or config.icon.property_default

      param.required value.getType(), ["composite"]

      # Build the control by recursing and concating the result
      properties = value.getProperties()
      batches = [[]]
      batch_i = 0

      for property in _.pairs(properties)
        if property[1].getType() == "composite"
          if batches[batch_i].length > 0
            batches[++batch_i] = []
          batches[batch_i].push property
          batches[++batch_i] = []
        else
          batches[batch_i].push property

      contents = batches.map (batch) =>
        batch.map (component) =>
          name = @prepareNameForDisplay component[0]
          type = component[1].getType()

          return "" unless @["renderControl_#{type}"]
          return "" unless component[1].showInSidebar()

          # Note that we handle the "Basic" composite differently here
          componentCount = batch.length
          if componentCount <= 3 and displayName.toLowerCase() != "basic"
            width = "#{100 / batch.length}%"
          else
            width = "100%"

          unless displayName.toLowerCase() == "basic"
            parent = displayName.toLowerCase()
          else
            parent = ""

          @["renderControl_#{type}"]
            name: name
            width: width
            parent: parent
          , component[1]

        .join("")
      .join("")

      TemplateCompositeControl
        icon: displayIcon
        displayName: displayName
        dataName: displayName.toLowerCase()
        contents: contents

    renderControl_number: (data, value) ->
      value = param.required value
      displayName = param.required data.name

      TemplateNumericControl
        displayName: displayName
        name: displayName.toLowerCase()
        max: value.getMax()
        min: value.getMin()
        float: value.getFloat()
        placeholder: value.getPlaceholder()
        value: value.getValueString()
        width: data.width or "100%"
        parent: data.parent or false

    renderControl_boolean: (data, value) ->
      value = param.required value
      displayName = param.required data.name

      TemplateBooleanControl
        displayName: displayName
        name: displayName.toLowerCase()
        value: value.getValue()
        width: data.width or "100%"
        parent: data.parent or false

    renderControl_text: (data, value) ->
      value = param.required value
      displayName = param.required data.name

      TemplateTextControl
        displayName: displayName
        name: displayName.toLowerCase()
        placeholder: value.getPlaceholder()
        value: value.getValueString()
        parent: data.parent or false

    ###
    ###
    ## Generic sidebar functionality after this point
    ###
    ###

    ###
    # Set sidebar width, sets internal offset values
    #
    # @param [Number] width
    ###
    setWidth: (width) ->
      elem = @getElement()
      elem.width width
      @_width = elem.width()
      @_hiddenX = -(@_width - 40)
      @_visibleX = 0

    ###
    # Refreshes the state of the timeline toggle icons and storage
    ###
    refreshVisible: ->
      Storage.set "sidebar.visible", @_visible
      @getElement(".button.toggle i").toggleClass config.icon.toggle_left, @_visible
      @getElement(".button.toggle i").toggleClass config.icon.toggle_right, !@_visible

    ###
    # Toggle visibility of the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to false
    ###
    toggle: (cb, animate) ->
      animate = false unless animate

      if @_visible
        @hide cb, animate
      else
        @show cb, animate

    ###
    # Show the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to true
    ###
    show: (cb, animate) ->
      animate = false unless animate

      if @_visible
        cb() if cb
        return

      if animate
        @getElement().animate left: @_visibleX, 300, cb
      else
        @getElement().css left: @_visibleX
        cb() if cb

      @_visible = true
      @refreshVisible()

    ###
    # Hide the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to true
    ###
    hide: (cb, animate) ->
      animate = false unless animate

      unless @_visible
        cb() if cb
        return

      if animate
        @getElement().animate left: @_hiddenX , 300, cb
      else
        @getElement().css left: @_hiddenX
        cb() if cb

      @_visible = false
      @refreshVisible()
