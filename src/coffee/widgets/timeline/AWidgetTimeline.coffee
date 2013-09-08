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
  constructor: (parent) ->

    if AWidgetTimeline.__exists
      throw new Error "Only one timeline can exist at any one time!"
      # You also can't destroy existing timelines, so HAH

    AWidgetTimeline.__exists = true
    AWidgetTimeline.__instance = @

    param.required parent

    super prefId("atimeline"), parent, [ "atimeline" ]

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

  # Register actor, causes it to appear on the timeline starting from the
  # current cursor position.
  #
  # @param [AHBaseActor] actor
  registerActor: (actor) ->
    param.required actor

    if not actor instanceof AHBaseActor
      throw new Error "Actor must be an instance of AHBaseActor!"

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
    _html +=   "<ul id=\"att-space\">"

    # Testing
    _html +=   "<div class=\"atts-outer\">"
    _html +=     "<div class=\"attso-inner\"></div>"
    _html +=   "</div>"

    _html += "</ul>"

    _html += "</div>"

    # Now the list of preset animations. Dragging any of them onto an actor
    # will apply them from the current time onwards.
    _html += "<ul id=\"at-animations\"></ul>"

    # Ship
    $(@_sel).html _html

  # Resize and apply our height to the body
  #
  # @param [Number] height
  resize: (@_height) ->
    $(@_sel).css "height", "#{@_height}px"
    $("body").css "padding-bottom", @_bodyPadding + @_height