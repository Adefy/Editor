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
  ModalSetPreviewFPSTemplate = require "templates/modal/set_preview_fps"

  Storage = require "storage"

  # Timeline widget, serving as the main control center for objects.
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

      @renderStructure()
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
    # @param [BaseActor] actor
    ###
    _actorTimeSelector: (actor) ->
      "#actor-time-#{actor.getId()}.actor"

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
      selectedId = Workspace.getSelectedActor()

      actor = _.find @_actors, (a) -> a.getId() == selectedId
      actor.updateInTime() if actor and actor.isAlive()

    ###
    # Kills the interval and NULLs the playbackID
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

    ###
    # When an actor expand button is pressed this function is called
    # @param [HTMLElement] element
    ###
    _onActorExpand: (element) ->
      index = $(element).attr("data-index")
      actor = @_actors[index]
      timeSelector = @_actorTimeSelector(actor)

      $(element).toggleClass "expanded"
      $(timeSelector).toggleClass "expanded", $(element).hasClass("expanded")

      icon = $(element).find ".expand i"

      if $(element).hasClass "expanded"
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
        if (t < a.lifetimeStart or t > a.lifetimeEnd) and a.isAlive()
          a.timelineDeath()

        else if a.isAlive() or (t >= a.lifetimeStart and t <= a.lifetimeEnd)
          a.updateInTime()

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
    # Registers event listeners
    # @private
    ###
    _regListeners: ->

      $(document).on "click", ".timeline .button.toggle", (e) =>
        @toggle()

      $(document).on "click", ".actor .expand", (e) =>
        @_onActorExpand $(e.target).closest ".actor"

      ##
      ## TODO: Move all of the control listeners into the timeline_control class
      ##

      # Outer timebar
      $(document).on "click", ".timeline .list .actor", (e) =>
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

      # Sidebar save button
      ## TODO: WTF is this? Likely we don't need it
      # $(document).on "click", ".asp-save", (e) => @_saveKey e

    ###
    # Return current cursor time in ms (relative to duration)
    #
    # @return [Number] time cursor time in ms
    ###
    getCursorTime: ->
      @_duration * ($("#timeline-cursor").position().left / $(@_spaceSelector()).width())

    ###
    # @param [HTMLElement] element
    # @private
    ###
    _onOuterClicked: (element) ->
      param.required element

      index = Number $(element).attr "data-index"

      @selectActorByIndex index
      @ui.pushEvent "timeline.selected.actor", actor: @_actors[index]

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
      index = @_actors.length-1
      @renderActorTimebar index
      @renderActorListEntry index

    ###
    # Remove an actor by id, re-renders timeline internals. Note that this
    # utilizies the ID of the AJS actor!
    #
    # @param [Number] id
    # @return [Boolean] success
    ###
    removeActor: (id) ->
      param.required id

      actorIndex = _.findIndex @_actors, (a) -> a.getActorId() == id
      return false unless actorIndex != -1

      @_actors.splice actorIndex, 1

      @renderActorList()
      @_renderSpace()

      true

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
    # @param [BaseActor] actor
    # @param [Boolean] apply optional, if false we only return the render HTML
    # @privvate
    ###
    renderActorListEntry: (index, apply) ->
      param.required index
      apply = param.optional apply, true

      actor = @_actors[index]

      html = TimelineActorTemplate
        id: "actor-body-#{actor.getId()}"
        actorId: actor.getId()
        index: index
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
        @_refreshActorRows()
      else
        html

    ###
    # Render the actor list Should never be called by itself, only by @render()
    #
    # @private
    ###
    renderActorList: ->
      entriesHTML = @_actors.map (actor, index) =>
        @renderActorListEntry index, false

      $(@_bodySelector()).html entriesHTML.join ""
      @_refreshActorRows()

    ###
    # Renders an individual actor timebar, used when registering new actors,
    # preventing a full re-render of the space. Also called internally by
    # @_renderSpace.
    #
    # @param [BaseActor] actor
    # @param [Boolean] apply optional, if false we only return the render HTML
    # @private
    ###
    renderActorTimebar: (index, apply) ->
      param.required index
      apply = param.optional apply, true

      spaceW = $(@_spaceSelector()).width()

      actor = @_actors[index]
      actorId = actor.getId()

      # TODO: Consider moving the following two checks into our registerActor
      #       method. The only possible concern with that is the fact that
      #       the lifetime can change outside of our supervision (it is public
      #       and whatnot).
      #
      #       A possible remedy to this would be to make the lifetime private,
      #       and only allow modification through ourselves. Hmmm....

      # Sanity check, actor must die after it is created
      if actor.lifetimeEnd < actor.lifetimeStart
        throw new Error "Actor lifetime end must come after lifetime start! " +\
                        "start: #{actor.lifetimeStart}, " +\
                        "end: #{actor.lifetimeEnd}"

      # Make sure actors' lifetime is contained in our duration!
      #
      # TODO: In the future, we can allow for actor deaths after our duration,
      #       to ease timeline resizing.
      if actor.lifetimeStart < 0 or actor.lifetimeEnd > @_duration
        throw new Error "Actor exists beyond our duration!"

      # Calculate actor x offset
      _start = spaceW * (actor.lifetimeStart / @_duration)
      _length = spaceW * ((actor.lifetimeEnd - actor.lifetimeStart) / @_duration)

      keyframes =
        opacity: []
        position: []
        rotation: []
        color: []
        #physics: []

      _animations = actor.getAnimations()
      for time, anim of _animations
        offset = spaceW * ((Number(time) - a.lifetimeStart) / @_duration)

        if anim.opacity
          keyframes["opacity"].push
            id: "opacity-#{actorId}-key-#{keyframes["opacity"].length}"
            left: offset

        if anim.position
          keyframes["position"].push
            id: "position-#{actorId}-key-#{keyframes["position"].length}"
            left: offset

        if anim.rotation
          keyframes["rotation"].push
            id: "rotation-#{actorId}-key-#{keyframes["rotation"].length}"
            left: offset

        if anim.color
          keyframes["color"].push
            id: "color-#{actorId}-key-#{keyframes["color"].length}"
            left: offset

        #if anim.components.physics
        #  keyframes["physics"].push
        #    id: "physics-#{actorId}-key-#{keyframes["physics"].length}"
        #    left: offset

      properties = []
      # The actor's timebar
      properties.push
        id: "actor-time-bar-#{actorId}"
        isProperty: false
        left: _start
        width: _length

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

      ##
      ## TODO: Check that something has actually changed before sending the HTML
      ##

      html = TimelineActorTimeTemplate
        id: "actor-time-#{actorId}"
        actorid: actorId
        index: index
        properties: properties

      if apply
        if $("#actor-time-#{aID}").length
          $("#actor-time-#{aID}").html html
        else
          $("#{@_spaceSelector()} .time-actors").append html
      else
        html

    ###
    # Render the timeline space. Should never be called by itself, only by
    # @render()
    #
    # @private
    ###
    _renderSpace: ->
      entriesHTML = @_actors.map (actor, index) =>
        @renderActorTimebar index, false

      $("#{@_spaceSelector()} .time-actors").html entriesHTML.join ""

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

      return @getElement().html TimelineBaseTemplate options

    ###
    # Proper render function, fills in timeline internals. Since we have two
    # distinct sections, each is rendered by a seperate method. This helps
    # divide the necessary logic, into @renderActorList() and @_renderSpace(). This
    # function simply calls both.
    ###
    render: ->
      @renderActorList()
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
      return unless actor

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

      @renderActorTimebar actor

    ###
    #
    # @param [BaseActor] actor
    # @private
    ###
    selectActor: (actor) ->
      @_lastSelectedActor = param.required actor
      $("#{@_actorBodySelector(actor)} .actor-info").addClass("selected")

    deselectActor: (actor) ->
      param.required actor
      $("#{@_actorBodySelector(actor)} .actor-info").removeClass("selected")

    switchSelectedActor: (actor) ->
      param.required actor

      @deselectActor @_lastSelectedActor if @_lastSelectedActor
      @selectActor actor

    ###
    # @param [Number] index
    ###
    selectActorByIndex: (index) -> @switchSelectedActor @_actors[index]

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
      if type == "workspace.add.actor"
        @registerActor params.actor
      else if type == "selected.actor"
        @updateActor params.actor
        @switchSelectedActor params.actor
      else if type == "update.actor"
        @updateActor params.actor
