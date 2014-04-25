###
@ChangeLog

  - "1.0.0": Initial
  - "1.1.0": Inherited from a RectangleActor

###

define (require) ->

  AUtilLog = require "util/log"
  config = require "config"
  param = require "util/param"
  ID = require "util/id"
  seedrand = require "util/seedrandom"
  Vec2 = require "core/vec2"

  Handle = require "handles/handle"
  RectangleActor = require "handles/actors/rectangle"

  CompositeProperty = require "handles/properties/composite"
  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"

  SettingsWidget = require "widgets/floating/settings"

  class Spawner extends RectangleActor

    ###
    # @param [UIManager] ui
    # @param [Object] options
    ###
    constructor: (@ui, options) ->
      pos = param.optional options.position, Vec2.zero()
      super @ui, 0, 32, 32, pos.x, pos.y

      @handleType = "Spawner"
      @setName "#{@handleType} #{@_id_numeric}"

      @_uid = ID.uID()

      @_actorRandomSpawnDelta = new Vec2(0, 0)
      @_actors = []

      @_spawnDumpList = []
      @_seedIncrement = 0

      # Spawners do not need a texture.
      delete @_ctx.setTexture

      ## for testing
      @_ctx.spawn =
        name: config.locale.ctx.spawner.spawn
        cb: => @spawn()

      @_ctx.configure =
        name: config.locale.ctx.spawner.configure
        cb: => @openConfigureDialog()

      @initPropertyParticles()
      @initPropertySpawn()

      @_properties.color.setValue r: 255, g: 110, b: 48
      @_properties.width.setVisibleInToolbar false
      @_properties.height.setVisibleInToolbar false
      @_properties.rotation.setVisibleInToolbar false
      @_properties.opacity.setVisibleInToolbar false

    ###
    # Get a random dump from our spawn list
    #
    # @return [Object]
    ###
    getSpawnableDump: ->
      @_spawnDumpList[Math.floor(Math.random() * @_spawnDumpList.length)]

    ###
    # Initialize our particles property
    #
    # @return [Spawner] self
    ###
    initPropertyParticles: ->
      @_properties.particles = new CompositeProperty()
      @_properties.particles.setVisibleInToolbar false
      @_properties.particles.icon = config.icon.property_particles

      @_properties.particles.seed = new NumericProperty()
      @_properties.particles.seed.setPrecision 0
      @_properties.particles.seed.setValue Math.floor(Math.random() * 0xFFFF)

      @_properties.particles.max = new NumericProperty()
      @_properties.particles.max.setPrecision 0
      @_properties.particles.max.setValue 20

      @_properties.particles.frequency = new NumericProperty()
      @_properties.particles.frequency.setMin 50
      @_properties.particles.frequency.setPrecision 0
      @_properties.particles.frequency.setValue 250

      @_properties.particles.addProperty "seed", @_properties.particles.seed
      @_properties.particles.addProperty "max", @_properties.particles.max
      @_properties.particles.addProperty "frequency", @_properties.particles.frequency

      @

    ###
    # Initialize Spawner spawn property
    #
    # @return [Spawner] self
    ###
    initPropertySpawn: ->
      @_properties.spawn = new CompositeProperty()
      @_properties.spawn.setVisibleInToolbar false
      @_properties.spawn.icon = config.icon.property_spawn
      @_properties.spawn.x = new NumericProperty()
      @_properties.spawn.x.setValue 0
      @_properties.spawn.y = new NumericProperty()
      @_properties.spawn.y.setValue 0

      @_properties.spawn.addProperty "x", @_properties.spawn.x
      @_properties.spawn.addProperty "y", @_properties.spawn.y

      @

    ###
    # @return [Number] seed
    ###
    getSeed: ->
      @_properties.particles.seed.getValue()

    ###
    # @param [Number] seed
    # @return [Spawner] self
    ###
    setSeed: (seed) ->
      @_properties.particles.seed.setValue seed
      @

    ###
    # @return [Number]
    ###
    getFrequency: ->
      @_properties.particles.frequency.getValue()

    ###
    # @param [Number] freq
    # @return [Spawner] self
    ###
    setFrequency: (freq) ->
      @_properties.particles.frequency.setValue freq
      @

    ###
    # @return [Boolean] canSpawn
    ###
    canSpawn: ->
      max = @particles.particles.max.getValue()
      (@_spawnDumpList.length > 0) && (max > @_actors.length)

    ###
    # @return [Object] data actor dump used for spawning
    ###
    addSpawnData: (data) ->
      param.required data

      if data.handleType == "Spawner"
        throw new Error "A particle system can't spawn another particle system"

      @_spawnDumpList.push data
      @

    ###
    # Remove an actor from the actors list
    # NOTE* This does not destroy the actor, use killActor instead
    #
    # @return [Spawner] self
    ###
    removeActor: (actor) ->
      @_actors = _.without @_actors, (a) -> a.getId() == actor.getId()
      @

    ###
    # Removes all actively spawned Actors
    #
    # @return [Spawner] self
    ###
    killActor: (actor) ->
      @removeActor actor
      actor.destroy()
      @

    ###
    # Removes all actively spawned Actors
    #
    # @return [Spawner] self
    ###
    killActors: ->
      @_actors.map (a) -> a.destroy()
      @_actors = []
      @

    ###
    # Reset the particle system to its original state
    #
    # @return [Spawner] self
    ###
    reset: ->
      @_seedIncrement = 0
      @killActors()
      @

    ###
    # Spawn a new actor and add it to the internal list
    #
    # @return [Spawner] self
    ###
    spawn: ->
      @_seedIncrement++
      return @ unless @canSpawn()

      unless spawnData = @getSpawnableDump()
        AUtilLog.error "Invalid spawn data on particle system [#{spawnData}]"
        return

      actor = window[spawnData.type].load @ui, spawnData
      seed = @_properties.particles.seed.getValue()

      pos = @_properties.spawn.getValue()
      pos = new Vec2(pos.x, pos.y)
        .random(seed: seed + @_seedIncrement)
        .add(@_properties.position.getValue())

      actor.setPosition pos.x, pos.y
      actor.isParticle = true

      # spawned actors are not listed in the Timeline, so no need to spawn
      # events for them when updating
      actor._silentUpdate = true

      @_actors.push actor
      @

    ###
    # Callback during playback
    #
    # @param [Number] time current time
    # @return [Spawner] self
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
    # Pop open our settings dialog
    # @return [SettingsWidget] settingsWidget
    ###
    openConfigureDialog: ->

      new SettingsWidget @ui,
        title: "Particle System"
        settings: [
          label: "Max particle count"
          type: Number
          placeholder: "Enter a particle limit"
          value: @_properties.particles.max.getValue()
          id: "max"
          min: 0
        ,
          label: "Spawn frequency (ms)"
          type: Number
          placeholder: "Enter spawn frequency, minimum 50"
          value: @_properties.particles.frequency.getValue()
          id: "frequency"
          min: 50
        ]

        cb: (data) =>
          console.log data

    ###
    # Dumps the Spawner to a basic Object
    #
    # @return [Object] data
    ###
    dump: ->
      _.extend super(),
        psVersion: "1.2.0"
        uid: @_uid                                                     # v1.1.0
        #actorRandomSpawnDelta: @_actorRandomSpawnDelta.dump()         # v1.1.0
        #position: @_position.dump()                                   # v1.0.0
        #spawnCap: @_spawnCap                                          # v1.0.0
        spawnDumpList: @_spawnDumpList                                 # v1.0.0

    ###
    # Load the state of a dumped particle system into the current
    #
    # @param [Object] data
    # @return [Spawner] self
    ###
    load: (data) ->
      super data

      if data.psVersion >= "1.1.0"
        @_uid = data.uid                                               # v1.1.0
       #@_actorRandomSpawnDelta = Vec2.load data.actorRandomSpawnDelta # v1.1.0

      #@_position = Vec2.load data.position                            # v1.0.0
      #@_spawnCap = data.spawnCap                                      # v1.0.0
      @_spawnDumpList = data.spawnDumpList                             # v1.0.0

      @

    ###
    # Load a Spawner from a dump
    #
    # @param [Object] data
    # @return [Spawner] spawner
    ###
    @load: (ui, data) ->
      ps = new Spawner ui
      ps.load data
      ps
