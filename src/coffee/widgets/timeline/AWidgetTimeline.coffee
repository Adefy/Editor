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

  # Creates a timeline at the bottom of the screen. Note that it is absolutely
  # positioned, and adds padding to the body accordingly.
  #
  # @param [String] parent parent element selector
  # @param [Number] duration ad length in ms, can be expensively modified later
  constructor: (parent, duration) ->

    if AWidgetTimeline.__exists
      throw new Error "Only one timeline can exist at any one time!"
      # You also can't destroy existing timelines, so HAH

    AWidgetTimeline.__exists = true
    AWidgetTimeline.__instance = @

    param.required parent
    @_duration = Number param.required(duration)

    # Enforce minimum duration of 250ms
    if @_duration < 250
      throw new Error "Ad must be longer than 250ms!"
      # Although I have no idea who would want an ad 251ms long

    super prefId("atimeline"), parent, [ "atimeline" ]

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

    # Enable cursor dragging
    $("#att-cursor").draggable
      axis: "x"
      containment: "parent"

  # Return our instance (assuming we exist)
  #
  # @return [AWidgetTimeline] instance
  @getMe: -> AWidgetTimeline.__instance

  # Return current cursor time in ms (relative to duration)
  #
  # @return [Number] time cursor time in ms
  getCursorTime: ->

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

  # Remove an actor by id, re-renders timeline internals. Note that this
  # utilizies the ID of the AJS actor!
  #
  # @param [Number] id
  # @return [Boolean] success
  removeActor: (id) ->
    param.required id

    for a, i in @_actors
      if a.getActorId() == id
        @_actors.splice i, 1
        return true

    # TODO: Remove any renderings of the actor (space, list)

    false

  # Get current timeline duration
  #
  # @return [Number] duration
  getDuration: -> @_duration

  # Render initial structure.
  # Note that calling this clears the timeline visually, and does not render
  # objects! Objects are not destroyed, call @render to update them.
  renderStructure: ->

    _html = ""

    # Our toolbar, serving both as an edge to resize ourselves with, and a
    # container for generic timeline functions. Also displays current cursor
    # position (time)
    _html += "<div id=\"at-toolbar\"></div>"

    # First up comes the actor listing. This is simply a flat list of all
    # actors in the scene. Clicking an actor selects it in the workspace, and
    # highlights its' timeline row.
    _html += "<ul id=\"at-actors\"></ul>"

    # Next we have the timeline itself. This is one wild beast of functionality
    # Or at least it is planned to be at the time of this comment. Hopefully,
    # in a week or so, it'll be alive and working. Hopefully.
    _html += "<div id=\"at-timeline\">"

    # Timeline cursor, designates current time, draggable, sexy
    _html +=   "<div id=\"att-cursor\"></div>"

    # Proper timeline space, actor timelines are contained here.
    _html +=   "<ul id=\"att-space\"></ul>"

    _html += "</div>"

    # Ship
    $(@_sel).html _html

  # Proper render function, fills in timeline internals. Since we have two
  # distinct sections, each is rendered by a seperate method. This helps
  # divide the necessary logic, into @_renderActors() and @_renderSpace(). This
  # function simply calls both.
  render: ->
    @renderActors()
    @renderSpace()

  # Render the actor list Should never be called by itself, only by @render()
  #
  # @private
  _renderActors: ->

    _h = ""

    for a, i in @_actors
      _h += "<li data-index=\"#{i}\">#{a.getName()}</li>"

    # Ship
    $("#at-actors").html _h

  # Renders an individual actor timebar, used when registering new actors,
  # preventing a full re-render of the space. Also called internally by
  # @_renderSpace.
  #
  # @param [Number] index index of the actor whose space we are to render
  #
  # @private
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

    # Injectify
    _h += "<div data-index=\"#{index}\" class=\"atts-outer\">"
    _h +=   "<div #{style} class=\"attso-inner\">"

    if notouch then return _h
    else $("#att-space").append _h

  # Render the timeline space. Should never be called by itself, only by
  # @render()
  #
  # @private
  _renderSpace: ->

    _h = ""

    spaceW = $("#att-space").width()

    # Create a time bar for each actor, positioned according to their birth and
    # death.
    for a, i in @_actors
      _h += @_renderActorSpace i, true

    # Ship
    $("#att-space").html _h

  # Resize and apply our height to the body
  #
  # @param [Number] height
  resize: (@_height) ->
    $(@_sel).css "height", "#{@_height}px"
    $("body").css "padding-bottom", @_bodyPadding + @_height