define (require) ->

  config = require "config"
  param = require "util/param"
  optValidate = require "util/option_validate"

  Effect = require "effects/effect"

  directions = ["left", "right", "up", "down", "horz", "vert"]
  # rest, right|down, rest, left|up
  shake_steps = [0, 1, 0, -1]

  class EffectShake extends Effect

    @title: "Shake"

    @properties:
      start:
        label: "Start Time (ms)"
        priority: "required"
        type: "number"
        def: -> 0
        validate: (value) -> value >= 0
      duration:
        label: "Duration (ms)"
        priority: "required"
        type: "number"
        def: -> 100
        validate: (value) -> value > 0
      force:
        label: "Force"
        priority: "required"
        type: "number"
        def: -> 10
        validate: (value) -> value > 0
      shakes:
        label: "Shake count"
        priority: "optional"
        type: "number"
        def: -> 2
        validate: (value) -> value > 0
      direction:
        label: "Direction"
        priority: "optional"
        type: "string"
        def: -> "horz"
        valididate: (value) ->
          _.any directions, (o) -> o == value

    ###
    # Shake Effect
    #
    # @param [BaseActor] target
    # @param [Object] options
    #   @option [Number] start  when should the animation start?
    #   @option [Number] duration  how long should this effect last
    #   @option [Number] force  how powerful should the shake be?
    #   @option [Number] shakes  how many shakes should the effect produce?
    #     @default 2
    #   @option [String] direction
    #     @case "left"
    #     @case "right"
    #     @case "up"
    #     @case "down"
    #     @case "horz"
    #       @default
    #     @case "vert"
    ###
    @execute: (target, options) ->
      options = optValidate @properties, options

      starttime = options.start
      duration  = options.duration
      force     = options.force
      shakes    = options.shakes
      direction = options.direction

      shakes += shakes % 2

      timesteps = duration / (shakes * 2)

      orgPosition = target.getPosition()
      orgPosition =
        x: orgPosition.x
        y: orgPosition.y

      for i in [0..shakes]
        sig = shake_steps[i % 4]

        time = starttime + timesteps * i

        ox = 0
        oy = 0

        switch direction
          when "left"  then ox = -force if sig != 0
          when "right" then ox = force if sig != 0
          when "up"    then oy = -force if sig != 0
          when "down"  then oy = force if sig != 0
          when "horz"  then ox = force * sig
          when "vert"  then oy = force * sig

        target.setPosition orgPosition.x + ox, orgPosition.y + oy
        target.updateInTime time

      target