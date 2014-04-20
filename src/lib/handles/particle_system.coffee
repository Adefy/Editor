define (require) ->

  ID = require "util/id"
  seedrand = require "util/seedrandom"

  Handle = require "handles/handle"

  Vec2 = require "core/vec2"

  class ParticleSystem extends Handle

    ###
    # @param [UIManager] ui
    ###
    constructor: (@ui) ->
      super()

      @_uid = ID.uID()

      ###
      # @type [Vec2]
      ###
      @_position = new Vec2(0, 0)
      @_actorRandomSpawnDelta = new Vec2(0, 0)

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

      ###
      # Returns an element from the @_spawnList
      # @return [Object]
      ###
      @_spawnSelector = =>
        @_spawnList[Math.floor(Math.random() * @_spawnList.length)]

      ###
      # @type [Number] _spawnCap maximum number of spawns allowed
      ###
      @_spawnCap = 100

      ###
      # Handle
      # @type [String]
      ###
      @handleType = "ParticleSystem"

      ###
      # @type [Number]
      ###
      @_seed = Math.random() * 0xFFFF

      @_iSeed = @_seed

    ###
    # Reset the particle system to its original state
    # @return [self]
    ###
    reset: ->
      @_iSeed = @_seed

      for actor in @_actors
        actor.destroy()

      @_actors.length = 0

      @

    ###
    # Spawn a new actor and add it to the internal list
    # @return [self]
    ###
    spawn: ->
      @_iSeed++

      actor = window[actor.type].load @ui, @_spawnSelector()
      pos = @_actorRandomSpawnDelta.random(seed: @_iSeed).add(@_position)
      actor.setPosition pos.x, pos.y
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
    # @return [Number] seed
    ###
    getSeed: ->
      @_seed

    ###
    # @param [Number] seed
    # @return [self]
    ###
    setSeed: (@_seed) -> @

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
        psVersion: "1.1.0"
        uid: @_uid                                                     # v1.1.0
        actorRandomSpawnDelta: @_actorRandomSpawnDelta.dump()          # v1.1.0
        position: @_position.dump()                                    # v1.0.0
        spawnCap: @_spawnCap                                           # v1.0.0
        spawnList: @_spawnList                                         # v1.0.0

    ###
    # Load the state of a dumped particle system into the current
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      super data

      if data.psVersion >= "1.1.0"
        @_uid = data.uid                                               # v1.1.0
        @_actorRandomSpawnDelta = Vec2.load data.actorRandomSpawnDelta # v1.1.0

      @_position = Vec2.load data.position                             # v1.0.0
      @_spawnCap = data.spawnCap                                       # v1.0.0
      @_spawnList = data.spawnList                                     # v1.0.0

      @

    ###
    # Load a ParticleSystem from a dump
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