define (require) ->

  config = require "config"
  param = require "util/param"

  ID = require "util/id"
  AUtilLog = require "util/log"
  aformat = require "util/format"
  Widget = require "widgets/widget"
  ContextMenu = require "widgets/context_menu"
  TimelineControl = require "widgets/timeline/timeline_control"
  Workspace = require "widgets/workspace/workspace"

  Dragger = require "util/dragger"
  Draggable = require "util/draggable"

  TemplateTimelineBase = require "templates/timeline/base"
  TemplateTimelineActor = require "templates/timeline/actor"
  TemplateTimelineActorTime = require "templates/timeline/actor_time"
  TemplateTimelineKeyframe = require "templates/timeline/keyframe"

  Storage = require "storage"
  config = require "config"

  # Timeline widget, serving as the main control center for objects.
  class Timeline extends Widget

    ###
    # @type [Boolean]
    ###
    @__staticInitialized: false

    ###
    # Creates a timeline at the bottom of the screen. Note that it is absolutely
    # positioned, and adds padding to the body accordingly.
    #
    # The default duration is 5000ms
    #
    # @param [UIManager] ui
    # @param [Number] duration ad length in ms, can be modified (expensive)
    ###
    constructor: (@ui, options) ->
      options = param.optional options, {}
      return unless @enforceSingleton()

      super @ui,
        id: ID.prefID("timeline")
        parent: "footer"
        classes: ["timeline"]

      @_duration = Number param.optional(options.duration, 5000)

      unless @_duration > 0
        return AUtilLog.error "Invalid duration: #{@_duration}"

      @_control = new TimelineControl @

      @_previewFPS = 30
      @_playbackID = null

      @controlState =
        fast_backward: false
        backward: false
        play: false
        forward: false
        fast_forward: false

      # Actor array, access through addActor/removeActor
      @_actors = []

      @resize 256

      @_regListeners()

    ###
    # @return [self]
    ###
    postInit: ->
      super()

      @_visible = Storage.get("timeline.visible") == true

      if @_visible
        @show()
      else
        @hide()

      @

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
    # Setup keyframe Dragger
    ###
    _setupDraggableKeyframes: ->
      return if @keyframeDragger

      @keyframeDragger = new Dragger ".actor .keyframes > .keyframe"

      @keyframeDragger.setOnDragStart (d) ->
        d.setUserData "startTime": Number $(d.getTarget()).attr "data-time"

      # Vertical component is ignored
      @keyframeDragger.setOnDrag (d, deltaX, deltaY) =>

        id = $(d.getTarget()).attr "id"

        keyframeTime = d.getUserDataValue "startTime"
        property = $(d.getTarget()).parent().attr("data-property")

        targetTime = keyframeTime + (deltaX * @getTimePerPixel())

        # Cache the actor to speed things up
        unless d.getUserDataValue "actor"
          actorId = $(d.getTarget()).closest(".actor").attr "data-actorid"
          actor = _.find @_actors, (a) -> a.getID() == actorId

          return AUtilLog.error "Invalid actor: #{actorId}" unless actor

          d.setUserDataValue "actor", actor
        else
          actor = d.getUserDataValue "actor"

        # Cache keyframe boundary information
        unless d.getUserDataValue "boundaries"

          boundaries =
            left: actor.findNearestState keyframeTime, false, property
            right: actor.findNearestState keyframeTime, true, property

          boundaries.right = @getDuration() if boundaries.right == -1

          d.setUserDataValue "boundaries", boundaries
        else
          boundaries = d.getUserDataValue "boundaries"

        return if targetTime > boundaries.right or targetTime < boundaries.left

        source = d.getUserDataValue("lastUpdate") or keyframeTime

        window.a = actor

        actor.transplantKeyframe property, source, targetTime
        actor.updateInTime()

        d.setUserDataValue "lastUpdate", Math.floor targetTime

        # Update target
        d.setTarget $("##{id}")

        # Update keyframe
        $(d.getTarget()).attr "data-time", Math.floor targetTime
        $(d.getTarget()).css "left", "#{@getOffsetForTime targetTime}px"

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
      "#{@_bodySelector()} #actor-body-#{actor.getID()}.actor"

    ###
    # @param [BaseActor] actor
    ###
    _actorTimeSelector: (actor) ->
      "#{@_spaceSelector()} #actor-time-#{actor.getID()}.actor"

    ###
    # returns the scrollbar selector
    # @return [String]
    ###
    _scrollbarSelector: -> "#{@_sel} .content"

    ###
    # Returns the scrollbar element
    # @return [jQuery]
    ###
    _scrollbarElement: ->
      $(@_scrollbarSelector())

    ## ATTRIBUTES

    ###
    # @return [Array<BaseActor>] actors
    ###
    getActors: -> @_actors

    ###
    # Get timeline duration
    #
    # @return [Number] duration
    ###
    getDuration: -> @_duration

    ###
    # Update timeline duration
    #
    # @param [Number] duration
    ###
    setDuration: (duration) ->
      param.required duration

      unless duration > 0
        return AUtilLog.error "Invalid duration: #{duration}"

      @_duration = duration
      @render()

    ###
    # Get current preview FPS
    #
    # @return [Number] duration
    ###
    getPreviewFPS: -> @_previewFPS

    ###
    # @param [Number] fps
    ###
    setPreviewFPS: (fps) -> @_previewFPS = fps

    ###
    # Return current cursor time in ms (relative to duration)
    #
    # @return [Number] time cursor time in ms
    ###
    getCursorTime: ->
      @_duration * ($("#timeline-cursor").position().left /
                    $(@_spaceSelector()).width())

    ###
    # Get the amount of time each pixel in the timeline represents
    #
    # @return [Number] TPP
    ###
    getTimePerPixel: ->
      @_duration / $(@_spaceSelector()).width()

    ###
    # Get the left offset pixel position for any given time
    #
    # @param [Number] time
    # @return [Number] offset
    ###
    getOffsetForTime: (time) ->
      (time / @_duration) * $(@_spaceSelector()).width()

    ###
    # Set an arbitrary cursor time
    #
    # @param [Number] time cursor time in ms
    ###
    setCursorTime: (time) ->
      param.required time

      $("#timeline-cursor").css "left", $(@_spaceSelector()).width() * (time / @_duration)

      setTimeout =>
        @_updateCursorTime()
        @updateAllActorsInTime()
      , 0

    ###
    # Validates an actor's lifetime
    # @param [BaseActor] actor
    # @private
    ###
    _checkActorLifetime: (actor) ->
      # Sanity check, actor must die after it is created
      if actor.lifetimeEnd_ms < actor.lifetimeStart_ms
        throw new Error "Actor lifetime end must come after lifetime start! " +\
                        "start: #{actor.lifetimeStart_ms}, " +\
                        "end: #{actor.lifetimeEnd_ms}"

      # Make sure actors' lifetime is contained in our duration!
      #
      # TODO: In the future, we can allow for actor deaths after our duration,
      #       to ease timeline resizing.
      if actor.lifetimeStart_ms < 0 or actor.lifetimeEnd_ms > @_duration
        throw new Error "Actor exists beyond our duration!"

      true

    ## UI-TRIGGERS

    ###
    # When an actor expand button is pressed this function is called
    # @param [jQuery] element
    # @private
    ###
    _onActorToggleExpand: (element) ->
      index = $(element).attr "data-index"
      @toggleActorExpandByIndex index

    ###
    # When an actor visibility button is pressed this function is called
    # @param [jQuery] element
    # @private
    ###
    _onActorToggleVisible: (element) ->
      index = $(element).attr "data-index"
      @toggleActorVisibilityByIndex index

    ###
    # When an actor live button is toggled
    # @param [jQuery] actorElement
    # @private
    ###
    _onActorToggleLive: (actorElement, propertyElement) ->
      #

    ###
    # When an actor graph button is toggled
    # @param [jQuery] actorElement
    # @private
    ###
    _onActorToggleGraph: (actorElement, propertyElement) ->
      #

    updateAllActorsInTime: ->
      t = @getCursorTime()

      for a in @_actors

        # Check if actor needs to die
        if (t < a.lifetimeStart_ms or t > a.lifetimeEnd_ms) and a.isAlive()
          a.timelineDeath()

        else if a.isAlive() or (t >= a.lifetimeStart_ms and t <= a.lifetimeEnd_ms)
          a.updateInTime()

    ###
    # @param [jQuery] element
    # @private
    ###
    _onOuterClicked: (element) ->
      param.required element

      index = Number $(element).attr "data-index"

      @switchSelectedActorByIndex index
      @ui.pushEvent "timeline.selected.actor", actor: @_actors[index]

    ###
    # @private
    ###
    _bindContextClick: ->
      $(document).on "contextmenu", ".timeline .actor .title", (e) =>
        actorElement = $(e.target).closest ".actor"
        index = $(actorElement).attr "data-index"
        new ContextMenu @ui,
          x: e.pageX
          y: e.pageY
          properties: @_actors[index].getContextProperties()

        e.preventDefault()
        false

    ###
    # Registers event listeners
    # @private
    ###
    _regListeners: ->

      @_setupDraggableKeyframes()
      @_bindContextClick()

      $(document).on "click", ".timeline .button.toggle", (e) =>
        @toggle()

      $(document).on "click", ".timeline .list .actor .expand", (e) =>
        @_onActorToggleExpand $(e.target).closest ".actor"

      $(document).on "click", ".timeline .list .actor .visibility", (e) =>
        @_onActorToggleVisible $(e.target).closest ".actor"

      $(document).on "click", ".timeline .list .actor .live", (e) =>
        @_onActorToggleLive $(e.target).closest(".actor"),
          $(e.target).closest(".property")

      $(document).on "click", ".timeline .list .actor .graph", (e) =>
        @_onActorToggleGraph $(e.target).closest(".actor"),
          $(e.target).closest(".property")

      ##
      ## TODO: Move all of the control listeners into the timeline_control class
      ##

      # Outer timebar
      $(document).on "click", ".timeline .list .actor .title", (e) =>
        @_onOuterClicked $(e.target).closest ".actor"

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

      @_cursorDraggable = new Draggable "#timeline-cursor"
      @_cursorDraggable.constrainToX()
      @_cursorDraggable.constrainToParent()

      # Cancel the drag if we are currently in the middle of playback
      @_cursorDraggable.setCondition => @_playbackID == null

      @_cursorDraggable.setOnDrag => @_updateCursorTime()
      @_cursorDraggable.setOnDragEnd => @updateAllActorsInTime()

    ###
    # Construct a new scrollbar
    # @return [Void]
    # @private
    ###
    _setupScrollbar: ->
      @_scrollbarElement().perfectScrollbar suppressScrollX: true

    ###
    # Kills the interval and NULLs the playbackID
    # @friend [TimelineControl]
    # @private
    ###
    clearPlaybackID: ->
      clearInterval @_playbackID
      @_playbackID = null

      # we need to update the play control state
      @controlState.play = false
      @updateControls()

    ###
    # Resize and apply our height to the body
    #
    # @param [Number] height
    ###
    resize: (@_height) -> @getElement().height @_height

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

      @_updateScrollbar()

    ###
    # @param [Number] index
    # @param [Boolean] forceState
    #   @optional
    ###
    toggleActorExpandByIndex: (index, forceState) ->
      param.required index

      actor = @_actors[index]
      return unless actor
      bodySelector = @_actorBodySelector(actor)
      timeSelector = @_actorTimeSelector(actor)

      $(bodySelector).toggleClass "expanded", forceState
      $(timeSelector).toggleClass "expanded", $(bodySelector).hasClass("expanded")

      icon = $(bodySelector).find ".expand i"

      if $(bodySelector).hasClass "expanded"
        icon.removeClass "fa-caret-right"
        icon.addClass "fa-caret-down"
      else
        icon.removeClass "fa-caret-down"
        icon.addClass "fa-caret-right"

    ###
    # @param [Number] index
    # @param [Boolean] forceState
    #   @optional
    ###
    toggleActorVisibilityByIndex: (index, forceState) ->
      param.required index

      actor = @_actors[index]
      return unless actor
      bodySelector = @_actorBodySelector(actor)
      iconSelector = "#{bodySelector} .visibility i"

      if forceState != null and forceState != undefined
        actor.setVisible forceState
      else
        actor.setVisible !actor.getVisible()

      $(iconSelector).toggleClass "fa-eye", actor.getVisible()


    ###
    # @param [BaseActor] actor
    # @param [Boolean] forceState
    ###
    toggleActorExpand: (actor, forceState) ->
      param.required actor

      id = actor.getActorId()
      actorIndex = _.findIndex @_actors, (a) -> a.getActorId() == id
      @toggleActorExpandByIndex actorIndex , forceState

    ## ACTION

    ###
    # Register actor, causes it to appear on the timeline starting from the
    # current cursor position.
    #
    # @param [BaseActor] actor
    ###
    addActor: (actor) ->
      param.required actor

      ## screw it!
      #if actor.constructor.name.indexOf("Actor") == -1
      #  throw new Error "Actor must be an instance of BaseActor!"

      @_actors.push actor
      @refresh()
      @_updateScrollbar()

      true

    ###
    # Remove an actor by id, re-renders timeline internals. Note that this
    # utilizies the ID of the AJS actor!
    #
    # @param [BaseActor] actor
    # @return [Boolean] success
    ###
    removeActor: (actor) ->
      param.required actor

      id = actor.getActorId()
      actorIndex = _.findIndex @_actors, (a) -> a.getActorId() == id
      return false unless actorIndex != -1

      @_actors.splice actorIndex, 1

      @refresh()
      @_updateScrollbar()

      true

    ###
    # Sets the actor as the currently selected and highlights it
    # @param [BaseActor] actor
    ###
    selectActor: (actor) ->
      @_lastSelectedActor = param.required actor
      $("#{@_actorBodySelector(actor)} .actor-info").addClass("selected")

    ###
    # Clears the actor selection
    # @param [BaseActor] actor
    ###
    deselectActor: (actor) ->
      param.required actor
      $("#{@_actorBodySelector(actor)} .actor-info").removeClass("selected")

    ###
    # @param [BaseActor] actor
    ###
    switchSelectedActor: (actor) ->
      param.required actor

      @deselectActor @_lastSelectedActor if @_lastSelectedActor
      @selectActor actor

    ###
    # @param [Number] index
    ###
    switchSelectedActorByIndex: (index) -> @switchSelectedActor @_actors[index]

    ###
    # Updates the state of the timeline toggle icons and storage
    ###
    updateVisible: ->
      Storage.set "timeline.visible", @_visible
      @getElement(".button.toggle i").toggleClass config.icon.toggle_down, @_visible
      @getElement(".button.toggle i").toggleClass config.icon.toggle_up, !@_visible

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

      @_visible = true

      if animate
        @getElement().animate { height: @_height },
          duration: 300
          easer: "swing"
          progress: => @ui.pushEvent "timeline.showing"
          done: => @ui.pushEvent "timeline.show"
      else
        @getElement().height @_height
        @ui.pushEvent "timeline.show"

      @updateVisible()

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

      @_visible = false

      if animate
        @getElement().animate { height: @_hiddenHeight },
          duration: 300
          easer: "swing"
          progress: => @ui.pushEvent "timeline.hiding"
          done: => @ui.pushEvent "timeline.hide"
      else
        @getElement().height @_hiddenHeight
        @ui.pushEvent "timeline.hide"

      @updateVisible()

    ## CALC

    ###
    # @param [BaseActor]
    # @return [Object]
    #   @property [Number] spaceW
    #   @property [Number] start
    #   @property [Number] length
    # @private
    ###
    _calcActorTimebar: (actor) ->
      param.required actor
      spaceW = $(@_spaceSelector()).width()
      {
        spaceW: spaceW
        start: spaceW * (actor.lifetimeStart_ms / @_duration)
        length: spaceW * ((actor.lifetimeEnd_ms - actor.lifetimeStart_ms) / @_duration)
      }

    ###
    # @return [Object]
    #   @property [Array<Object>] *
    #     @property [String] id
    #     @property [Number] left
    # @private
    ###
    _calcActorKeyframes: (actor, timebarData) ->
      param.required actor
      param.required timebarData

      actorId = actor.getID()

      keyframes =
        opacity: []
        position: []
        rotation: []
        color: []
        #physics: []

      _animations = actor.getAnimations()

      for time, anim of _animations
        offset = timebarData.spaceW *
                 ((Number(time) - actor.lifetimeStart_ms) / @_duration)

        if anim.opacity
          keyframes["opacity"].push
            id: "actor-#{actorId}-key-opacity-#{keyframes["opacity"].length}"
            left: offset
            time: time

        if anim.position
          keyframes["position"].push
            id: "actor-#{actorId}-key-position-#{keyframes["position"].length}"
            left: offset
            time: time

        if anim.rotation
          keyframes["rotation"].push
            id: "actor-#{actorId}-key-rotation-#{keyframes["rotation"].length}"
            left: offset
            time: time

        if anim.color
          keyframes["color"].push
            id: "actor-#{actorId}-key-color-#{keyframes["color"].length}"
            left: offset
            time: time

      keyframes

    ###
    # @return [Array<Object>]
    #   @property [String] id
    #   @property [Boolean] isProperty
    #   @property [Number] left
    #     @optional
    #   @property [Number] width
    #     @optional
    #   @property [Array<Object>] keyframes
    #     @optional
    #     @property [String] id
    #     @property [Number] left
    # @private
    ###
    _calcActorTimeProperties: (actor) ->
      param.required actor

      actorId = actor.getID()
      timebarData = @_calcActorTimebar actor
      keyframes = @_calcActorKeyframes actor, timebarData

      properties = []
      # The actor's timebar
      properties.push
        id: "actor-time-bar-#{actorId}"
        isProperty: false
        left: timebarData.start
        width: timebarData.length

      properties.push
        id: "actor-time-property-opacity-#{actorId}"
        name: "opacity"
        isProperty: true
        keyframes: keyframes["opacity"]

      properties.push
        id: "actor-time-property-position-#{actorId}"
        name: "position"
        isProperty: true
        keyframes: keyframes["position"]

      properties.push
        id: "actor-time-property-rotation-#{actorId}"
        name: "rotation"
        isProperty: true
        keyframes: keyframes["rotation"]

      properties.push
        id: "actor-time-property-color-#{actorId}"
        name: "color"
        isProperty: true
        keyframes: keyframes["color"]

      #properties.push
      #  id: "actor-time-property-physics-#{actorId}"
      #  isProperty: true
      #  keyframes: keyframes["physics"]

      properties

    ## RENDER

    ###
    # Appends a single actor to the actor list, used after registering an actor
    # and rendering their timebar
    #
    # @param [BaseActor] actor
    # @param [Boolean] apply optional, if false we only return the render HTML
    # @privvate
    ###
    _renderActorListEntry: (actor) ->
      param.required actor

      TemplateTimelineActor
        id: "actor-body-#{actor.getID()}"
        actorId: actor.getID()
        index: _.findIndex @_actors, (a) -> a.getID() == actor.getID()
        title: actor.getName()
        properties: [
          id: "opacity"
          title: "Opacity"
          value: aformat.num actor.getOpacity(), 2
        ,
          id: "position"
          title: "Position"
          value: aformat.pos actor.getPosition(), 0
        ,
          id: "rotation"
          title: "Rotation"
          value: aformat.degree actor.getRotation(), 2
        ,
          id: "color"
          title: "Color"
          value: aformat.color actor.getColor(), 2
        ]

    ###
    # Render the actor list Should never be called by itself, only by @render()
    #
    # @private
    ###
    _renderActorList: ->
      @_actors.map (actor) =>
        @_renderActorListEntry actor, false
      .join ""

    ###
    # Renders an individual actor timebar, used when registering new actors,
    # preventing a full re-render of the space. Also called internally by
    # @_renderActorTimeSpace.
    #
    # @param [BaseActor] actor
    # @param [Boolean] apply optional, if false we only return the render HTML
    # @return [HTML]
    # @private
    ###
    _renderActorTimebarEntry: (actor) ->
      param.required actor

      actorId = actor.getID()
      index = _.findIndex @_actors, (a) -> a.getID() == actorId

      return false unless @_checkActorLifetime actor

      properties = @_calcActorTimeProperties actor

      ##
      ## TODO: Check that something has actually changed before sending the HTML
      ##

      TemplateTimelineActorTime
        id: "actor-time-#{actorId}"
        actorid: actorId
        index: index
        properties: properties

    ###
    # Render the timeline space. Should never be called by itself, only by
    # @render()
    # @return [Void]
    # @private
    ###
    _renderActorTimebar: ->
      @_actors.map (actor) =>
        @_renderActorTimebarEntry actor, false
      .join ""

    ###
    # Proper render function, fills in timeline internals. Since we have two
    # distinct sections, each is rendered by a seperate function. This helps
    # divide the necessary logic, into @_renderActorList() and @_renderActorTimebar().
    # This function simply calls both.
    # @return [String]
    ###
    render: ->
      options =
        id: "timeline-header"
        timelineId: @getID()
        currentTime: "0:00.00"
        contents: @_renderActorList()
        timeContents: @_renderActorTimebar()

      super() +
      TemplateTimelineBase options

    ###
    # @return [self]
    ###
    refresh: ->
      super()
      @_setupScrollbar()
      @updateVisible()
      @

    ###
    # @return [self]
    ###
    postRefresh: ->
      super()

    ## UPDATE

    ###
    # Update the size and position of the scrollbar
    # @return [Void]
    ###
    _updateScrollbar: ->
      @_scrollbarElement().perfectScrollbar "update"
      @

    ###
    # Update displayed cursor time
    # @private
    ###
    _updateCursorTime: ->
      ms = @getCursorTime()

      seconds = ms / 1000.0
      minutes = seconds / 60.0
      timeText = "#{(minutes % 60).toFixed()}:#{(seconds % 60).toFixed(2)}"

      $("#timeline-cursor-time").text timeText

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
    # Update the state of the actor body
    # @return [Void]
    ###
    updateActorBody: (actor) ->
      actor = param.optional actor, @_lastSelectedActor
      return unless actor

      pos = actor.getPosition()
      color = actor.getColor()
      rotation = actor.getRotation()
      opacity = actor.getOpacity()

      bodySelector = @_actorBodySelector actor
      bodyElement = $(bodySelector)

      titleElement = bodyElement.find(".actor-info > .title")
      opacityElement = bodyElement.find(".property#opacity")
      positionElement = bodyElement.find(".property#position")
      rotationElement = bodyElement.find(".property#rotation")
      colorElement = bodyElement.find(".property#color")

      titleElement.text actor.getName()
      opacityElement.find(".value").text aformat.num opacity, 2
      positionElement.find(".value").text aformat.pos pos, 0
      rotationElement.find(".value").text aformat.degree rotation, 2
      colorElement.find(".value").text aformat.color color, 2

      ##
      # Live buttons - always active
      opacityElement.find(".live .button").toggleClass "active", true
      positionElement.find(".live .button").toggleClass "active", true
      rotationElement.find(".live .button").toggleClass "active", true
      colorElement.find(".live .button").toggleClass "active", true

    ###
    # Update the state of the actor timebar
    # @return [Void]
    ###
    updateActorTime: (actor) ->
      actor = param.optional actor, @_lastSelectedActor
      return unless actor

      timeSelector = @_actorTimeSelector actor
      properties = @_calcActorTimeProperties actor

      for property in properties
        if property.isProperty
          keyframes = property.keyframes

          ## hard refresh
          elem = $("#{timeSelector} ##{property.id}")
          elem.empty()

          for keyframe in keyframes
            elem.append TemplateTimelineKeyframe
              id: keyframe.id
              index: keyframe.index
              property: property.name
              time: keyframe.time
              left: keyframe.left

          ## soft refresh (and it doesnt work)
          #elems = $("#{timeSelector} ##{property.id} keyframe")
          ## adjust the size of the keyframes container
          #if keyframes.length < elems.length
          #  diff = elems.length - keyframes.length
          #  for i in [0...diff]
          #    elems.remove(elems[0])
          #else if keyframes.length > elems.length
          #  diff = keyframes.length - elems.length
          #  for i in [0...diff]
          #    elems.append TemplateTimelineKeyframe
          #      id: "placeholder"
          #      left: 0
          #$("#{timeSelector} ##{property.id} keyframe").each (index, e) ->
          #  keyframe = keyframes[index]
          #  e.attr "id", keyframe.id
          #  e.css left: keyframe.left

        else
          $("#{timeSelector} ##{property.id} .bar").css
            left: "#{property.left}px"
            width: "#{property.width}px"

      ###
      ## Hard Refresh
      ###
      #@_renderActorTimebar actor
      ####
      ## Sadly, when a refresh takes place the timebar's expanded state
      ## is reset, so we need to update it, in a rather crude way...
      ####
      #bodySelector = @_actorBodySelector actor
      #@toggleActorExpand actor, $(bodySelector).hasClass("expanded")

    ###
    # Called by actors, for updating its Timeline state
    # this is a much gentle way of updating the data, instead of rendering
    # over the HTML content
    # @friend [BaseActor]
    # @param [BaseActor] actor
    # @private
    ###
    updateActor: (actor) ->
      actor = param.optional actor, @_lastSelectedActor
      return unless actor

      @updateActorBody actor
      @updateActorTime actor

    ###
    # Updates all actors in the timeline
    ###
    _updateAll: ->
      for actor in @_actors
        @updateActor actor

    ## EVENTS

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      switch type
        when "workspace.add.actor"
          @addActor params.actor
        when "workspace.remove.actor"
          @removeActor params.actor
        when "workspace.selected.actor"
          @switchSelectedActor params.actor
          @updateActor params.actor
        when "property.bar.update.actor"
          @updateActor params.actor
        when "actor.update.intime"
          @updateActor params.actor
        when "renamed.actor"
          @updateActor params.actor
        when "selected.actor.update"
          @updateActor params.actor


    ## Serialization

    ###
    # @return [Object] data
    ###
    dump: ->
      _.extend super(),
        timelineVersion: "1.1.0"
        duration: @getDuration()
        current: @getCursorTime()

    ###
    # @param [Object] data
    ###
    load: (data) ->
      super data
      # data.timelineVersion >= "1.0.0"
      @setDuration data.duration
      @setCursorTime data.current

###
@Changlog

  - "1.0.0": Initial
  - "1.1.0": ???

###