##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Allows us to control the physics engine. (start, pause, stop)
class AWidgetControlPhysics extends AWidgetControlBarControl

  # Set up controls
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
    super "Physics", "Stopped", controls