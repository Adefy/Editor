##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Allows us to control the state of the renderer (start, pause, stop) the loop
class AWidgetControlRender extends AWidgetControlBarControl

  # Buid eeeeeet
  constructor: ->

    controls = [
      name: "Play"
      icon: "icon-play"
      state: "on"
      cb: -> alert "play pressed"
    ,
      name: "Stop"
      icon: "icon-stop"
      state: "off"
      cb: -> alert "stop pressed"
    ]

    # The class we extend handles the heavy lifting
    super "Renderer", "Stopped", controls