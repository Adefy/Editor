define (require) ->

  param = require "util/id"

  Dumpable = require "mixin/dumpable"

  class Vec2 extends Dumpable

    constructor: (x, y) ->
      @x = param.optional x, 0
      @y = param.optional y, 0

    add: (other) ->
      new Vec2 @x + other.x, @y + other.y

    sub: (other) ->
      new Vec2 @x - other.x, @y - other.y

    mul: (other) ->
      new Vec2 @x * other.x, @y * other.y

    div: (other) ->
      new Vec2 @x / other.x, @y / other.y

    ###
    # Dump the current Vec2 to a basic Object
    # @return [Object] data
    ###
    dump: ->
      _.extend super(),
        x: @x
        y: @y

    ###
    # Load a Vec2 from a dump
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      super data

      @x = data.x
      @y = data.y

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