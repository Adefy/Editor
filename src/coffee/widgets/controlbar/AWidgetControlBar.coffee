##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

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

    # Controls add themselves through our @addControl
    @_controls = []

    # Since we're awesome, we'll define controls ourselves
    new AWidgetControlCanvas
    new AWidgetControlRender
    new AWidgetControlPhysics

    # For the time being, we render ourselves, since there is nothing too
    # dynamic about our existence.
    @render()

  # Add a control to our list, then trigger a re-render. Note that there is
  # currently no method to remove existing controls! So don't go crazy with it.
  #
  # @param [AWidgetControlBarControl] control
  addControl: (control) ->
    @_controls.push control
    @render()

  # Our miniscule render function
  render: ->
    $(@_sel).html @genElement "div", class: "awcb-inner", =>
      # Get the current canvas size. Note that this render function should really
      # only ever be called once; after it is, we will update our displayed
      # canvas size manually. Only initially do we need to read it in.
      _cW = @_parent.getCanvasWidth()
      _cH = @_parent.getCanvasHeight()
      _h = ""
      for o in @_controls
        _h += o.render()
      _h

  # Static method to fetch our internal instance
  #
  # @return [AWidgetControlBar] me
  @getMe: -> AWidgetControlBar.__instance