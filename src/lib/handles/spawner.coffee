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
  BaseActor = require "handles/actors/base"

  CompositeProperty = require "handles/properties/composite"
  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"

  SettingsWidget = require "widgets/floating/settings"

  class Spawner extends BaseActor

    @UPDATE_RESOLUTION: 10 # ms
    @UPDATE_INTERVAL: null
    @SPAWNERS: []

    ###
    # Static helper to setup the update interval for all spawners
    ###
    @setupUpdateInterval: ->
      return if Spawner.UPDATE_INTERVAL

      Spawner.UPDATE_INTERVAL = setInterval ->
        now = Date.now()

        spawner.previewTick(now) for spawner in Spawner.SPAWNERS

      , Spawner.UPDATE_RESOLUTION

    ###
    # This prevents all spawners from updating!
    ###
    @clearUpdateInterval: ->
      return unless Spawner.UPDATE_INTERVAL

      clearInterval Spawner.UPDATE_INTERVAL
      Spawner.UPDATE_INTERVAL = null

    ###
    # Adds a spawner to the list of spawners that we update
    #
    # @param [Spawner] spawner
    ###
    @registerSpawner: (spawner) ->
      unless spawner instanceof Spawner
        AUtilLog.error "Provided object is not a spawner, refusing to register!"
        return

      Spawner.SPAWNERS.push spawner

    ###
    # Removes a spanwer from the list of those we update
    #
    # @param [Spawner] spawner
    ###
    @unregisterSpawner: (spawner) ->
      unless spawner instanceof Spawner
        AUtilLog.error "Provided object is not a spawner, refusing to register!"
        return

      _.remove Spawner.SPAWNERS, (s) -> s.getId() == spawner.getId()

    ###
    # @param [UIManager] ui
    # @param [Object] options
    ###
    constructor: (@ui, options) ->
      param.required options

      # Don't save this, as it is volatile (likely immediately deleted)
      template = param.required options.templateHandle

      super @ui, template.lifetimeStart_ms, template.lifetimeEnd_ms

      @_imitateHandle template

      @handleType = "Spawner"
      @setName "#{@handleType} #{@_id_numeric}"

      @_uid = ID.uID()

      @_actorRandomSpawnDelta = new Vec2(0, 0)

      @_spawns = []
      @_previewSpawns = []
      @_lastSpawnTime = Date.now()
      @_lastPreviewSpawnTime = Date.now()
      @_lastPreviewUpdateTime = Date.now()

      @_seedIncrement = 0

      ## for testing
      @_ctx.spawn =
        name: config.locale.ctx.spawner.spawn
        cb: => @spawn()

      @_ctx.configure =
        name: config.locale.ctx.spawner.configure
        cb: => @openConfigureDialog()

      delete @_ctx.makeSpawner

      @hideAllProperties()
      @initPropertyParticles()
      @initPropertyDirection()
      @initPropertyVelocity()
      @initPropertyVelocityRange()

      @_properties.position.setVisibleInToolbar true
      @_properties.layer.setVisibleInToolbar true

      @postInit()

      # Ensure the spawner update cycle is both running, and includes us
      Spawner.setupUpdateInterval()
      Spawner.registerSpawner @

    ###
    # Copy over all unique properties of the provided handle. This essentially
    # turns us into a base for our own spawns.
    #
    # NOTE: This should probably only be called once! Preferably in our
    #       constructor
    ###
    _imitateHandle: (handle) ->

      unless window[handle.constructor.name]
        throw new Error "Unkown handle class #{handle.constructor.name}!"

      # Copy over unique methods
      for name, method of window[handle.constructor.name].prototype
        unless "#{@[name]}" == "#{method}" or name == "constructor"
          @[name] = _.clone method, true

      # Update our own properties to match
      for name, property of handle._properties

        if @_properties[name]
          if property.dump
            @_properties[name].clone property
          else
            @_properties[name].load property
        else

          # Copy over unique properties
          # NOTE: This assigns them by reference!
          if property.dump
            @_properties[name] = property
          else
            if property.type == "composite"
              @_properties[name] = new CompositeProperty()
            else if property.type == "number"
              @_properties[name] = new NumericProperty()
            else if property.type == "boolean"
              @_properties[name] = new BooleanProperty()

            @_properties[name].load property if @_properties[name]

      @_propBuffer = _.clone handle._propBuffer, true
      @_animations = _.clone handle._animations, true

      @setTextureByUID handle.getTextureUID()
      @_imitationActorType = handle.constructor.name

    ###
    # Get the name of the class we spawn
    #
    # @return [String] name
    ###
    getSpawnableClassName: ->
      @_imitationActorType

    ###
    # Initialize our particles property
    #
    # @return [Spawner] self
    ###
    initPropertyParticles: ->
      @_properties.particles = new CompositeProperty()
      @_properties.particles.setVisibleInToolbar false

      @_properties.particles.seed = new NumericProperty()
      @_properties.particles.seed.setPrecision 0
      @_properties.particles.seed.setValue Math.floor(Math.random() * 0xFFFF)

      @_properties.particles.max = new NumericProperty()
      @_properties.particles.max.setPrecision 0
      @_properties.particles.max.setValue 50

      @_properties.particles.frequency = new NumericProperty()
      @_properties.particles.frequency.setMin 50
      @_properties.particles.frequency.setPrecision 0
      @_properties.particles.frequency.setValue 50

      @_properties.particles.lifetime = new NumericProperty()
      @_properties.particles.lifetime.setMin 100
      @_properties.particles.lifetime.setPrecision 0
      @_properties.particles.lifetime.setValue 700

      @_properties.particles.addProperty "seed", @_properties.particles.seed
      @_properties.particles.addProperty "max", @_properties.particles.max
      @_properties.particles.addProperty "frequency", @_properties.particles.frequency
      @_properties.particles.addProperty "lifetime", @_properties.particles.lifetime

      @

    ###
    # Set up the property that specifies the end of a vector starting at our
    # origin, representing the direction of initial spawns
    ###
    initPropertyDirection: ->
      @_properties.direction = new CompositeProperty()
      @_properties.direction.setVisibleInToolbar false

      @_properties.direction.x = new NumericProperty()
      @_properties.direction.x.setValue 0
      @_properties.direction.y = new NumericProperty()
      @_properties.direction.y.setValue 10

      @_properties.direction.addProperty "x", @_properties.direction.x
      @_properties.direction.addProperty "y", @_properties.direction.y

    ###
    # Set up the property responsible for the initial velocity of spawns.
    # Units are pixels/s
    ###
    initPropertyVelocity: ->
      @_properties.velocity = new CompositeProperty()
      @_properties.velocity.setVisibleInToolbar false

      @_properties.velocity.x = new NumericProperty()
      @_properties.velocity.x.setValue 0
      @_properties.velocity.y = new NumericProperty()
      @_properties.velocity.y.setValue 0

      @_properties.velocity.addProperty "x", @_properties.velocity.x
      @_properties.velocity.addProperty "y", @_properties.velocity.y

    ###
    # Set up the property by which spawn velocity is randomly offset
    ###
    initPropertyVelocityRange: ->
      @_properties.velocityRange = new CompositeProperty()
      @_properties.velocityRange.setVisibleInToolbar false

      @_properties.velocityRange.x = new NumericProperty()
      @_properties.velocityRange.x.setValue 2
      @_properties.velocityRange.y = new NumericProperty()
      @_properties.velocityRange.y.setValue 2

      @_properties.velocityRange.addProperty "x", @_properties.velocityRange.x
      @_properties.velocityRange.addProperty "y", @_properties.velocityRange.y

    ###
    # Remove an actor from the actors list
    # NOTE* This does not destroy the actor, use killActor instead
    #
    # @return [Spawner] self
    ###
    removeActor: (actor) ->
      @_spawns = _.without @_spawns, (a) -> a.getId() == actor.getId()
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
      @_spawns.map (a) -> a.destroy()
      @_spawns = []
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
    # @param [Number] time time of spawn (used with lifetime to expire spawn)
    # @return [Spawner] self
    ###
    spawn: (time) ->
      param.required time

      @_spawns.push @_generateSpawn time
      @

    ###
    # Spawn a new preview actor; This actor has a lower opacity
    #
    # @param [Number] time time of spawn (used with lifetime to expire spawn)
    # @return [Spawner] self
    ###
    spawnPreview: (time) ->
      param.required time

      spawn = @_generateSpawn time
      spawn.getProperty("layer").main.setValue @_properties.layer.main.getValue() - 0.1
      spawn.getProperty("opacity").setValue 0.5

      # Attach velocity
      velocityRange = @_properties.velocityRange.getValue()
      velocity = @_properties.velocity.getValue()

      spawn._velocity =
        x: velocity.x + (Math.random() * velocityRange.x)
        y: velocity.y + (Math.random() * velocityRange.y)

      @_previewSpawns.push spawn
      @

    ###
    # Generate a spawned actor. This actor is not tracked by the workspace or
    # timeline!
    #
    # @param [Number] time time of spawn (used with lifetime to expire spawn)
    # @return [BaseActor] actor
    ###
    _generateSpawn: (time) ->
      param.required time
      @_seedIncrement++

      actor = window[@getSpawnableClassName()].load @ui, @dump()
      actor.disableTemporalUpdates()

      seed = @_properties.particles.seed.getValue()

      position = @_properties.position.getValue()
      direction = @_properties.direction.getValue()

      finalX = position.x + (Math.random() * direction.x)
      finalY = position.y + (Math.random() * direction.y)

      actor.isParticle = true
      actor.getProperty("position").setValue
        x: finalX
        y: finalY

      actor._spawnTime = time

      # Spawned actors are not listed in the Timeline, so no need to spawn
      # events for them when updating
      actor._silentUpdate = true
      actor

    ###
    # Callback during playback
    #
    # @param [Number] time current time
    # @return [Spawner] self
    ###
    tick: (time) ->
      max = @particles.particles.max.getValue()
      freq = @getFrequency()

      if freq == 0
        while @_spawns.length < max
          @spawn()

      else
        # determine if we need to spawn an actor or not
      @

    ###
    # Called by our own preview interval, updates our preview visuals
    #
    # @param [Number] now time returned by Date.now()
    ###
    previewTick: (now) ->
      max = @_properties.particles.max.getValue()
      freq = @_properties.particles.frequency.getValue()

      if now - @_lastPreviewSpawnTime >= freq and @_previewSpawns.length <= max
        @_lastPreviewSpawnTime = now
        @spawnPreview now

      @updatePreview now

    ###
    # Update our preview actors in time. Velocity is pixels/second
    #
    # @param [Number] now time returned by Date.now()
    ###
    updatePreview: (now) ->
      dt = (now - @_lastPreviewUpdateTime) / 1000
      @_lastPreviewUpdateTime = now

      return unless @_previewSpawns.length > 0

      # Iterate backwards so we can safely splice expired actors
      for i in [@_previewSpawns.length - 1..0]
        spawn = @_previewSpawns[i]

        # Expire if we need to
        if (now - spawn._spawnTime) > @_properties.particles.lifetime.getValue()
          spawn.delete()
          @_previewSpawns.splice i, 1
        else
          pos = spawn.getProperty("position")

          currentPosition = pos.getValue()

          pos.setValue
            x: currentPosition.x + spawn._velocity.x
            y: currentPosition.y + spawn._velocity.y

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
        psVersion: "1.3.0"
        uid: @_uid                                                     # v1.1.0
        spawnableClassName: @getSpawnableClassName()                   # v1.3.0
        #actorRandomSpawnDelta: @_actorRandomSpawnDelta.dump()         # v1.1.0
        #position: @_position.dump()                                   # v1.0.0
        #spawnCap: @_spawnCap                                          # v1.0.0
        #spawnDumpList: @_spawnDumpList                                # v1.0.0

    ###
    # Load the state of a dumped particle system into the current
    #
    # @param [Object] data
    # @return [Spawner] self
    ###
    load: (data) ->
      super data

      if data.psVersion >= "1.1.0"
        @_uid = data.uid

      if data.psVersion >= "1.3.0"
        @_imitationActorType = data.spawnableClassName

      @

    ###
    # Load a Spawner from a dump
    #
    # @param [Object] data
    # @return [Spawner] spawner
    ###
    @load: (ui, data) ->
      templateHandle = window[data.spawnableClassName].load ui, data
      spawner = new Spawner ui, templateHandle: templateHandle
      spawner.load data
      templateHandle.delete()

      spawner
