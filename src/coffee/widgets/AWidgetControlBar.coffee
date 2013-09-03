# AWGL control bar
class AWidgetControlBar extends AWidget

  # Set to true upon instantiation, prevents more than one instance
  # Similar to the workspace
  @__exists: false

  # Always helpful to have around. Ended up adding it quite late to the
  # workspace, might as well add it to ourselves pre-emptively as well
  @__instance: null

  # Instantiates us, note that we need to be created after the workspace, since
  # we bind to it.
  #
  # @param [AWidgetWorkspace] parent workspace we are meant to control
  constructor: (parent) ->

    if AWidgetControlBar.__exists == true
      AUtilLog.warn "A controlbar already exists, refusing to continue!"
      return

    param.required parent

    AWidgetControlBar.__exists = true
    AWidgetControlBar.__instance = @

    if not parent instanceof AWidgetWorkspace
      throw new Error "ControlBar needs to bind to an existing workspace!"

    super prefId("awcontrolbar"), parent, [ "awcontrolbar" ], true

    # For the time being, we render ourselves, since there is nothing too
    # dynamic about our existence.
    @render()

  # Our miniscule render function
  render: ->

    _h = ""
    _h += "<ul><div class=\"awcb-inner\">"
    _h +=   "<div class=\"awcb-section\">"
    _h +=     "<div class=\"awcb-section-title\">Renderer</div>"
    _h +=     "<li id=\"awcb-awgl-render-play\" class=\"awcb-control on\">"
    _h +=       "Start"
    _h +=       "<i class=\"icon-play\"></i>"
    _h +=     "</li>"
    _h +=     "<li id=\"awcb-awgl-render-stop\" class=\"awcb-control off\">"
    _h +=       "Stop"
    _h +=       "<i class=\"icon-stop\"></i>"
    _h +=     "<li class=\"awcb-control-status off\">Stopped</li>"
    _h +=     "</li>"
    _h +=   "</div>"
    _h +=   "<div class=\"awcb-section\">"
    _h +=     "<div class=\"awcb-section-title\">Physics</div>"
    _h +=     "<li id=\"awcb-awgl-physics-play\" class=\"awcb-control on\">"
    _h +=       "Start"
    _h +=       "<i class=\"icon-play\"></i>"
    _h +=     "</li>"
    _h +=     "<li id=\"awcb-awgl-physics-stop\" class=\"awcb-control off\">"
    _h +=       "Stop"
    _h +=       "<i class=\"icon-stop\"></i>"
    _h +=     "</li>"
    _h +=     "<li class=\"awcb-control-status off\">Stopped</li>"
    _h +=   "</div>"
    _h += "</div></ul>"

    $(@_sel).html _h

  # Static method to fetch our internal instance
  #
  # @return [AWidgetControlBar] me
  @getMe: -> AWidgetControlBar.__instance