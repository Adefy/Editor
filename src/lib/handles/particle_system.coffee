define (require) ->

  Handle = require "handles/handle"

  Vec2 = require "core/vec2"

  class ParticleSystem extends Handle

    constructor: ->

      @_position = new Vec2(0, 0)

      @_actors = []

      ###
      # @type [Array<Object>]
      #   @property [Object] actorRef a actor dump used as a reference
      #   @property
      ###
      @_spawnList = []

      ###
      # @type [Number] _spawnCap maximum number of spawns allowed
      ###
      @_spawnCap = 100

      @handleType = "ParticleSystem"

    spawn: ->
      @_actors.push

      @

    getPosition: ->
      @_position

    setPosition: (x, y) ->
      @_position.x = x
      @_position.y = y

      @

    dump: ->
      _.extend super(),
        psVersion: "1.0.0"
        position: @_position.dump()                                    # v1.0.0
        spawnCap: @_spawnCap                                           # v1.0.0
        spawnList: @_spawnList                                         # v1.0.0

    load: (data) ->
      super data

      @_position = Vec2.load data.position                             # v1.0.0
      @_spawnCap = data.spawnCap                                       # v1.0.0
      @_spawnList = data.spawnList                                     # v1.0.0

      @

###
  ChangeLog
    dump: "1.0.0"

###