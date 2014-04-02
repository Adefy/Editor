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
  TimelineKeyframeTemplate = require "templates/timeline/keyframe"
  ModalSetPreviewFPSTemplate = require "templates/modal/set_preview_fps"

  Storage = require "storage"

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
    constructor: (@ui, duration) ->
      return unless @enforceSingleton()

      super
        id: ID.prefId("timeline")
        parent: "footer"
        classes: ["timeline"]

      @_duration = Number param.optional(duration, 5000)
      @_control = new TimelineControl @

      @_previewFPS = 30
      @_visible = true

      @controlState =
        fast_backward: false
        backward: false
        play: false
        forward: false
        fast_forward: false

      # Actor array, access through registerActor/removeActor
      @_actors = []

      # Check for any existing padding on the body (and format accordingly)
      if $("body").css("padding-bottom") == "auto"
        @_bodyPadding = 0
      else
        @_bodyPadding = $("body").css("padding-bottom").split("px").join ""

      @resize 256

      @_renderStructure()
      @_updateCursorTime()

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
      "#{@_bodySelector()} #actor-body-#{actor.getId()}.actor"

    ###
    # @param [BaseActor] actor
    ###
    _actorTimeSelector: (actor) ->
      "#{@_spaceSelector()} #actor-time-#{actor.getId()}.actor"

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
    # Return current cursor time in ms (relative to duration)
    #
    # @return [Number] time cursor time in ms
    ###
    getCursorTime: ->
      @_duration * ($("#timeline-cursor").position().left /
                    $(@_spaceSelector()).width())

    ###
    # Set an arbitrary cursor time
    #
    # @param [Number] time cursor time in ms
    ###
    setCursorTime: (time) ->
      param.required time

      $("#timeline-cursor").css "left", $(@_spaceSelector()).width() * (time / @_duration)

      @_onCursorDrag()
      @_onCursorDragStop()

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

    ###
    # Cursor drag event
    #
    # @param [Event] e
    # @param [Object] ui
    # @private
    ###
    _onCursorDrag: (e, ui) -> @_updateCursorTime()

    ###
    # Cursor drag stop event, updates all living
    #
    # @param [Event] e
    # @param [Object] ui
    # @private
    ###
    _onCursorDragStop: (e, ui) ->
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
    # Registers event listeners
    # @private
    ###
    _regListeners: ->

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

      $("#timeline-cursor").draggable
        axis: "x"
        containment: "parent"
        drag: (e, ui) =>

          # Cancel the drag if we are currently in the middle of playback
          return false if @_playbackID != undefined and @_playbackID != null

          @_onCursorDrag e, ui

        stop: (e, ui) =>
          @_onCursorDragStop e, ui

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
    registerActor: (actor) ->
      param.required actor

      if actor.constructor.name.indexOf("Actor") == -1
        throw new Error "Actor must be an instance of BaseActor!"

      @_actors.push actor
      @_renderActorTimebar _.last @_actors
      @_renderActorListEntry _.last @_actors
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

      @_renderActorList()
      @_renderSpace()
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
        @getElement().animate height: @_height, 300, "swing", =>
          @ui.pushEvent "timeline.show"
      else
        @getElement().height @_height
        @ui.pushEvent "timeline.show"

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
        @getElement().animate height: @_hiddenHeight, 300, "swing", =>
          @ui.pushEvent "timeline.hide"
      else
        @getElement().height @_hiddenHeight
        @ui.pushEvent "timeline.hide"

      ##
      # I'm sure jQuery's toggle class can do this, but I still haven't
      # figured it out properly
      @getElement(".button.toggle i").removeClass("fa-arrow-down")
      @getElement(".button.toggle i").addClass("fa-arrow-up")

      Storage.set "timeline.visible", false
      @_visible = false

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

      actorId = actor.getId()

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
            id: "key-#{keyframes["opacity"].length}"
            left: offset

        if anim.position
          keyframes["position"].push
            id: "key-#{keyframes["position"].length}"
            left: offset

        if anim.rotation
          keyframes["rotation"].push
            id: "key-#{keyframes["rotation"].length}"
            left: offset

        if anim.color
          keyframes["color"].push
            id: "key-#{keyframes["color"].length}"
            left: offset

        #if anim.components.physics
        #  keyframes["physics"].push
        #    id: "physics-#{actorId}-key-#{keyframes["physics"].length}"
        #    left: offset

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

      actorId = actor.getId()
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
        isProperty: true
        keyframes: keyframes["opacity"]

      properties.push
        id: "actor-time-property-position-#{actorId}"
        isProperty: true
        keyframes: keyframes["position"]

      properties.push
        id: "actor-time-property-rotation-#{actorId}"
        isProperty: true
        keyframes: keyframes["rotation"]

      properties.push
        id: "actor-time-property-color-#{actorId}"
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
    _renderActorListEntry: (actor, apply) ->
      param.required actor
      apply = param.optional apply, true

      html = TimelineActorTemplate
        id: "actor-body-#{actor.getId()}"
        actorId: actor.getId()
        index: _.findIndex @_actors, (a) -> a.getId() == actor.getId()
        title: actor.name
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

      if apply
        $(@_bodySelector()).append html
        @updateActorBody(actor)
      else
        html

    ###
    # Render the actor list Should never be called by itself, only by @render()
    #
    # @private
    ###
    _renderActorList: ->
      entriesHTML = @_actors.map (actor) => @_renderActorListEntry actor, false

      $(@_bodySelector()).html entriesHTML.join ""

    ###
    # Renders an individual actor timebar, used when registering new actors,
    # preventing a full re-render of the space. Also called internally by
    # @_renderSpace.
    #
    # @param [BaseActor] actor
    # @param [Boolean] apply optional, if false we only return the render HTML
    # @return [HTML]
    # @private
    ###
    _renderActorTimebar: (actor, apply) ->
      param.required actor
      apply = param.optional apply, true

      actorId = actor.getId()
      index = _.findIndex @_actors, (a) -> a.getId() == actorId

      return false unless @_checkActorLifetime actor

      properties = @_calcActorTimeProperties actor

      ##
      ## TODO: Check that something has actually changed before sending the HTML
      ##

      html = TimelineActorTimeTemplate
        id: "actor-time-#{actorId}"
        actorid: actorId
        index: index
        properties: properties

      if apply
        if $("#actor-time-#{actorId}").length
          $("#actor-time-#{actorId}").html html
        else
          $("#{@_spaceSelector()} .time-actors").append html
      else
        html

    ###
    # Render the timeline space. Should never be called by itself, only by
    # @render()
    # @return [Void]
    # @private
    ###
    _renderSpace: ->
      entriesHTML = @_actors.map (actor) => @_renderActorTimebar actor, false

      $("#{@_spaceSelector()} .time-actors").html entriesHTML.join ""

    ###
    # Render initial structure.
    # Note that calling this clears the timeline visually, and does not render
    # objects! Objects are not destroyed, call @render to update them.
    # @return [Void]
    ###
    _renderStructure: ->
      options =
        id: "timeline-header"
        timelineId: @getId()
        currentTime: "0:00.00"

      @getElement().html TimelineBaseTemplate options

    ###
    # Proper render function, fills in timeline internals. Since we have two
    # distinct sections, each is rendered by a seperate function. This helps
    # divide the necessary logic, into @_renderActorList() and @_renderSpace().
    # This function simply calls both.
    # @return [Void]
    ###
    render: ->
      @_renderActorList()
      @_renderSpace()
      @_setupScrollbar()

    ## UPDATE

    ###
    # Update the size and position of the scrollbar
    # @return [Void]
    ###
    _updateScrollbar: ->
      @_scrollbarElement().perfectScrollbar "update"

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

      opacityElement = bodyElement.find(".property#opacity")
      positionElement = bodyElement.find(".property#position")
      rotationElement = bodyElement.find(".property#rotation")
      colorElement = bodyElement.find(".property#color")

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
            elem.append TimelineKeyframeTemplate
              id: keyframe.id
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
          #    elems.append TimelineKeyframeTemplate
          #      id: "placeholder"
          #      left: 0
          #$("#{timeSelector} ##{property.id} keyframe").each (index, e) ->
          #  keyframe = keyframes[index]
          #  e.attr "id", keyframe.id
          #  e.css left: keyframe.left

        else
          $("#{timeSelector} ##{property.id}").css
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
          @registerActor params.actor
        when "workspace.remove.actor"
          @removeActor params.actor
        when "workspace.selected.actor"
          @switchSelectedActor params.actor
          @updateActor params.actor
        when "tab.properties.update.actor"
          @updateActor params.actor
        when "selected.actor.changed"
          @updateActor()
        when "actor.update.intime"
          @updateActorBody params.actor

    ## MODALS

    ###
    # Show dialog box for setting the preview framerate
    # @return [Modal]
    ###
    showSetPreviewRate: ->

      # Randomized input name
      name = ID.prefId "_tPreviewRate"

      _html = ModalSetPreviewFPSTemplate
        previewFPS: @getPreviewFPS()
        name: name

      new Modal
        title: "Set Preview Framerate"
        content: _html
        modal: false
        cb: (data) => @_previewFPS = data[name]
        validation: (data) ->
          return "Framerate must be a number" if isNaN data[name]
          return "Framerate must be > 0" if data[name] <= 0
          true