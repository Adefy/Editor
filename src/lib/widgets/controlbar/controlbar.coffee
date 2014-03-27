define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"
  ControlCanvas = require "widgets/controlbar/control_canvas"
  ControlRender = require "widgets/controlbar/control_render"
  ControlPhysics = require "widgets/controlbar/control_physics"
  Workspace = require "widgets/workspace/workspace"

  # ARE control bar
  class ControlBar extends Widget

    ###
    # Set to true upon instantiation, prevents more than one instance
    # Similar to the workspace
    # @type [Boolean]
    ###
    @__exists: false

    ###
    # Always helpful to have around. Ended up adding it quite late to the
    # workspace, might as well add it to ourselves pre-emptively as well
    # @type [ControlBar]
    ###
    @__instance: null

    ###
    # Instantiates us, note that we need to be created after the workspace, since
    # we bind to it.
    #
    # @param [Workspace] parent workspace we are meant to control
    ###
    constructor: (parent) ->

      if ControlBar.__exists == true
        AUtilLog.warn "A controlbar already exists, refusing to continue!"
        return

      param.required parent

      ControlBar.__exists = true
      ControlBar.__instance = @

      if not parent instanceof Workspace
        throw new Error "ControlBar needs to bind to an existing workspace!"

      super ID.prefId("awcontrolbar"), parent, [ "awcontrolbar" ], true

      # Controls add themselves through our @addControl
      @_controls = []

      # Since we're awesome, we'll define controls ourselves
      new ControlCanvas
      new ControlRender
      new ControlPhysics

      # For the time being, we render ourselves, since there is nothing too
      # dynamic about our existence.
      @render()

    ###
    # Add a control to our list, then trigger a re-render. Note that there is
    # currently no method to remove existing controls! So don't go crazy with it.
    #
    # @param [ControlBarControl] control
    ###
    addControl: (control) ->
      @_controls.push control
      @render()

    ###
    # Our miniscule render function
    ###
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

    ###
    # Static method to fetch our internal instance
    #
    # @return [ControlBar] me
    ###
    @getMe: -> ControlBar.__instance
