define (require) ->

  config = require "config"
  param = require "util/param"
  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  ID = require "util/id"
  Widget = require "widgets/widget"

  CompositeProperty = require "handles/properties/composite"

  Dragger = require "util/dragger"

  TemplatePropertyBar = require "templates/property_bar"
  TemplateBooleanControl = require "templates/sidebar/controls/boolean"
  TemplateCompositeControl = require "templates/sidebar/controls/composite"
  TemplateNumericControl = require "templates/sidebar/controls/numeric"
  TemplateTextControl = require "templates/sidebar/controls/text"

  ###
  # Property bar, breaks out settings and high-level editor controls
  ###
  class PropertyBar extends Widget

    ###
    # Prevents us from binding event listeners twice
    # @type [Boolean]
    ###
    @__exists: false

    ###
    # @param [UI] ui
    ###
    constructor: (@ui, options) ->
      return unless @enforceSingleton()

      super @ui,
        id: ID.prefID("property-bar")
        classes: ["property-bar"]
        parent: "header"

      # We cache our internal built state, since we require an object to show
      # anything meaningful. Our state is refreshed externally, after which
      # we save the HTML in this property, request a render from our parent,
      # and then pass it down once our parent responds
      @_builtHMTL = ""

      # Automatically register self as the default properties widget if none yet
      # exists
      $("body").data "default-properties", @

      @targetActor = null

      @registerInputListener()
      @setupDragger()

    ###
    # Checks if a property bar has already been created
    ###
    enforceSingleton: ->
      if PropertyBar.__exists
        AUtilLog.warn "A property bar already exists, refusing to initialize!"
        return false

      PropertyBar.__exists = true

    ###
    # Initialize our input dragging functionality
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

      $(document).on "change", "#{@_sel} .control > input", (e) =>
        @saveControl e.target
        @ui.pushEvent "property.bar.update.actor", actor: @targetActor

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

      value = null
      parent = $(control).attr "data-parent"

      if propType == "number"
        value = Number $(control).val()
      else if propType == "text"
        value  = $(control).val()
      else if propType == "checkbox"
        value = $(control).is ":checked"

      updatePacket = {}

      if $(control).attr "data-parent"
        updatePacket[parent] = {}
        updatePacket[parent][propName] = value
      else
        updatePacket[propName] = value

      unless apply
        updatePacket
      else
        @targetActor.updateProperties updatePacket

    ###
    # Refresh widget data using a manipulatable, not that this function is
    # not where injection occurs! We request a refresh from our parent for that
    #
    # @param [Handle] obj
    ###
    refreshActor: (obj) ->
      @targetActor = param.required obj

      properties = _.pairs obj.getProperties()

      # Bring together all non-composites and render them under the "Basic"
      # label
      nonComposites = _.filter properties, (p) ->
        p[1].getType() != "composite" and p[1].showInToolbar()

      composites = _.filter properties, (p) ->
        p[1].getType() == "composite" and p[1].showInToolbar()

      if nonComposites.length > 0
        fakeControl = new CompositeProperty()
        fakeControl.setProperties _.object nonComposites

        nonCompositeHTML = @generateControl
          name: "basic"
          icon: config.icon.property_basic
        , fakeControl
      else
        nonCompositeHTML = ""

      compositeHTML = composites.map (p) =>
        name = p[0]
        property = p[1]
        icn = config.icon.property_default
        icn = property.icon if property.icon

        @generateControl { name: name, icon: icn }, property

      compositeHTML.unshift nonCompositeHTML

      @getElement().html TemplatePropertyBar
        controls: compositeHTML
        actorName: @targetActor.getName()

    ###
    # Clear the property widget
    ###
    clear: ->
      @_builtHMTL = ""
      @targetActor = null
      @getElement().html ""

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
      oldActor = @targetActor
      @targetActor = param.optional actor, @targetActor
      return unless @targetActor

      if !@_builtHMTL || (@targetActor != oldActor)
        return @refreshActor @targetActor

      for property, value of @targetActor.getProperties()

        if value.getType() == "composite"
          parent = "h1[data-name=#{property}]"
        else
          parent = "h1[data-name=basic]"

        if value.getType() == "composite"
          for cName, cValue of value.getProperties()

            input = $("#{@_sel} #{parent} + div > dl input[name=#{cName}]")
            value = cValue.getValueString()

            $(input).val value

        else
          input = $("#{@_sel} #{parent} + div > dl input[name=#{property}]")
          value = value.getValueString()

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
      AUtilEventLog.egot "tab.properties", type
      switch type
        when "workspace.selected.actor", "timeline.selected.actor", "workspace.add.actor"
          @updateActor params.actor
        when "workspace.remove.actor"
          @clearActor params.actor
        when "selected.actor.update"
          @updateActor params.actor

    ###
    #
    # Control rendering
    #
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
      param.optional data.icon, config.icon.property_default
      param.required value
      param.required value.getType(), ["composite"]

      return unless @["renderControl_#{value.getType()}"]

      ndata =
        name: @prepareNameForDisplay(data.name)
        icon: data.icon

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
      displayIcon = param.optional data.icon, config.icon.property_default

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
          return "" unless component[1].showInToolbar()

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
      width = param.optional data.width, "100%"
      parent = param.optional data.parent, false

      TemplateNumericControl
        displayName: displayName
        name: displayName.toLowerCase()
        max: value.getMax()
        min: value.getMin()
        float: value.getFloat()
        placeholder: value.getPlaceholder()
        value: value.getValueString()
        width: width
        parent: parent

    renderControl_boolean: (data, value) ->
      value = param.required value
      displayName = param.required data.name
      width = param.optional data.width, "100%"
      parent = param.optional data.parent, false

      TemplateBooleanControl
        displayName: displayName
        name: displayName.toLowerCase()
        value: value.getValue()
        width: width
        parent: parent

    renderControl_text: (data, value) ->
      value = param.required value
      displayName = param.required data.name
      width = param.optional data.width, "100%"
      parent = param.optional data.parent, false

      TemplateTextControl
        displayName: displayName
        name: displayName.toLowerCase()
        placeholder: value.getPlaceholder()
        value: value.getValueString()
        parent: parent
