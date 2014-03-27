define (require) ->

  ControlBarControl = require "widgets/controlbar/controlbar_control"

  # Allows us to control the physics engine. (start, pause, stop)
  class ControlPhysics extends ControlBarControl

    ###
    # Set up controls
    ###
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
