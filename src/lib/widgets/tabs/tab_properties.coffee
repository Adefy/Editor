define (require) ->

  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"
  ID = require "util/id"
  Tab = require "widgets/tabs/tab"

  TemplateBooleanControl = require "templates/sidebar/controls/boolean"
  TemplateCompositeControl = require "templates/sidebar/controls/composite"
  TemplateNumericControl = require "templates/sidebar/controls/numeric"
  TemplateTextControl = require "templates/sidebar/controls/text"

  CompositeProperty = require "handles/properties/composite"

  Dragger = require "util/dragger"

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

      @registerInputListener()
      @setupDragger()

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

      $(document).on "input", "dl > dd > input", (e) =>
        @saveControl e.target
        @ui.pushEvent "tab.properties.update.actor", actor: @targetActor

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
      param.optional data.icon, "fa-cog"
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
      param.required data.name
      param.optional data.icon, "fa-cog"

      displayName = data.name
      displayIcon = data.icon

      param.required value.getType(), ["composite"]

      # Build the control by recursing and concating the result
      contents = _.pairs(value.getProperties()).map (component) =>
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

      .join("")

      TemplateCompositeControl
        icon: displayIcon
        name: displayName
        dataName: displayName.toLowerCase()
        contents: contents

    renderControl_number: (displayName, value, width, parent) ->
      width = param.optional width, "100%"
      parent = param.optional parent, false

      TemplateNumericControl
        displayName: displayName
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

      TemplateBooleanControl
        displayName: displayName
        name: displayName.toLowerCase()
        value: value.getValue()
        width: width
        parent: parent

    renderControl_text: (displayName, value, width, parent) ->
      width = param.optional width, "100%"
      parent = param.optional parent, false

      TemplateTextControl
        displayName: displayName
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

        nonCompositeHTML = @generateControl { name: "basic", icon: "fa-cog"}, fakeControl
      else
        nonCompositeHTML = ""

      compositeHTML = composites.map (p) =>
        icn = "fa-cog"
        name = p[0]
        # wtf hax
        switch name
          when "basic"    then icn = "fa-cog"
          when "color"    then icn = "fa-adjust"
          when "physics"  then icn = "fa-anchor"
          when "position" then icn = "fa-arrows"

        @generateControl { name: name, icon: icn }, p[1]
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
      oldActor = @targetActor
      @targetActor = param.optional actor, @targetActor
      return unless @targetActor

      if !@_builtHMTL || (@targetActor != oldActor)
        return @refresh @targetActor

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
      AUtilEventLog.egot "tab.properties", type
      switch type
        when "workspace.selected.actor", "timeline.selected.actor", "workspace.add.actor"
          @updateActor params.actor
        when "workspace.remove.actor"
          @clearActor params.actor
        when "selected.actor.changed"
          @updateActor()
