define (require) ->

  config = require "config"
  param = require "util/param"

  directions = ["left", "right", "up", "down", "horz", "vert"]
  # rest, right|down, rest, left|up
  shake_steps = [0, 1, 0, -1]

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
  (target, options) ->
    starttime = param.required options.start
    duration  = param.required options.duration
    force     = param.required options.force
    shakes    = param.optional options.shakes, 2
    direction = param.optional options.direction, "horz", directions

    timesteps = duration / (shakes * 2)

    orgPosition = target.getPosition()

    for i in [0...shakes]
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
