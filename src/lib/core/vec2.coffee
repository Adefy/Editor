define (require) ->

  param = require "util/id"

  Dumpable = require "mixin/dumpable"

  class Vec2 extends Dumpable

    constructor: (x, y) ->
      @x = param.optional x, 0
      @y = param.optional y, 0

    ###
    # @param [Boolean] bipolar should randomization occur in all directions?
    # @return [Vec2]
    ###
    random: (options) ->
      options = param.optional options, {}
      bipolar = options.bipolar
      seed = param.optional options.seed, Math.random() * 0xFFFF

      x = Math.random() * @x
      y = Math.random() * @y
      if bipolar
        x = -x if Math.random() < 0.5
        y = -y if Math.random() < 0.5

      new Vec2 x, y

    ###
    # @param [Vec2]
    # @return [Vec2]
    ###
    add: (other) ->
      new Vec2 @x + other.x, @y + other.y

    ###
    # @param [Vec2]
    # @return [Vec2]
    ###
    sub: (other) ->
      new Vec2 @x - other.x, @y - other.y

    ###
    # @param [Vec2]
    # @return [Vec2]
    ###
    mul: (other) ->
      new Vec2 @x * other.x, @y * other.y

    ###
    # @param [Vec2]
    # @return [Vec2]
    ###
    div: (other) ->
      new Vec2 @x / other.x, @y / other.y


    ###
    # Dump the current Vec2 to a basic Object
    # @return [Object] data
    ###
    dump: ->
      _.extend super(),
        x: @x                                                          # v1.0.0
        y: @y                                                          # v1.0.0

    ###
    # Load a Vec2 from a dump
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      super data

      @x = data.x                                                      # v1.0.0
      @y = data.y                                                      # v1.0.0

      @

    ###
    # Load a Vec2 from a dump
    # @param [Object] data
    # @return [Vec2]
    ###
    @load: (data) ->
      vec2 = new Vec2()
      vec2.load data
      vec2