define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  aformat = require "util/format"
  Widget = require "widgets/widget"
  Modal = require "widgets/modal"
  TimelineControl = require "widgets/timeline/timeline_control"
  Workspace = require "widgets/workspace/workspace"
  TimelineBaseTemplate = require "templates/timeline/base"
  TimelineActorTemplate = require "templates/timeline/actor"
  TimelineActorTimeTemplate = require "templates/timeline/actor_time"

  Storage = require "storage"

  # Timeline widget, serving as the main control center for objects.
  #
  # OH GAWD this is going to be complex.
  # 9/6/2013: Escape while you still can
  class Timeline extends Widget

    ###
    # Timebar color classes, styled in colors.styl
    # @type [Array<String>] css class names
    ###
    @_timebarColors: [
      "atimebar-color-1"
      "atimebar-color-2"
      "atimebar-color-3"
      "atimebar-color-4"
    ]

    ###
    # Timebar bg color classes, styled in colors.styl
    # @type [Array<String>] css class names
    ###
    @_timebarBGColors: [
      "atimebar-color-1-bg"
      "atimebar-color-2-bg"
      "atimebar-color-3-bg"
      "atimebar-color-4-bg"
    ]

    @__staticInitialized: false

    ###
    # Get a random timebar color index, used when setting default actor timebar
    # color
    #
    # @return [Number] colIndex
    ###
    @getRandomTimebarColor: ->
      Math.floor(Math.random() * @_timebarColors.length)

    ###
    # Creates a timeline at the bottom of the screen. Note that it is absolutely
    # positioned, and adds padding to the body accordingly.
    #
    # The default duration is 5000ms
    #
    # @param [UIManager] ui
    # @param [Number] duration ad length in ms, can be modified (expensive)
    ###
    constructor: (@ui, duration) ->
      return unless @enforceSingleton()

      @_duration = Number param.optional(duration, 5000)
      @_control = new TimelineControl @

      @_previewFPS = 30
      @_visible = true

      # Sanity check on our internal color arrays
      _l1 = Timeline._timebarColors.length
      _l2 = Timeline._timebarBGColors.length

      if _l1 != _l2
        throw new Error "Timeline color count != timeline bg color count!"

      # Enforce minimum duration of 250ms
      throw new Error "Ad must be longer than 250ms!" unless @_duration > 250

      super
        id: ID.prefId("timeline")
        parent: "footer"
        classes: ["timeline"]

      @controlState =
        fast_backward: false
        backward: false
        play: false
        forward: false
        fast_forward: false

      # Actor array, access through registerActor/removeActor
      @_actors = []

      # Check for any existing padding on the body (and format accordingly)
      @_bodyPadding = $("body").css "padding-bottom"
      if @_bodyPadding == "auto" then @_bodyPadding = 0
      @_bodyPadding = @_bodyPadding.split("px").join ""

      # Set initial height and resize
      @resize 256

      # Inject our layout
      @renderStructure()

      # Set initial time
      @_updateCursorTime()

      @_enableDrag()
      @_regListeners()

      if Storage.get("timeline.visible") != false
        @show()
      else
        @hide()

    ###
    # Checks if a timeline has already been created, and returns false if one
    # has. Otherwise, sets a flag preventing future calls from returning true
    ###
    enforceSingleton: ->
      if Timeline.__exists
        AUtilLog.warn "A timeline already exists, refusing to initialize!"
        return false

      Timeline.__exists = true

    ###
    # Returns the time space css selector
    # @return [String] selector
    # @private
    ###
    _spaceSelector: -> "#{@_sel} .content .time"

    ###
    # Returns the body space css selector
    # @return [String] selector
    # @private
    ###
    _bodySelector: -> "#{@_sel} .content .list"

    ###
    # @param [BaseActor] actor
    ###
    _actorBodySelector: (actor) ->
      "#actor-body-#{actor.getId()}.actor"

    ###
    # Get current timeline duration
    #
    # @return [Number] duration
    ###
    getDuration: -> @_duration

    ###
    # Get current preview FPS
    #
    # @return [Number] duration
    ###
    getPreviewFPS: -> @_previewFPS

    ###
    # Enables cursor dragging
    # @private
    ###
    _enableDrag: ->
      $("#timeline-cursor").draggable
        axis: "x"
        containment: "parent"
        drag: (e, ui) =>

          # Cancel the drag if we are currently in the middle of playback
          if @_playbackID != undefined and @_playbackID != null
            return false

          @_onCursorDrag e, ui
          @_onCursorDragStop e, ui

    ###
    # Animation keys lightbolts saving
    # @private
    ###
    _saveKey: ->
      index = Workspace.getSelectedActor()
      # only enter checks if an actor is actually selected
      if index != null and index != undefined
        for actor, i in @_actors
          if actor.getId() == index then index = i
      if @_actors[index].isAlive()
        ARELog.info "SAVED"
        @_actors[index].updateInTime()

    ###
    # Kills the interval and NULLs the playbackID
    # @private
    ###
    clearPlaybackID: ->
      clearInterval @_playbackID
      @_playbackID = null
      ##
      # we need to update the play control state
      @controlState.play = false
      @updateControls()

    ###
    # Resize and apply our height to the body
    #
    # @param [Number] height
    ###
    resize: (@_height) ->
      @getElement().height @_height

    ###
    # callback when a resize takes place
    ###
    onResize: ->
      @_hiddenHeight = @getElement(".header").height()
      if @_visible
        @getElement().height @_height
      else
        @getElement().height @_hiddenHeight

      @getElement(".content").height @getElement().height -
                                     @getElement(".header").height()

    ###
    # When an actor expand button is pressed this function is called
    # @param [Event] e
    ###
    _onActorExpand: (e) ->
      actorId = e.currentTarget.attributes.actorid.value
      timeSelector = "#actor-time-#{actorId}.actor"
      bodySelector = "#actor-body-#{actorId}.actor"

      elm = $(bodySelector)
      elm.toggleClass "expanded"
      $(timeSelector).toggleClass "expanded", elm.hasClass("expanded")

      icon = $("#{bodySelector} .expand i")
      if elm.hasClass "expanded"
        icon.removeClass "fa-caret-right"
        icon.addClass "fa-caret-down"
      else
        icon.removeClass "fa-caret-down"
        icon.addClass "fa-caret-right"

    ###
    # Cursor drag event
    #
    # @param [Event] e
    # @param [Object] ui
    # @private
    ###
    _onCursorDrag: (e, ui) ->
      # Update our cursor time
      @_updateCursorTime()

    ###
    # Cursor drag stop event, updates all living
    #
    # @param [Event] e
    # @param [Object] ui
    # @private
    ###
    _onCursorDragStop: (e, ui) ->
      # TODO: Apply update to only existing actors.
      #       Calculate actor births and deaths seperately (after this)
      cursor = @getCursorTime()
      for a in @_actors
        # Check if actor needs to die
        if (cursor < a.lifetimeStart or cursor > a.lifetimeEnd) and a.isAlive()
          a.timelineDeath()

        if a.isAlive() or (cursor >= a.lifetimeStart and cursor <= a.lifetimeEnd)
          a.updateInTime()

    ###
    # Update displayed cursor time
    # @private
    ###
    _updateCursorTime: ->
      ms = @getCursorTime()
      seconds = ms / 1000.0
      minutes = seconds / 60.0
      #hours = minutes / 60.0 # we will probably never get this far
      $("#timeline-cursor-time").text "#{(minutes % 60).toFixed()}:#{(seconds % 60).toFixed(2)}"
      #$("#timeline-cursor-time").text "Cursor: #{time}s @ #{@getPreviewFPS()} FPS"

    ###
    # Registers event listeners
    # @private
    ###
    _regListeners: ->

      $(document).on "click", ".timeline .button.toggle", (e) =>

        # Find the affected timeline
        selector = e.currentTarget.attributes.timelineid.value
        timeline = $("body").data "##{selector}"

        timeline.toggle()

      # Handle expansions
      $(document).on "click", ".actor .expand", (e) => @_onActorExpand e

      # Outer timebar
      $(document).on "click", ".timeline .list .actor", (e) =>
        @_control.onOuterClicked e.currentTarget

      # Timeline visibility toggle
      $(document).on "click", "#timline-visible-toggle", (e) =>
        @_control._visToggleClicked e
        @updateControls()

      # Timeline playback controls
      $(document).on "click", "#timeline-control-fast-backward", (e) =>
        @_control.onClickFastBackward e
        @updateControls()

      $(document).on "click", "#timeline-control-forward", (e) =>
        @_control.onClickForward e
        @updateControls()

      $(document).on "click", "#timeline-control-play", (e) =>
        @_control.onClickPlay e
        @updateControls()

      $(document).on "click", "#timeline-control-backward", (e) =>
        @_control.onClickBackward e
        @updateControls()

      $(document).on "click", "#timeline-control-fast-forward", (e) =>
        @_control.onClickFastForward e
        @updateControls()

      # Sidebar save button
      $(document).on "click", ".asp-save", (e) => @_saveKey e

    ###
    # Return current cursor time in ms (relative to duration)
    #
    # @return [Number] time cursor time in ms
    ###
    getCursorTime: ->
      # I thought about making this a warning and just returning '0', but that
      # would mess up thing elsewhere (whoever uses our return value would be
      # screwed). This makes the most sense
      if $("#timeline-cursor").length == 0
        throw new Error "Cursor not visible can't return time!"

      @_duration * ($("#timeline-cursor").position().left / $(@_spaceSelector()).width())

    ###
    # Show dialog box for setting the preview framerate
    # @return [Modal]
    ###
    showSetPreviewRate: ->

      # Randomized input name
      n = ID.prefId "_tPreviewRate"

      _html = """
      <div class="input_group">
      <label for="_tPreviewRate">Framerate: </label>
      <input type="text" value="#{@getPreviewFPS()}" placeholder="30" name="#{n}" />
      </div>
      """

      new Modal
        title: "Set Preview Framerate"
        content: _html
        modal: false
        cb: (data) =>
          @_previewFPS = data[n]
        validation: (data) ->
          if isNaN(data[n]) then return "Framerate must be a number"
          if Number(data[n]) <= 0 then return "Framerate must be > 0"
          true

    ###
    # Set an arbitrary cursor time
    #
    # @param [Number] time cursor time in ms
    ###
    setCursorTime: (time) ->
      param.required time

      if $("#timeline-cursor").length == 0
        throw new Error "Cursor not visible can't return time!"

      # Move cursor
      $("#timeline-cursor").css "left", $(@_spaceSelector()).width() * (time / @_duration)

      # Update
      @_onCursorDrag()
      @_onCursorDragStop()

    ###
    # Register actor, causes it to appear on the timeline starting from the
    # current cursor position.
    #
    # @param [BaseActor] actor
    ###
    registerActor: (actor) ->
      param.required actor

      if actor.constructor.name.indexOf("Actor") == -1
        throw new Error "Actor must be an instance of BaseActor!"

      # Ship to our array
      @_actors.push actor

      # Render actor internals
      @_renderActorSpace @_actors.length - 1

      # Ship actor to the actor list
      @_renderActors @_actors.length - 1

    ###
    # Remove an actor by id, re-renders timeline internals. Note that this
    # utilizies the ID of the AJS actor!
    #
    # @param [Number] id
    # @return [Boolean] success
    ###
    removeActor: (id) ->
      param.required id

      for a, i in @_actors
        if a.getActorId() == id

          # Remove actor from our internal array
          @_actors.splice i, 1

          @_renderActors()
          @_renderSpace()

          return true

      false

    ###
    # Refresh spacer length and actor color in the actor list
    # @private
    ###
    _refreshActorRows: ->
      $("#{@_bodySelector()} actor").each ->
        #

    ###
    # Appends a single actor to the actor list, used after registering an actor
    # and rendering their timebar
    #
    # @param [Number] index index of the actor to append to the list
    # @privvate
    ###
    _renderSingleActor: (index, notouch) ->
      # notouch is an undocumented param, set to true when we are called from
      # @_renderActors. When it is true, we simply return our generated html
      # instead of injecting it
      notouch = param.optional notouch, false
      param.required index

      actor = @_actors[index]
      pos = actor.getPosition()
      color = actor.getColor()

      _properties = []
      _properties.push
        id: "opacity"
        title: "Opacity"
        value: aformat.num actor.getOpacity(), 2

      _properties.push
        id: "position"
        title: "Position"
        value: aformat.pos pos, 0

      _properties.push
        id: "rotation"
        title: "Rotation"
        value: aformat.degree actor.getRotation(), 2

      _properties.push
        id: "color"
        title: "Color"
        value: aformat.color color, 2

      _html = TimelineActorTemplate
        id: "actor-body-#{actor.getId()}"
        index: index
        actorId: actor.getId()
        title: actor.name
        properties: _properties

      if notouch then return _html

      $(@_bodySelector()).append _html
      @_refreshActorRows()

    ###
    # Render the actor list Should never be called by itself, only by @render()
    #
    # @private
    ###
    _renderActors: ->
      _h = ""
      for a, i in @_actors
        _h += @_renderSingleActor i, true

      # Ship
      $(@_bodySelector()).html _h
      @_refreshActorRows()

    ###
    # Renders an individual actor timebar, used when registering new actors,
    # preventing a full re-render of the space. Also called internally by
    # @_renderSpace.
    #
    # @param [Number] index index of the actor whose space we are to render
    # @private
    ###
    _renderActorSpace: (index, notouch) ->
      # notouch is an undocumented param, set to true when we are called from
      # @_renderSpace. When it is true, we simply return our generated html
      # instead of injecting it
      notouch = param.optional notouch, false
      param.required index

      if index < 0 or index >= @_actors.length
        throw new Error "Invalid index, no actor at #{index}, can't render space"

      spaceW = $(@_spaceSelector()).width()

      a = @_actors[index]
      aID = a.getId()

      # TODO: Consider moving the following two checks into our registerActor
      #       method. The only possible concern with that is the fact that
      #       the lifetime can change outside of our supervision (it is public
      #       and whatnot).
      #
      #       A possible remedy to this would be to make the lifetime private,
      #       and only allow modification through ourselves. Hmmm....

      # Sanity check, actor must die after it is created
      if a.lifetimeEnd < a.lifetimeStart
        throw new Error "Actor lifetime end must come after lifetime start! " +\
                        "start: #{a.lifetimeStart}, end: #{a.lifetimeEnd}"

      # Make sure actors' lifetime is contained in our duration!
      #
      # TODO: In the future, we can allow for actor deaths after our duration,
      #       to ease timeline resizing.
      if a.lifetimeStart < 0 or a.lifetimeEnd > @_duration
        throw new Error "Actor exists beyond our duration!"

      # Calculate actor x offset
      _start = spaceW * (a.lifetimeStart / @_duration)
      _length = spaceW * ((a.lifetimeEnd - a.lifetimeStart) / @_duration)

      keyframes =
        opacity: []
        position: []
        rotation: []
        color: []
        #physics: []

      _animations = a.getAnimations()
      for anim of _animations
        continue unless anim.components

        offset = spaceW * ((Number(anim) - a.lifetimeStart) / @_duration)

        if anim.components.opacity
          keyframes["opacity"].push
            id: "opacity-#{aID}-key-#{keyframes["opacity"].length}"
            left: offset

        if anim.components.position
          keyframes["position"].push
            id: "position-#{aID}-key-#{keyframes["position"].length}"
            left: offset

        if anim.components.rotation
          keyframes["rotation"].push
            id: "rotation-#{aID}-key-#{keyframes["rotation"].length}"
            left: offset

        if anim.components.color
          keyframes["color"].push
            id: "color-#{aID}-key-#{keyframes["color"].length}"
            left: offset

        #if anim.components.physics
        #  keyframes["physics"].push
        #    id: "physics-#{aID}-key-#{keyframes["physics"].length}"
        #    left: offset

      properties = []
      properties.push
        id: "actor-time-bar-#{aID}"
        isProperty: false
        left: _start
        width: _length

      properties.push
        id: "actor-time-property-opacity-#{aID}"
        isProperty: false
        keyframes: keyframes["opacity"]

      properties.push
        id: "actor-time-property-position-#{aID}"
        isProperty: false
        keyframes: keyframes["position"]

      properties.push
        id: "actor-time-property-rotation-#{aID}"
        isProperty: false
        keyframes: keyframes["rotation"]

      properties.push
        id: "actor-time-property-color-#{aID}"
        isProperty: false
        keyframes: keyframes["color"]

      #properties.push
      #  id: "actor-time-property-physics-#{aID}"
      #  isProperty: false
      #  keyframes: keyframes["physics"]

      _html = TimelineActorTimeTemplate
        id: "actor-time-#{aID}"
        dataIndex: index
        isExpanded: $("#actor-body-#{aID}").hasClass("expanded")
        properties: properties

      if notouch then return _html
      else $("#{@_spaceSelector()} .time-actors").append _html

    ###
    # Render the timeline space. Should never be called by itself, only by
    # @render()
    #
    # @private
    ###
    _renderSpace: ->
      # Create a time bar for each actor, positioned according to their birth and
      # death.
      _h = ""
      for a, i in @_actors
        _h += @_renderActorSpace i, true
      # Ship
      $("#{@_spaceSelector()} .time-actors").html _h

    ###
    # Render initial structure.
    # Note that calling this clears the timeline visually, and does not render
    # objects! Objects are not destroyed, call @render to update them.
    ###
    renderStructure: ->
      options =
        id: "timeline-header"
        timelineId: @getId()
        currentTime: "0:00.00"
        #contents: ""
        #timeContents: ""

      return @getElement().html TimelineBaseTemplate options

    ###
    # Proper render function, fills in timeline internals. Since we have two
    # distinct sections, each is rendered by a seperate method. This helps
    # divide the necessary logic, into @_renderActors() and @_renderSpace(). This
    # function simply calls both.
    ###
    render: ->
      @_renderActors()
      @_renderSpace()

    ###
    # Update the state of the controls bar
    # @return [Void]
    ###
    updateControls: ->
      @getElement("#timeline-control-fast-backward")
        .toggleClass("active", @controlState.fast_backward)
      @getElement("#timeline-control-backward")
        .toggleClass("active", @controlState.backward)
      @getElement("#timeline-control-play")
        .toggleClass("active", @controlState.play)
      @getElement("#timeline-control-forward")
        .toggleClass("active", @controlState.forward)
      @getElement("#timeline-control-fast-forward")
        .toggleClass("active", @controlState.fast_forward)

    ###
    # Called by actors, for updating its Timeline state
    # this is a much gentle way of updating the data, instead of rendering
    # over the HTML content
    # @friend [BaseActor]
    # @param [BaseActor] actor
    # @private
    ###
    updateActor: (actor) ->
      if actor
        pos = actor.getPosition()
        color = actor.getColor()
        rotation = actor.getRotation()
        opacity = actor.getOpacity()

        bodySelector = @_actorBodySelector(actor)
        selector = "#{bodySelector} .property"
        $("#{selector}#opacity .value").text aformat.num opacity, 2
        $("#{selector}#position .value").text aformat.pos pos, 0
        $("#{selector}#rotation .value").text aformat.degree rotation, 2
        $("#{selector}#color .value").text aformat.color color, 2

      actor

    ###
    #
    # @param [BaseActor] actor
    # @private
    ###
    selectActor: (actor) ->
      @updateActor actor

      if @_lastSelectedActor
        selector = @_actorBodySelector(@_lastSelectedActor)
        $("#{selector} .actor-info").removeClass("selected")

      @_lastSelectedActor = actor

      if @_lastSelectedActor
        selector = @_actorBodySelector(@_lastSelectedActor)
        $("#{selector} .actor-info").addClass("selected")

      actor

    ###
    # @param [Number] index
    ###
    selectActorByIndex: (index) ->
      @selectActor @_actors[index]

    ###
    # Toggle visibility of the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to false
    ###
    toggle: (cb, animate) ->
      animate = param.optional animate, true

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
      animate = param.optional animate, true

      if @_visible
        AUtilLog.warn "Timeline was already visible"
        cb() if cb
        return

      AUtilLog.info "Showing Timeline"

      if animate
        @getElement().animate height: @_height, 300
      else
        @getElement().height @_height

      ##
      # I'm sure jQuery's toggle class can do this, but I still haven't
      # figured it out properly
      @getElement(".button.toggle i").removeClass("fa-arrow-up")
      @getElement(".button.toggle i").addClass("fa-arrow-down")

      Storage.set "timeline.visible", true
      @_visible = true

    ###
    # Hide the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to true
    ###
    hide: (cb, animate) ->
      animate = param.optional animate, true

      unless @_visible
        AUtilLog.warn "Timeline was already hidden"
        cb() if cb
        return

      AUtilLog.info "Hiding Timeline"

      if animate
        @getElement().animate height: @_hiddenHeight, 300
      else
        @getElement().height @_hiddenHeight

      ##
      # I'm sure jQuery's toggle class can do this, but I still haven't
      # figured it out properly
      @getElement(".button.toggle i").removeClass("fa-arrow-down")
      @getElement(".button.toggle i").addClass("fa-arrow-up")

      Storage.set "timeline.visible", false
      @_visible = false

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      if type == "selected.actor"
        @selectActor params.actor
      else if type == "update.actor"
        @updateActor params.actor
