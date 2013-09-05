# Exposes controls to modify the canvas size
class AWidgetControlCanvas extends AWidgetControlBarControl

  # A tad fancy, we also require initialization
  constructor: ->

    controls = [
      name: "Pick Size"
      icon: "icon-resize-full"
      state: "on"
      cb: -> alert "resize requested"
    ]

    # Canvas dimensions. No real reason to save them for the time being, but
    # it might be useful to have them broken out internally in the future.
    @_canvasHeight = 0
    @_canvasWidth = 0

    # The class we extend handles the heavy lifting
    super "Canvas", "-", controls

  # Pull in the current size of the canvas
  initialize: ->

    @_canvasHeight = AWidgetWorkspace.getMe().getCanvasHeight()
    @_canvasWidth = AWidgetWorkspace.getMe().getCanvasWidth()

    # Ship it
    @status = "#{@_canvasWidth}x#{@_canvasHeight}"