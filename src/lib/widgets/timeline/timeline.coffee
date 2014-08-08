define (require) ->

  config = require "config"
  param = require "util/param"

  ID = require "util/id"
  AUtilLog = require "util/log"
  aformat = require "util/format"
  Widget = require "widgets/widget"
  ContextMenu = require "widgets/context_menu"
  TimelineControl = require "widgets/timeline/timeline_control"
  Workspace = require "widgets/workspace"

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
      options ||= {}
      return unless @enforceSingleton()

      super @ui,
        id: ID.prefID("timeline")
        parent: config.selector.footer
        classes: ["timeline"]

      @_duration = Number(options.duration || 5000)

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

      @_bindListeners()

    ###
    # @return [Timeline] self
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
      unless duration > 0
        return AUtilLog.error "Invalid duration: #{duration}"

      @_duration = duration
      @regenerateTimelineTicks()

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
      if $("#timeline-cursor").length > 0
        @_duration * ($("#timeline-cursor").position().left /
                      $(@_spaceSelector()).width())
      else
        0

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
      100 * (time / @_duration)

    ###
    # Set an arbitrary cursor time
    #
    # @param [Number] time cursor time in ms
    ###
    setCursorTime: (time) ->
      $("#timeline-cursor").css "left", "#{(100 * (time / @_duration))}%"

      setTimeout =>
        @_updateCursorTime()
        @updateAllActorsInTime()
      , 0

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

    updateAllActorsInTime: ->
      t = @getCursorTime()
      a.seekToTime t for a in @_actors

    ###
    # @param [jQuery] element
    # @private
    ###
    _onOuterClicked: (element) ->
      index = Number $(element).attr "data-index"

      @switchSelectedActorByIndex index
      @ui.pushEvent "timeline.selected.actor", actor: @_actors[index]

    ###
    # Setup keyframe Dragger
    # @private
    ###
    _bindKeyframeDragging: ->
      return if @keyframeDragger

      @keyframeDragger = new Dragger ".actor .property-keyframes > .keyframe"
      @keyframeDragger.setOnDragStart (d) ->
        d.setUserData "startTime": Number $(d.getTarget()).attr "data-time"

      # Vertical component is ignored
      @keyframeDragger.setOnDrag (d, deltaX, deltaY) =>

        id = $(d.getTarget()).attr "id"
        keyframeTime = d.getUserDataValue "startTime"
        targetTime = keyframeTime + (deltaX * @getTimePerPixel())

        ###
        # Cache the actor to speed things up
        ###
        unless d.getUserDataValue "actor"
          actorId = $(d.getTarget()).closest(".actor").attr "data-actorid"
          actor = _.find @_actors, (a) -> a.getID() == actorId

          return AUtilLog.error "Invalid actor: #{actorId}" unless actor

          d.setUserDataValue "actor", actor
        else
          actor = d.getUserDataValue "actor"

        propertyName = $(d.getTarget()).attr "data-property"
        property = actor.getProperty propertyName
        return AUtilLog.error "Invalid property: #{property}" unless property

        ###
        # Cache keyframe boundary information
        ###
        unless d.getUserDataValue "boundaries"
          boundaries =
            left: property.getNearestTimeLeft keyframeTime
            right: property.getNearestTimeRight keyframeTime

          d.setUserDataValue "boundaries", boundaries
        else
          boundaries = d.getUserDataValue "boundaries"

        return if targetTime > boundaries.right or targetTime < boundaries.left

        source = d.getUserDataValue("lastUpdate") or keyframeTime

        ###
        # Actual keyframe transplant. Yay
        ###
        property.moveKeyframe source, targetTime
        actor.reseek()

        d.setUserDataValue "lastUpdate", Math.floor targetTime

        # Update target
        d.setTarget $("##{id}")

        # Update keyframe
        $(d.getTarget()).attr "data-time", Math.floor targetTime
        $(d.getTarget()).css left: "#{@getOffsetForTime targetTime}%"

    ###
    # Setup keyframe Dragger
    # @private
    ###
    _bindTimebarDragging: ->
      @timebarDragger = new Dragger ".time .actor .bar"

      @timebarDragger.setCheckDrag (e) -> e.shiftKey

      @timebarDragger.setOnDragStart (d) ->
        target = $(d.getTarget())
        startTime = Number(target.attr "data-start")
        endTime = Number(target.attr "data-end")
        d.setUserData "startTime": startTime, "endTime": endTime

      # Vertical component is ignored
      @timebarDragger.setOnDrag (d, deltaX, deltaY) =>

        target = $(d.getTarget())
        id = target.attr "id"

        # Cache the actor to speed things up
        if d.getUserDataValue "actor"
          actor = d.getUserDataValue "actor"
        else
          actorId = target.closest(".actor").attr "data-actorid"
          actor = _.find @_actors, (a) -> a.getID() == actorId

          return AUtilLog.error "Invalid actor: #{actorId}" unless actor

          d.setUserDataValue "actor", actor

        # Cache keyframe boundary information
        if d.getUserDataValue "boundaries"
          boundaries = d.getUserDataValue "boundaries"
        else
          boundaries =
            left: 0
            right: @getDuration()

          d.setUserDataValue "boundaries", boundaries

        startTime = d.getUserDataValue "startTime"
        endTime = d.getUserDataValue "endTime"
        property = target.parent().attr("data-property")
        targetTime = startTime
        targetTimeEnd = endTime

        # adjust starting point only
        if d.modifiers.ctrlKey
          targetTime = startTime + (deltaX * @getTimePerPixel())
        # adjust ending point only
        else if d.modifiers.altKey
          targetTimeEnd = endTime + (deltaX * @getTimePerPixel())
        # move timebar
        else
          targetTime = startTime + (deltaX * @getTimePerPixel())
          targetTimeEnd = targetTime + (endTime - startTime)
          return if targetTimeEnd > boundaries.right or targetTime < boundaries.left

        # Update keyframe
        target.attr "data-start", Math.floor targetTime
        target.attr "data-end", Math.floor targetTimeEnd
        target.css
          left: "#{@getOffsetForTime targetTime}%"
          width: "#{@getOffsetForTime targetTimeEnd - targetTime}%"

      @timebarDragger.setOnDragEnd (d) =>
        actor = d.getUserDataValue "actor"
        elem = $(d.getTarget())
        startTime = Number elem.attr "data-start"
        endTime = Number elem.attr "data-end"
        actor.adjustLifetime(start: startTime, end: endTime)
        actor.updateInTime()

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
    _bindListeners: ->

      @_bindContextClick()
      @_bindKeyframeDragging()
      @_bindTimebarDragging()

      $(document).on "click", ".timeline .control.right", (e) =>
        @toggle()

      $(document).on "click", ".timeline .list .actor .expand", (e) =>
        @_onActorToggleExpand $(e.target).closest ".actor"

      $(document).on "click", ".timeline .list .actor .visibility", (e) =>
        @_onActorToggleVisible $(e.target).closest ".actor"

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
      @_cursorDraggable.constrainToElement ".timeline .content .time"

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
    # Clear out and re-generate the time ticks at the top of the timeline
    ###
    regenerateTimelineTicks: ->
      container = @getElement ".time-delimit"
      timeSpace = @_spaceSelector()

      tickValue = @_duration / 10
      tickWidth = $(timeSpace).width() / 10

      container.html ""

      for i in [0...10]
        container.append """
        <div class="tick" style="width: #{tickWidth}px">
          <div class="tick-visual"></div>
          <div class="tick-value">#{((tickValue * i) / 1000).toFixed 2}s</div>
        </div>
        """

    ###
    # @param [Number] index
    # @param [Boolean] forceState
    #   @optional
    ###
    toggleActorExpandByIndex: (index, forceState) ->

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
      @_actors.push actor

      listEntry = @_renderActorListEntry actor
      timebarEntry = @_renderActorTimebarEntry actor

      if actor.isAnimated()
        animatedClass = "animated-actors"
      else
        animatedClass = "static-actors"

      @getElement(".timeline-actor-list.#{animatedClass}").append listEntry
      @getElement(".time-#{animatedClass}").append timebarEntry

      @_updateScrollbar()

      true

    ###
    # Remove an actor by id, re-renders timeline internals. Note that this
    # utilizies the ID of the ARE actor!
    #
    # @param [BaseActor] actor
    # @return [Boolean] success
    ###
    removeActor: (actor) ->

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
      @_lastSelectedActor = actor
      $("#{@_actorBodySelector(actor)} .actor-info").addClass("selected")

    ###
    # Clears the actor selection
    # @param [BaseActor] actor
    ###
    deselectActor: (actor) ->
      $("#{@_actorBodySelector(actor)} .actor-info").removeClass("selected")

    ###
    # @param [BaseActor] actor
    ###
    switchSelectedActor: (actor) ->
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
      @getElement(".control.right i").toggleClass config.icon.toggle_down, @_visible
      @getElement(".control.right i").toggleClass config.icon.toggle_up, !@_visible

    ###
    # Toggle visibility of the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to false
    ###
    toggle: (cb, animate) ->
      animate = true unless animate = false

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
      animate = true unless animate = false

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
      animate = true unless animate = false

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

      #spaceW = $(@_spaceSelector()).width()
      {
        #spaceW: spaceW
        start: actor.getBirthTime()
        end: actor.getDeathTime()
        left: "#{100 * (actor.getBirthTime() / @_duration)}%"
        length: "#{100 * ((actor.getDeathTime() - actor.getBirthTime()) / @_duration)}%"
      }

    ###
    # @return [Object] keyframes
    # @private
    ###
    _calcActorKeyframes: (actor, timebarData) ->
      actorId = actor.getID()

      keyframesProcessed =
        opacity: []
        position: []
        rotation: []
        color: []

      keyframes = actor.getKeyframes()
      uniqueFrameID = 0

      for time, frameset of keyframes
        offset = 100 * Number(time) / @_duration
        offset = "#{offset}%"

        for frame in frameset
          uniqueFrameID++

          if frame.property == "opacity"
            keyframesProcessed.opacity.push
              id: "#{actorId}-opacity-#{uniqueFrameID}"
              left: offset
              time: time
              name: "opacity"

          if frame.property == "position"
            keyframesProcessed.position.push
              id: "#{actorId}-position-#{uniqueFrameID}"
              left: offset
              time: time
              name: "position"

          if frame.property == "rotation"
            keyframesProcessed.rotation.push
              id: "#{actorId}-rotation-#{uniqueFrameID}"
              left: offset
              time: time
              name: "rotation"

          if frame.property == "color"
            keyframesProcessed.color.push
              id: "#{actorId}-color-#{uniqueFrameID}"
              left: offset
              time: time
              name: "color"

      keyframesProcessed

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

      actorId = actor.getID()
      timebarData = @_calcActorTimebar actor
      keyframes = @_calcActorKeyframes actor, timebarData

      [
        id: "actor-time-property-opacity-#{actorId}"
        name: "opacity"
        keyframes: keyframes.opacity
      ,
        id: "actor-time-property-position-#{actorId}"
        name: "position"
        keyframes: keyframes.position
      ,
        id: "actor-time-property-rotation-#{actorId}"
        name: "rotation"
        keyframes: keyframes.rotation
      ,
        id: "actor-time-property-color-#{actorId}"
        name: "color"
        keyframes: keyframes.color
      ]

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
    # Render a list of actors for the detail view.
    #
    # @param [Array<BaseActor>] actors
    # @return [Array<String>] HTML individually rendered actor entries
    # @private
    ###
    _renderActorList: (actors) ->
      @_actors.map (actor) =>
        @_renderActorListEntry actor

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
      actorId = actor.getID()
      index = _.findIndex @_actors, (a) -> a.getID() == actorId

      properties = @_calcActorTimeProperties actor
      timebarData = @_calcActorTimebar actor
      keyMarkers = @_getKeyframeMarkerTimes properties

      ##
      ## TODO: Check that something has actually changed before sending the HTML
      ##

      TemplateTimelineActorTime
        id: "actor-time-#{actorId}"
        actorid: actorId
        index: index
        keyframeIndicators: keyMarkers
        properties: properties
        left: timebarData.left
        width: timebarData.length
        start: timebarData.start
        end: timebarData.end

    ###
    # Generate a list of keyframe marker times for an array of properties. These
    # times signify the position on the timebar where a marker should be shown.
    #
    # @param [Array<Object>] properties
    # @return [Array<Number>] markers
    ###
    _getKeyframeMarkerTimes: (properties) ->
      keyframeLists = _.map properties, (p) -> p.keyframes.map (k) -> k?.left
      _.uniq _.reduce keyframeLists, (all, keys) -> all.concat keys

    ###
    # Render an array of actor timebars
    #
    # @param [Array<BaseActor>] actors
    # @return [Array<String>] HTML individually rendered actor timebars
    # @private
    ###
    _renderActorTimebars: (actors) ->
      actors.map (actor) =>
        @_renderActorTimebarEntry actor

    ###
    # Proper render function, fills in timeline internals.
    #
    # @return [String] html
    ###
    render: ->

      animatedActors = _.filter @_actors, (a) -> a.isAnimated()
      staticActors = _.filter @_actors, (a) -> !a.isAnimated()

      options =
        id: "timeline-header"
        timelineId: @getID()
        currentTime: @_generateTimeString()
        staticActorList: @_renderActorList staticActors
        animatedActorList: @_renderActorList animatedActors
        staticActorTimebars: @_renderActorTimebars staticActors
        animatedActorTimebars: @_renderActorTimebars animatedActors

      super() +
      TemplateTimelineBase options

    ###
    # @return [Timeline] self
    ###
    refresh: ->
      super()
      @_setupScrollbar()
      @updateVisible()
      @

    ###
    # @return [Timeline] self
    ###
    postRefresh: ->
      super()
      @regenerateTimelineTicks()
      @

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
      $("#timeline-cursor-time").text @_generateTimeString()

    ###
    # Creates a string suitable for rendering
    #
    # @return [String] time_s
    ###
    _generateTimeString: ->
      ms = @getCursorTime()

      seconds = ms / 1000.0
      minutes = seconds / 60.0
      "#{(minutes % 60).toFixed()}:#{(seconds % 60).toFixed(2)}"

    ###
    # Update the state of the controls bar
    # @return [Timeline] self
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

      @

    ###
    # Update the state of the actor body
    #
    # @return [Timeline] self
    ###
    updateActorBody: (actor) ->
      actor ||= @_lastSelectedActor
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

      @

    ###
    # Update the state of the actor timebar
    #
    # @param [BaseActor] actor
    # @return [Timeline] self
    ###
    updateActorTime: (actor) ->
      actor ||= @_lastSelectedActor
      return unless actor

      @resizeActorTimebar actor
      @refreshActorKeyframes actor

      @

    ###
    # Update the extents of the actor's timebar
    #
    # @param [BaseActor] actor
    ###
    resizeActorTimebar: (actor) ->
      timebarData = @_calcActorTimebar actor

      timebar = @getElement "#{@_actorTimeSelector actor} .bar"
      timebar.css
        left: timebarData.left
        width: timebarData.length
      timebar.attr "data-start", timebarData.start
      timebar.attr "data-end",   timebarData.end

      @

    refreshActorKeyframes: (actor) ->
      properties = @_calcActorTimeProperties actor
      markers = @_getKeyframeMarkerTimes properties
      timeSelector = @_actorTimeSelector actor

      # Remove existing keyframe markers (from timebar and property rows)
      $("#{timeSelector} .keyframe").remove()

      for property in properties
        propertyContainer = $("#{timeSelector} ##{property.id}")

        # Re-generate them
        for keyframe in property.keyframes
          propertyContainer.append TemplateTimelineKeyframe
            id: keyframe.id
            property: keyframe.name
            time: keyframe.time
            left: keyframe.left

      for marker in markers
        $("#{timeSelector} .bar").append """
        <div style="left: #{marker}" class="keyframe"></div>
        """

      @

    ###
    # Called by actors, for updating its Timeline state
    # this is a much gentle way of updating the data, instead of rendering
    # over the HTML content
    # @friend [BaseActor]
    # @param [BaseActor] actor
    # @private
    ###
    updateActor: (actor) ->
      actor ||= @_lastSelectedActor
      return unless actor

      @updateActorBody actor
      @updateActorTime actor

    ###
    # Updates all actors in the timeline
    ###
    _updateAllActors: ->
      @updateActor actor for actor in @_actors

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
        when "sidebar.update.actor"
          @updateActor params.actor
        when "actor.update.intime"
          @updateActor params.actor unless @_playbackID
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
