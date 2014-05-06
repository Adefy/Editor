define (require) ->

  config = require "config"
  param = require "util/param"
  optValidate = require "util/option_validate"

  Effect = require "effects/effect"

  # rest, right|down, rest, left|up
  rock_steps = [0, 1, 0, -1]

  class EffectRock extends Effect

    @title: "Rock"

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
      rocks:
        label: "Rock count"
        priority: "optional"
        type: "number"
        def: -> 2
        validate: (value) -> value > 0

    ###
    # Rock Effect, pretty much a copy of shake, but for rotation
    #
    # @param [BaseActor] target
    # @param [Object] options
    #   @option [Number] start  when should the animation start?
    #   @option [Number] duration  how long should this effect last
    #   @option [Number] force  how powerful should the shake be?
    #   @option [Number] rocks  how many rocks should the effect produce?
    #     @default 2
    ###
    @execute: (target, options) ->
      options = optValidate @properties, options

      starttime = options.start
      duration  = options.duration
      force     = options.force
      rocks     = options.rocks

      # always force a even number of rocks
      rocks += rocks % 2

      timesteps = duration / (rocks * 2)

      rotation = target.getRotation()

      for i in [0..rocks]
        sig = rock_steps[i % 4]

        time = starttime + timesteps * i

        offset = force * sig

        target.setRotation rotation + offset
        target.updateInTime time

      target
