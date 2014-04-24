define (require) ->

  config = require "config"
  param = require "util/param"

  ID = require "util/id"
  seedrand = require "util/seedrandom"

  Handle = require "handles/handle"
  RectangleActor = require "handles/actors/rectangle"

  Vec2 = require "core/vec2"

  CompositeProperty = require "handles/properties/composite"
  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"

  class ParticleSystem extends RectangleActor

    ###
    # @param [UIManager] ui
    # @param [Object] options
    ###
    constructor: (@ui, options) ->
      pos = param.optional options.position, Vec2.zero()
      super @ui, 0, 32, 32, pos.x, pos.y

      @_uid = ID.uID()

      ###
      # @type [Vec2]
      ###
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
      # Handle
      # @type [String]
      ###
      @handleType = "ParticleSystem"

      @setName "#{@handleType} #{@_id_n}"

      ###
      # @type [Number] iSeed seed increment
      ###
      @_iSeed = 0

      # ParticleSystems do not need a texture.
      delete @_ctx.setTexture

      ## for testing
      @_ctx.spawn =
        name: config.locale.label.spawn_command
        cb: => @spawn()

      @initPropertyParticles()
      @initPropertySpawn()

      @_properties.color.setValue r: 255, g: 110, b: 48
      @_properties.width.setVisibleInToolbar false
      @_properties.height.setVisibleInToolbar false
      @_properties.rotation.setVisibleInToolbar false
      @_properties.opacity.setVisibleInToolbar false

    ###
    # Initialize ParticleSystem particles property
    # @return [self]
    ###
    initPropertyParticles: ->
      @_properties.particles = new CompositeProperty()
      @_properties.particles.icon = config.icon.property_particles

      ###
      # @type [Number] seed
      ###
      @_properties.particles.seed = new NumericProperty()
      @_properties.particles.seed.setPrecision 0
      @_properties.particles.seed.setValue Math.floor(Math.random() * 0xFFFF)

      ###
      # @type [Number] max maximum number of spawns allowed
      ###
      @_properties.particles.max = new NumericProperty()
      @_properties.particles.max.setPrecision 0
      @_properties.particles.max.setValue 20

      ###
      # @type [Number] frequency how often should actors spawn, 0 is immediately
      ###
      @_properties.particles.frequency = new NumericProperty()
      @_properties.particles.frequency.setPrecision 0
      @_properties.particles.frequency.setValue 0

      @_properties.particles.addProperty "seed", @_properties.particles.seed
      @_properties.particles.addProperty "max", @_properties.particles.max
      @_properties.particles.addProperty "frequency", @_properties.particles.frequency

      @

    ###
    # Initialize ParticleSystem spawn property
    # @return [self]
    ###
    initPropertySpawn: ->
      @_properties.spawn = new CompositeProperty()
      @_properties.spawn.icon = config.icon.property_spawn
      @_properties.spawn.x = new NumericProperty()
      @_properties.spawn.x.setValue 0
      @_properties.spawn.y = new NumericProperty()
      @_properties.spawn.y.setValue 0

      ## add properties

      @_properties.spawn.addProperty "x", @_properties.spawn.x
      @_properties.spawn.addProperty "y", @_properties.spawn.y

      @

    ###
    # @return [Number] seed
    ###
    getSeed: -> @_properties.particles.seed.getValue()

    ###
    # @param [Number] seed
    # @return [self]
    ###
    setSeed: (seed) -> @_properties.particles.seed.setValue(seed); @

    ###
    # @return [Number]
    ###
    getFrequency: -> @_properties.particles.frequency.getValue()

    ###
    # @param [Number] freq
    # @return [self]
    ###
    setFrequency: (freq) -> @_properties.particles.frequency.setValue(freq); @

    ###
    # @return [Boolean] canSpawn
    ###
    canSpawn: ->
      max = @particles.particles.max.getValue()
      (@_spawnList.length > 0) && (max > @_actors.length)

    ###
    # @return [Object] data actor dump used for spawning
    ###
    addSpawnData: (data) ->
      param.required data
      if data.handleType == "ParticleSystem"
        msg = "You can't have a particle system that spawns a particle system"
        throw new Error msg

      @_spawnList.push data
      @

    ###
    # Remove an actor from the actors list
    # NOTE* This does not destroy the actor, use killActor instead
    # @return [self]
    ###
    removeActor: (actor) ->
      @_actors = _.without @_actors, (a) -> a.getId() == actor.getId()
      @

    ###
    # Removes all actively spawned Actors
    # @return [self]
    ###
    killActor: (actor) ->
      @removeActor actor
      actor.destroy()
      @

    ###
    # Removes all actively spawned Actors
    # @return [self]
    ###
    killActors: ->
      for actor in @_actors
        actor.destroy()
      @_actors.length = 0
      @

    ###
    # Reset the particle system to its original state
    # @return [self]
    ###
    reset: ->
      @_iSeed = 0

      @killActors()

      @

    ###
    # Spawn a new actor and add it to the internal list
    # @return [self]
    ###
    spawn: ->
      @_iSeed++ # increment the iSeed

      # we have no actor data, forget about spawning
      return @ if @_spawnList.length == 0

      spawnData = @_spawnSelector()

      unless spawnData
        throw new Error "null spawn data!"

      actor = window[spawnData.type].load @ui, spawnData

      seed = @_properties.particles.seed.getValue()

      pos = @_properties.spawn.getValue()
      pos = new Vec2(pos.x, pos.y)
        .random(seed: seed + @_iSeed)
        .add(@_properties.position.getValue())

      actor.setPosition pos.x, pos.y
      actor.isParticle = true

      @_actors.push actor

      @

    ###
    # Callback during playback
    # @param [Number] time current time
    # @return [self]
    ###
    tick: (time) ->
      return unless @canSpawn()

      max = @particles.particles.max.getValue()
      freq = @getFrequency()

      if (freq == 0)
        while @_actors.length < max
          @spawn()

      else
        # determine if we need to spawn an actor or not
      @

    ###
    # Dumps the ParticleSystem to a basic Object
    # @return [Object] data
    ###
    dump: ->
      _.extend super(),
        psVersion: "1.2.0"
        uid: @_uid                                                     # v1.1.0
        #actorRandomSpawnDelta: @_actorRandomSpawnDelta.dump()          # v1.1.0
        #position: @_position.dump()                                    # v1.0.0
        #spawnCap: @_spawnCap                                           # v1.0.0
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
        #@_actorRandomSpawnDelta = Vec2.load data.actorRandomSpawnDelta # v1.1.0

      #@_position = Vec2.load data.position                             # v1.0.0
      #@_spawnCap = data.spawnCap                                       # v1.0.0
      @_spawnList = data.spawnList                                     # v1.0.0

      @

    ###
    # Load a ParticleSystem from a dump
    # @param [Object] data
    # @return [ParticleSystem]
    ###
    @load: (ui, data) ->
      ps = new ParticleSystem ui
      ps.load data
      ps

###
@ChangeLog

  - "1.0.0": Initial
  - "1.1.0": Inherited from a RectangleActor

###