define (require) ->

  Handle = require "handles/handle"

  Vec2 = require "core/vec2"

  class ParticleSystem extends Handle

    constructor: (@ui) ->

      @_position = new Vec2(0, 0)

      ###
      # @type [Array<BaseActor>]
      ###
      @_actors = []

      ###
      # @type [Array<Object>]
      #   @property [Object] actorRef a actor dump used as a reference
      #   @property
      ###
      @_spawnList = []
      @_spawnSelector = =>
        @_spawnList[Math.floor(Math.random() * @_spawnList.length)]

      ###
      # @type [Number] _spawnCap maximum number of spawns allowed
      ###
      @_spawnCap = 100

      @handleType = "ParticleSystem"

    ###
    # Spawn a new actor and add it to the internal list
    # @return [self]
    ###
    spawn: ->
      actor = window[actor.type].load @ui, @_spawnSelector()
      actor.isParticle = true

      @_actors.push actor

      @

    ###
    # Remove an actor from the actors list
    # @return [self]
    ###
    remove: (actor) ->
      @_actors = _.without @_actors, (a) -> a.getId() == actor.getId()
      @

    ###
    # Get the ParticleSystem root position
    # @return [Vec2]
    ###
    getPosition: ->
      @_position

    ###
    # Set the ParticleSystem root position
    # @param [Number] x
    # @param [Number] y
    ###
    setPosition: (x, y) ->
      @_position.x = x
      @_position.y = y

      @

    ###
    # Dumps the ParticleSystem to a basic Object
    # @return [Object] data
    ###
    dump: ->
      _.extend super(),
        psVersion: "1.0.0"
        position: @_position.dump()                                    # v1.0.0
        spawnCap: @_spawnCap                                           # v1.0.0
        spawnList: @_spawnList                                         # v1.0.0

    ###
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      super data

      @_position = Vec2.load data.position                             # v1.0.0
      @_spawnCap = data.spawnCap                                       # v1.0.0
      @_spawnList = data.spawnList                                     # v1.0.0

      @

    ###
    # @param [Object] data
    # @return [ParticleSystem]
    ###
    @load: (data) ->
      ps = new ParticleSystem AdefyEditor.ui
      ps.load data
      ps

###
  ChangeLog
    dump: "1.0.0"

###