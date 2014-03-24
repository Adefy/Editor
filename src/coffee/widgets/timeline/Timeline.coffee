##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Timeline widget, serving as the main control center for objects.
#
# OH GAWD this is going to be complex.
# 9/6/2013: Escape while you still can
#
# @depend ABezier.coffee
class AWidgetTimeline extends AWidget

  # Only one instance can ever exist
  @__exists: false

  # Always useful
  @__instance: null

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

  ###
  # Creates a timeline at the bottom of the screen. Note that it is absolutely
  # positioned, and adds padding to the body accordingly.
  #
  # @param [String] parent parent element selector
  # @param [Number] duration ad length in ms, can be expensively modified later
  ###
  constructor: (parent, duration) ->

    if AWidgetTimeline.__exists
      throw new Error "Only one timeline can exist at any one time!"
      # You also can't destroy existing timelines, so HAH

    AWidgetTimeline.__exists = true
    AWidgetTimeline.__instance = @

    # Default preview playback speed (fps)
    @_previewRate = 30

    # Visibility toggle animation status
    @__animating = false

    param.required parent
    @_duration = Number param.required(duration)

    # Sanity check on our internal color arrays
    _l1 = AWidgetTimeline._timebarColors.length
    _l2 = AWidgetTimeline._timebarBGColors.length

    if _l1 != _l2
      throw new Error "Timeline color count != timeline bg color count!"

    # Enforce minimum duration of 250ms
    if @_duration < 250
      throw new Error "Ad must be longer than 250ms!"
      # Although I have no idea who would want an ad 251ms long

    super prefId("timeline"), parent, [ "timeline" ]

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

    me = @

    @_enableDrag()
    @_regListeners()

  ###
  # Enables cursor dragging
  # @private
  ###
  _enableDrag: ->
    me = @

    # Enable cursor dragging
    $("#att-cursor").draggable
      axis: "x"
      containment: "parent"
      drag: (e, ui) ->

        # Cancel the drag if we are currently in the middle of playback
        if me._playbackID != undefined and me._playbackID != null
          return false

        me._onCursorDrag e, ui
        me._onCursorDragStop e, ui

  ###
  # Animation keys lightbolts saving
  # @private
  ###
  _saveKey: ->
    index = AWidgetWorkspace.getSelectedActor()
    # only enter checks if an actor is actually selected
    if index != null and index != undefined
      for actor, i in @_actors
        if actor.getId() == index then index = i
    if @_actors[index].isAlive()
      ARELog.info "SAVED"
      @_actors[index].updateInTime()

  ###
  # Registers event listeners
  # @private
  ###
  _regListeners: ->
    me = @

    # Set up event listeners (this is where the magic happens)
    $(document).ready ->

      # Outer timebar
      $(document).on "click", ".atts-outer", (e) -> me._outerClicked e, @

      # Timeline visibility toggle
      $(document).on "click", "#attt-toggle", (e) -> me._visToggleClicked e

      # Timeline playback controls
      $(document).on "click", "#atttc-toggle", (e) -> me._toggleClicked e
      $(document).on "click", "#atttc-forward", (e) -> me._forwClicked e
      $(document).on "click", "#atttc-backward", (e) -> me._prevClicked e

      # Sidebar save button
      $(document).on "click", ".asp-save", (e) -> me._saveKey e

  ###
  # @private
  ###
  _endPlayback: ->
    clearInterval @_playbackID
    @setCursorTime 0
    @_playbackID = null

  ###
  # @private
  ###
  _pausePlayback: ->
    clearInterval @_playbackID
    @_playbackID = null

  ###
  # Playback toggle button clicked (play/pause)
  # @private
  ###
  _toggleClicked: ->

    # If currently playing, remove the interval
    if @_playbackID != undefined and @_playbackID != null
      @_pausePlayback()
      return

    frameRate = 1000 / @_previewRate

    # Play the ad at 30 frames per second
    me = @
    @_playbackStart = @getCursorTime()
    @_playbackID = setInterval ->
      nextTime = me.getCursorTime() + frameRate
      if nextTime > me._duration then nextTime = me._duration

      me.setCursorTime nextTime

      if nextTime >= me._duration then me._endPlayback()

    , frameRate

  ###
  # Visibilty toggle request
  # @private
  ###
  _visToggleClicked: ->

    if $(@_sel).css("bottom") == "0px" and not @__animating
      @__animating = true

      $(@_sel).animate
        bottom: "-#{$(@_sel).height() - 24}px"
      ,
        duration: 500
        easing: "swing"
        step: =>
          window.left_sidebar.onResize()
          window.right_sidebar.onResize()
          window.workspace.onResize()
        done: => @__animating = false

    else if not @__animating
      @__animating = true

      $(@_sel).animate
        bottom: "0px"
      ,
        duration: 500
        easing: "swing"
        step: =>
          window.left_sidebar.onResize()
          window.right_sidebar.onResize()
          window.workspace.onResize()
        done: => @__animating = false

  ###
  # Forward playback button clicked (next keyframe)
  # @private
  ###
  _forwClicked: ->
    _currentPosition = @getCursorTime()
    _newPosition = null
    _min = 99999
    index = AWidgetWorkspace.getSelectedActor()

    # only enter checks if an actor is actually selected
    if index != null and index != undefined
      for actor, i in @_actors
        if actor.getId() == index then index = i

      _animations = @_actors[index].getAnimations()
      for anim of _animations
        if anim > _currentPosition
          if anim - _currentPosition < _min and anim - _currentPosition > 1
            _newPosition = anim
            _min = Math.round(anim - _currentPosition)

      # if no animations after current position, go to the end of the timeline
      if _newPosition != null
        if @_playbackID != null and @_playbackID != undefined
          @_pausePlayback()
        @setCursorTime _newPosition
      else
        # If we move cursor to duration, it is not on the screen anymore
        # maybe an issue with the width, maybe just because of how my
        # screens are set up. Something to keep an eye on.
        @setCursorTime @_duration
        @_pausePlayback()

  ###
  # Backward playback button clicked (prev keyframe)
  # @private
  ###
  _prevClicked: ->
    _currentPosition = @getCursorTime()
    _newPosition = null
    _min = 99999
    index = AWidgetWorkspace.getSelectedActor()

    # only enter checks if an actor is actually selected
    if index != null and index != undefined
      for actor, i in @_actors
        if actor.getId() == index then index = i

      _animations = @_actors[index].getAnimations()
      for anim of _animations
        if anim < _currentPosition
          if _currentPosition - anim < _min and _currentPosition - anim > 1
            _newPosition = anim
            _min = Math.round(_currentPosition - anim)

      # if no animtaions before this one we go to the beginning of the timeline
      if _newPosition != null
        if @_playbackID != null and @_playbackID != undefined
          @_pausePlayback()
        @setCursorTime _newPosition
      else
        @setCursorTime 0
        @_endPlayback()

  ###
  # Show dialog box for setting the preview framerate
  # @return [AWidgetModal]
  ###
  showSetPreviewRate: ->

    # Randomized input name
    n = prefId "_tPreviewRate"

    _html = """
    <div class="input_group">
    <label for="_tPreviewRate">Framerate: </label>
    <input type="text" value="#{@_previewRate}" placeholder="30" name="#{n}" />
    </div>
    """

    new AWidgetModal
      title: "Set Preview Framerate"
      content: _html
      modal: false
      cb: (data) =>
        @_previewRate = data[n]
      validation: (data) ->
        if isNaN(data[n]) then return "Framerate must be a number"
        if Number(data[n]) <= 0 then return "Framerate must be > 0"
        true

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

    for a in @_actors

      cursor = @getCursorTime()

      # Check if actor needs to die
      if (cursor < a.lifetimeStart or cursor > a.lifetimeEnd) and a.isAlive()
        a.timelineDeath()

      if a.isAlive() or (cursor >= a.lifetimeStart and cursor <= a.lifetimeEnd)
        a.updateInTime()

  # Update displayed cursor time
  # @private
  _updateCursorTime: ->
    time = (@getCursorTime() / 1000.0).toFixed 3
    $("#attt-cursor-time").text "Cursor: #{time}s @ #{@_previewRate} FPS"

  # Timebar click handler, magic and whatnot
  #
  # @param [Object] e click event
  # @param [Object] element dom element that was clicked
  # @private
  _outerClicked: (e, element) ->
    param.required e
    param.required element

    # Grab and validate index
    index = Number $(element).attr("data-index")
    if index < 0 or index > @_actors.length - 1 or isNaN(index)
      AUtilLog.warn "Clicked timebar has an invalid index, bailing [#{index}]"
      return

    @_actors[index].onClick()

  # Return our instance (assuming we exist)
  #
  # @return [AWidgetTimeline] instance
  @getMe: -> AWidgetTimeline.__instance

  # Get a random timebar color index, used when setting default actor timebar
  # color
  #
  # @return [Number] colIndex
  @getRandomTimebarColor: ->
    Math.floor(Math.random() * AWidgetTimeline._timebarColors.length)

  # Set an arbitrary cursor time
  #
  # @param [Number] time cursor time in ms
  setCursorTime: (time) ->
    param.required time

    if $("#att-cursor").length == 0
      throw new Error "Cursor not visible can't return time!"

    # Move cursor
    $("#att-cursor").css "left", $("#att-space").width() * (time / @_duration)

    # Update
    @_onCursorDrag()
    @_onCursorDragStop()

  # Return current cursor time in ms (relative to duration)
  #
  # @return [Number] time cursor time in ms
  getCursorTime: ->

    return # skip the cursor check for now

    # I thought about making this a warning and just returning '0', but that
    # would mess up thing elsewhere (whoever uses our return value would be
    # screwed). This makes the most sense
    if $("#att-cursor").length == 0
      throw new Error "Cursor not visible can't return time!"

    @_duration * ($("#att-cursor").position().left / $("#att-space").width())

  # Register actor, causes it to appear on the timeline starting from the
  # current cursor position.
  #
  # @param [AHBaseActor] actor
  registerActor: (actor) ->
    param.required actor

    if not actor instanceof AHBaseActor
      throw new Error "Actor must be an instance of AHBaseActor!"

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
  # Get current timeline duration
  #
  # @return [Number] duration
  ###
  getDuration: -> @_duration

  ###
  # Render initial structure.
  # Note that calling this clears the timeline visually, and does not render
  # objects! Objects are not destroyed, call @render to update them.
  ###
  renderStructure: ->

    return $(@_sel).html ATemplate.timelineBase()

    _html = ""

    # First up comes the actor listing. This is simply a flat list of all
    # actors in the scene. Clicking an actor selects it in the workspace, and
    # highlights its' timeline row.
    _html += "<ul id=\"at-actors\">"
    _html +=  "<hr>"
    _html +=   "<div id=\"ata-title\">Actors</div>"
    _html +=  "<hr>"
    _html +=   "<div id=\"ata-body\"></div>"
    _html += "</ul>"

    # Next we have the timeline itself. This is one wild beast of functionality
    # Or at least it is planned to be at the time of this comment. Hopefully,
    # in a week or so, it'll be alive and working. Hopefully.
    _html += "<div id=\"at-timeline\">"

    # Our toolbar, serving both as an edge to resize ourselves with, and a
    # container for generic timeline functions. Also displays current cursor
    # position (time)
    _html += """
      <div id=\"att-toolbar\">
        <div class=\"attt-third\">
          <span id=\"attt-cursor-time\"></span>
        </div>
        <div class=\"attt-third\">
          <div id=\"attt-controls\">
            <i id=\"atttc-backward\" class=\"icon-step-backward\"></i>
            <i id=\"atttc-toggle\" class=\"icon-play\"></i>
            <i id=\"atttc-forward\" class=\"icon-step-forward\"></i>
          </div>
        </div>
        <div class=\"attt-third\">
          <i id=\"attt-toggle\" class=\"icon-caret-down\"></i>
        </div>
      </div>
      """

    # Timeline cursor, designates current time, draggable, sexy
    _html +=   "<div id=\"att-cursor\"><div></div></div>"

    # Proper timeline space, actor timelines are contained here.
    _html +=   "<ul id=\"att-space\"></ul>"

    _html += "</div>"

    # Ship
    $(@_sel).html _html

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
  # Refresh spacer length and actor color in the actor list
  # @private
  ###
  _refreshActorRows: ->

    me = @
    $(".atab-spacer").each ->
      name = $(@).parent().find(".atab-name")[0]
      a = me._actors[Number($(@).parent().attr("data-index"))]

      # Set width
      $(@).width $(@).parent().width() - $(name).width() - 24

      # Remove current color
      for c in AWidgetTimeline._timebarBGColors
        $(@).removeClass c

      # Ship new color
      $(@).addClass AWidgetTimeline._timebarBGColors[a.timebarColor]

    $(".atab-name").each ->
      a = me._actors[Number($(@).parent().attr("data-index"))]

      # Remove current color
      for c in AWidgetTimeline._timebarColors
        $(@).removeClass c

      # Ship new color
      $(@).addClass AWidgetTimeline._timebarColors[a.timebarColor]

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
    $("#ata-body").html _h

    @_refreshActorRows()

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

    spacer = "<div class=\"atab-spacer\"></div>"
    name = "<div class=\"atab-name\">#{@_actors[index].name}</div>"
    _h = "<li data-index=\"#{index}\">#{name}#{spacer}</li>"

    if notouch then return _h

    $("#ata-body").append _h
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

    _h = ""
    spaceW = $("#att-space").width()

    a = @_actors[index]

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

    # Build style
    style = "style=\"left:#{_start}px; width:#{_length}px\""

    _colorClass = AWidgetTimeline._timebarBGColors[a.timebarColor]

    # Injectify
    _h += "<div data-index=\"#{index}\" class=\"atts-outer\">"
    _h +=   "<div #{style} class=\"attso-inner #{_colorClass}\">"

    # Render animation handles
    _animations = a.getAnimations()
    for anim of _animations
      offset = spaceW * ((Number(anim) - a.lifetimeStart) / @_duration)
      _h += "<div style=\"left: #{offset}px;\" class=\"attso-key\">"
      _h +=   "<i class=\"icon-bolt\"></i>"
      _h += "</div>"

    _h +=   "</div>"
    _h += "</div>"

    if notouch then return _h
    else $("#att-space").append _h

  ###
  # Render the timeline space. Should never be called by itself, only by
  # @render()
  #
  # @private
  ###
  _renderSpace: ->

    _h = ""

    # Create a time bar for each actor, positioned according to their birth and
    # death.
    for a, i in @_actors
      _h += @_renderActorSpace i, true

    # Ship
    $("#att-space").html _h

  ###
  # Resize and apply our height to the body
  #
  # @param [Number] height
  ###
  resize: (@_height) ->
    $(@_sel).css "height", "#{@_height}px"
    $("body").css "padding-bottom", @_bodyPadding + @_height
