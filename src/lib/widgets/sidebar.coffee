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
  TextureLibrary = require "widgets/floating/texture_library"

  TemplateSidebar = require "templates/sidebar/sidebar"
  TemplateBooleanControl = require "templates/sidebar/controls/boolean"
  TemplateCompositeControl = require "templates/sidebar/controls/composite"
  TemplateNumericControl = require "templates/sidebar/controls/numeric"
  TemplateTextControl = require "templates/sidebar/controls/text"

  ###
  # The sidebar exposes actor properties to the user through various input
  # fields spread across multiple panels.
  #
  # Sex'ay
  ###
  class Sidebar extends Widget

    # Panel names used for show/hide/toggle commands
    @PANEL_PHYSICS: "physics"
    @PANEL_SPAWN: "spawn"
    @PANEL_APPEARANCE: "appearance"

    # Speed of animations in ms
    @ANIM_SPEED: 300

    ###
    # Sets up a new actor sidebar on the left side of the screen.
    #
    # @param [UIManager] ui
    ###
    constructor: (@ui) ->

      super @ui,
        id: ID.prefID("sidebar")
        parent: config.selector.content
        classes: ["sidebar"]

      @_cachedHTML =  null
      @_targetActor = null
      @_hiddenX = 0
      @_visibleX = 0
      @_visible = !!Storage.get("sidebar.visible")

      @setWidth 250
      @_bindListeners()

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
    # Binds listeners responsible for detecting input modifications, sidebar
    # toggling, and panel toggling.
    #
    # @private
    ###
    _bindListeners: ->
      @_bindSidebarToggle()
      @_bindInputChange()
      @_bindOpacityInput()
      @_bindAppearanceInputs()
      @_bindDraggableInputs()
      @_bindPanelControls()

    ###
    # Binds the listener responsible for toggling the visible state of the
    # sidebar. This also hides all visible panels.
    #
    # @private
    ###
    _bindSidebarToggle: ->
      # TODO: Re-implement this

    ###
    # Binds the listener responsible for reacting to input changes. This
    # includes both the main sidebar and all extension panels.
    #
    # @private
    ###
    _bindInputChange: ->
      $(document).on "change", "#{@_sel} .sb-control > input", (e) =>
        @saveControl e.target
        @ui.pushEvent "sidebar.update.actor", actor: @_targetActor

    ###
    # Binds the listeners responsible for making the compound opacity control
    # work properly. The slider and input field update when the other is
    # changed.
    #
    # @private
    ###
    _bindOpacityInput: ->
      $(document).on "change", "#{@_sel} .sb-opacity input", (e) =>
        opacity = $(e.target).val()
        isSlider = $(e.target).parent().hasClass "sb-op-slider"

        if isSlider
          $("#{@_sel} .sb-op-input").val opacity
        else
          $("#{@_sel} .sb-op-slider input").val opacity

        @_targetActor.getProperties().opacity.setValue opacity

    ###
    # Hooks up listeners for the appearance panel input fields. This includes
    # all tabs.
    #
    # @private
    ###
    _bindAppearanceInputs: ->
      apa_sel = "#{@_sel} .sb-seco-appearance"

      # Direct HTML color code input
      $(document).on "change", "#{apa_sel} .apa-tabs input", (e) =>
        value = $(e.target).val().match(/.{1,2}/g)
        return unless value.length == 3

        color =
          r: parseInt value[0], 16
          g: parseInt value[1], 16
          b: parseInt value[2], 16
        @_targetActor.setColor color.r, color.g, color.b

        @_refreshAppearance sidebar: false

      # Sliders
      $(document).on "change", "#{apa_sel} .apa-sliders input", (e) =>
        li = $(e.target).parent()
        id = li.attr "data-id"

        component = Number $(e.target).val()

        # Update the other input
        if $(e.target).attr("type") == "range"
          li.children("input[type=number]").val component
        else
          li.children("input[type=range]").val component

        # Send update to actor
        color = @_targetActor.getColor()
        color.r = component if id == "red"
        color.g = component if id == "green"
        color.b = component if id == "blue"
        @_targetActor.setColor color.r, color.g, color.b

        # Refresh only panel
        @_refreshAppearance sidebar: false

      # Mode switch
      $(document).on "change", "#{apa_sel} .onoffswitch input", (e) =>
        TextureLibrary.close()

        square = $ "#{@getSel()} .sb-seco-appearance .apa-top-sample"
        outer = $ "#{@getSel()} .sb-seco-appearance .apa-top"

        # Grab existing color/texture info
        color = @_targetActor.getColor()
        texture = _.find @ui.editor.project.textures, (texture) =>
          texture.getUID() == @_targetActor.getTextureUID()

        # Show input section
        if $(e.target).is ":checked"
          $("#{@getSel()} .apa-mode-color").hide()
          $("#{@getSel()} .apa-mode-texture").show()

          outer.removeClass "color"
          outer.addClass("texture") unless outer.hasClass "texture"
        else
          $("#{@getSel()} .apa-mode-color").show()
          $("#{@getSel()} .apa-mode-texture").hide()

          outer.removeClass "texture"
          outer.addClass("color") unless outer.hasClass "color"

        if texture
          square.css background: "#fff url(#{texture.getURL()}) cover"
        else
          square.css background: "rgb(#{color.r}, #{color.g}, #{color.b})"

      # Texture library
      $(document).on "click", "#{apa_sel} .apa-texture-button button", (e) =>

        # The library close handler resets the button
        if $(e.target).hasClass "open"
          TextureLibrary.close()
        else
          sample = $("#{apa_sel} .apa-top-sample")

          lib = new TextureLibrary @ui,
            direction: "left"
            x: $(sample).position().left + $(sample).width()
            y: $(sample).position().top + $(sample).height() / 2

          lib.setOnItemClick (item) =>
            square = $ "#{@getSel()} .sb-seco-appearance .apa-top-sample"
            square.css "background-image": "url(#{item.image})"

            @_targetActor.setTextureByUID item.uid
            TextureLibrary.close()

          lib.setOnClose ->
            $(e.target).removeClass "open"
            $(e.target).text "Select texture..."

          $(e.target).addClass "open"
          $(e.target).text "Close library"

    ###
    # Set up our ability to modify numeric input values by dragging horizontally
    #
    # @private
    ###
    _bindDraggableInputs: ->
      @dragger = new Dragger "#{@_sel} input[type=number]"

      @dragger.setOnDragStart (d) ->
        d.setUserData initialValue: Number $(d.getTarget()).val()
        $(d.getTarget()).css "cursor", "e-resize"

      @dragger.setOnDrag (d, deltaX, deltaY) =>
        newVal = d.getUserData().initialValue + deltaX

        # Bounds check for numbers
        if $(d.getTarget()).attr("type") == "number"
          return if isNaN newVal

          unless isNaN $(d.getTarget()).attr "min"
            return if newVal < $(d.getTarget()).attr "min"

          unless isNaN $(d.getTarget()).attr "max"
            return if newVal > $(d.getTarget()).attr "max"

        $(d.getTarget()).val newVal
        $(d.getTarget()).change()

      @dragger.setOnDragEnd (d) ->
        $(d.getTarget()).css "cursor", "auto"

    ###
    # Binds listeners for the extension panel controls. Includes sidebar links
    # and panel cancel/apply buttons.
    #
    # @private
    ###
    _bindPanelControls: ->
      physicsEnable = "#{@getSel()} .sb-dialogues li[data-id=physics] input"
      physicsToggle = "#{@getSel()} .sb-dialogues li[data-id=physics] a"
      physicsApply = "#{@getSel()} .sb-seco-physics .sb-commit .sb-apply"
      physicsCancel = "#{@getSel()} .sb-seco-physics .sb-commit .sb-cancel"

      spawnEnable = "#{@getSel()} .sb-dialogues li[data-id=spawn] input"
      spawnToggle = "#{@getSel()} .sb-dialogues li[data-id=spawn] a"
      spawnApply = "#{@getSel()} .sb-seco-spawn .sb-commit .sb-apply"
      spawnCancel = "#{@getSel()} .sb-seco-spawn .sb-commit .sb-cancel"

      appearanceToggle = "#{@getSel()} .sb-appearance a"
      appearanceCancel = "#{@getSel()} .sb-seco-appearance .sb-commit .sb-cancel"
      appearanceApply = "#{@getSel()} .sb-seco-appearance .sb-commit .sb-apply"

      # Update apa dialogue cache with current cache state
      _apaRefreshCache = =>
        apaControls = $("#{@getSel()} .apa-controls")

        if @_targetActor.hasTexture()
          textureUID = @_targetActor.getTextureUID()
          apaControls.attr "data-cached-mode", "texture"
          apaControls.attr "data-cached-texture", textureUID
        else
          color = @_targetActor.getColor()
          apaControls.attr "data-cached-mode", "color"
          apaControls.attr "data-cached-color", JSON.stringify color

      # Apply data cached on apa dialogue onto actor
      _apaApplyCached = =>
        apaControls = $("#{@getSel()} .apa-controls")
        mode = apaControls.attr("data-cached-mode")

        if mode
          if mode == "color"
            color = JSON.parse apaControls.attr "data-cached-color"
            @_targetActor.clearTexture()
            @_targetActor.setColor color.r, color.g, color.b
          else if mode == "texture"
            textureUID = apaControls.attr "data-cached-texture"
            @_targetActor.setTextureByUID textureUID

      # Sidebar toggles
      $(document).on "click", physicsToggle, =>
        @togglePanel Sidebar.PANEL_PHYSICS

      $(document).on "click", spawnToggle, =>
        @togglePanel Sidebar.PANEL_SPAWN

      $(document).on "click", appearanceToggle, =>
        TextureLibrary.close()

        if @isPanelVisible Sidebar.PANEL_APPEARANCE
          _apaApplyCached()
          @_refreshAppearance sidebar: false
        else
          _apaRefreshCache()

        @togglePanel Sidebar.PANEL_APPEARANCE

      # Cancel buttons, hide associated panel and perform a value update
      $(document).on "click", physicsCancel, =>
        @hidePanel Sidebar.PANEL_PHYSICS, null, =>
          @refreshInputValues()

      $(document).on "click", spawnCancel, =>
        @hidePanel Sidebar.PANEL_SPAWN, null, =>
          @refreshInputValues()

      $(document).on "click", appearanceCancel, =>

        TextureLibrary.close()
        _apaApplyCached()
        @_refreshAppearance sidebar: false

        @hidePanel Sidebar.PANEL_APPEARANCE, null, =>
          @refreshInputValues()

      $(document).on "click", appearanceApply, =>

        TextureLibrary.close()
        _apaRefreshCache()
        @_refreshAppearance panel: false

        @hidePanel Sidebar.PANEL_APPEARANCE, null

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
    ## Panel logic
    ###
    ###

    ###
    # Get the full HTML selector for the specified panel. Primarily used by
    # internal methods for panel manipulation.
    #
    # @param [String] name
    # @return [String] selector
    ###
    getPanelSelector: (name) ->
      if name == Sidebar.PANEL_PHYSICS
        "#{@getSel()} .sb-secondary.sb-seco-physics"
      else if name == Sidebar.PANEL_SPAWN
        "#{@getSel()} .sb-secondary.sb-seco-spawn"
      else if name == Sidebar.PANEL_APPEARANCE
        "#{@getSel()} .sb-secondary.sb-seco-appearance"
      else
        null

    ###
    # Show the specified panel if it is currently hidden.
    #
    # @param [String] name
    # @param [String] selector optional, so we don't have to fetch it
    # @param [Method] cb optional end of animation callback
    ###
    showPanel: (name, sel, cb) ->
      return unless sel ||= @getPanelSelector name
      return if @isPanelVisible name, sel

      @hideAllPanelsExcept name, sel
      $(sel).animate left: @_width, Sidebar.ANIM_SPEED, cb

    ###
    # Hide the specified panel if it is currently visible.
    #
    # @param [String] name
    # @param [String] selector optional, so we don't have to fetch it
    # @param [Method] cb optional end of animation callback
    ###
    hidePanel: (name, sel, cb) ->
      return unless sel ||= @getPanelSelector name
      return if @isPanelHidden name, sel

      $(sel).animate left: 0, Sidebar.ANIM_SPEED, cb

    ###
    # Hide all panels except the specified one.
    #
    # @param [String] name
    # @param [String] selector optional, so we don't have to fetch it
    # @param [Method] cb optional end of animation callback
    ###
    hideAllPanelsExcept: (name, sel, cb) ->
      return unless sel ||= @getPanelSelector name

      @hidePanel Sidebar.PANEL_PHYSICS unless name == Sidebar.PANEL_PHYSICS
      @hidePanel Sidebar.PANEL_SPAWN unless name == Sidebar.PANEL_SPAWN
      @hidePanel Sidebar.PANEL_APPEARANCE unless name == Sidebar.PANEL_APPEARANCE

    ###
    # Toggle the visible state of the specified panel. If we have to show it,
    # all other panels are hidden.
    #
    # @param [String] name
    # @param [String] selector optional, so we don't have to fetch it
    # @param [Method] cb optional end of animation callback
    ###
    togglePanel: (name, sel, cb) ->
      return unless sel ||= @getPanelSelector name

      if @isPanelHidden name, sel
        @showPanel name, sel, cb
      else
        @hidePanel name, sel, cb

    ###
    # Check if the specified panel is currently visible.
    #
    # @param [String] name
    # @param [String] selector optional, so we don't have to fetch it
    # @return [Boolean] visible
    ###
    isPanelVisible: (name, sel) ->
      return unless sel ||= @getPanelSelector name

      $(sel).offset().left == @_width

    ###
    # Check if the specified panel is currently hidden.
    #
    # @param [String] name
    # @param [String] selector optional, so we don't have to fetch it
    # @return [Boolean] hidden
    ###
    isPanelHidden: (name, sel) ->
      return unless sel ||= @getPanelSelector name

      $(sel).offset().left == 0

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

      # Move appearance dialogue down, in line with appearance section
      if @_targetActor
        $("#{@getSel()} .sb-seco-appearance").offset
          top: $("#{@getSel()} .sb-appearance").position().top

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
    # Helper to tell us if the appearance panel actually needs a refresh. This
    # includes the sample square on the main sidebar
    #
    # @return [Boolean] needsRefresh
    ###
    _apaNeedsRefresh: ->
      @_apaCache ||= {}

      color = @_targetActor.getColor()
      textureUID = @_targetActor.getTextureUID()

      @_apaCache.textureUID != textureUID || !_.isEqual @_apaCache.color, color

    ###
    # Update the internal cache used to determine we need a refresh
    ###
    _apaUpdateRefreshCache: ->
      @_apaCache ||= {}

      @_apaCache.color = @_targetActor.getColor()
      @_apaCache.textureUID = @_targetActor.getTextureUID()
      @

    ###
    # Pull in new input values from our target actor
    ###
    refreshInputValues: ->
      return unless !!@_targetActor

      @_refreshRawInputs()
      @_refreshAppearance() if @_apaNeedsRefresh()
      @_refreshOpacity()

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
    # Refresh appearance squares. Can also be used to refresh specific squares.
    #
    # @param [Object] options optional specification of which square to refresh
    # @option options [Boolean] sidebar
    # @option options [Boolean] panel
    ###
    _refreshAppearance: (options) ->
      options ||= {}
      options.sidebar = true unless options.sidebar == false
      options.panel = true unless options.panel == false

      # Build selector
      sidebarSquare = "#{@getSel()} .sb-appearance .sb-ap-sample"
      sidebarOuter = "#{@getSel()} .sb-appearance"
      panelSquare = "#{@getSel()} .sb-seco-appearance .apa-top-sample"
      panelOuter = "#{@getSel()} .sb-seco-appearance .apa-top"

      apSquareSelector = ""
      apSquareSelector += sidebarSquare if options.sidebar
      apSquareSelector += ", " if options.sidebar and options.panel
      apSquareSelector += panelSquare if options.panel

      apOuterSelector = ""
      apOuterSelector += sidebarOuter if options.sidebar
      apOuterSelector += ", " if options.sidebar and options.panel
      apOuterSelector += panelOuter if options.panel

      return unless apSquareSelector.length > 0
      apSquare = $ apSquareSelector
      apOuter = $ apOuterSelector

      @_apaUpdateRefreshCache()

      # Grab existing color/texture info
      color = @_targetActor.getColor()
      texture = _.find @ui.editor.project.textures, (texture) =>
        texture.getUID() == @_targetActor.getTextureUID()

      # Update square
      if texture
        apOuter.removeClass "color"
        apOuter.addClass("texture") unless apOuter.hasClass "texture"

        apSquare.css "background-image": "url('#{texture.getURL()}')"
      else
        apOuter.removeClass "texture"
        apOuter.addClass("color") unless apOuter.hasClass "color"

        apSquare.css
          "background-image": "none"
          "background-color": "rgb(#{color.r}, #{color.g}, #{color.b})"

      # Update control mode
      if texture
        $("#{@getSel()} .apa-mode-color").hide()
        $("#{@getSel()} .apa-mode-texture").show()
      else
        $("#{@getSel()} .apa-mode-color").show()
        $("#{@getSel()} .apa-mode-texture").hide()

      # Update sliders/inputs
      $("#{@getSel()} .sb-seco-appearance .apa-sliders-rgb li").each (i, elm) =>
        id = $(elm).attr "data-id"
        value = null
        value = color.r if id == "red"
        value = color.g if id == "green"
        value = color.b if id == "blue"
        return unless value != null

        $(elm).children("input").val value

      _getHexComponent = (c) ->
        c_s = c.toString 16
        if c_s.length == 2 then c_s else "0#{c_s}"

      # Update HTML code input
      htmlCode = ""
      htmlCode += _getHexComponent color.r
      htmlCode += _getHexComponent color.g
      htmlCode += _getHexComponent color.b

      $("#{@getSel()} .sb-seco-appearance .apa-tabs input").val htmlCode

      # Update switch
      $("#{@getSel()} .apa-top-switch input").prop "checked", !!texture

    _refreshOpacity: ->
      opacity = @_targetActor.getOpacity()

      $("#{@getSel()} .sb-opacity input[type=range]").val opacity * 100
      $("#{@getSel()} .sb-opacity input[type=number]").val opacity * 100

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
      displayName = data.name
      displayIcon = data.icon or config.icon.property_default

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
      value = value
      displayName = data.name

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
      value = value
      displayName = data.name

      TemplateBooleanControl
        displayName: displayName
        name: displayName.toLowerCase()
        value: value.getValue()
        width: data.width or "100%"
        parent: data.parent or false

    renderControl_text: (data, value) ->
      value = value
      displayName = data.name

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
    setWidth: (@_width) ->
      @getElement().width @_width
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
        @getElement().animate left: @_visibleX, Sidebar.ANIM_SPEED, cb
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
        @getElement().animate left: @_hiddenX, Sidebar.ANIM_SPEED, cb
      else
        @getElement().css left: @_hiddenX
        cb() if cb

      @_visible = false
      @refreshVisible()
