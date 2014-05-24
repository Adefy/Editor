define (require) ->

  param = require "util/param"

  Dumpable = require "mixin/dumpable"

  class Vec2 extends Dumpable

    constructor: (@x, @y) ->
      @x ||= 0
      @y ||= 0

    ###
    # @param [Boolean] bipolar  should randomization occur in all directions?
    # @return [Vec2] randomizedVector
    ###
    random: (options) ->
      options ||= {}
      bipolar = !!options.bipolar
      seed = options.seed || Math.random() * 0xFFFF

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
    add: (other) -> new Vec2 @x + other.x, @y + other.y

    ###
    # @param [Vec2]
    # @return [Vec2]
    ###
    sub: (other) -> new Vec2 @x - other.x, @y - other.y

    ###
    # @param [Vec2]
    # @return [Vec2]
    ###
    mul: (other) -> new Vec2 @x * other.x, @y * other.y

    ###
    # @param [Vec2]
    # @return [Vec2]
    ###
    div: (other) -> new Vec2 @x / other.x, @y / other.y

    ###
    # @return [Vec2]
    ###
    floor: -> new Vec2 Math.floor(@x), Math.floor(@y)

    ###
    # @return [Vec2]
    ###
    ceil: -> new Vec2 Math.ceil(@x), Math.ceil(@y)

    ###
    # @return [Vec2]
    ###
    @zero: -> new Vec2 0, 0

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
