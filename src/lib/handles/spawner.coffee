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

  Actors = require "handles/actors"
  BaseActor = require "handles/actors/base"

  CompositeProperty = require "handles/properties/composite"
  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"

  SettingsWidget = require "widgets/floating/settings"

  Actors.Spawner = class Spawner extends BaseActor

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

        for spawner in Spawner.SPAWNERS
          spawner.tick(now)
          spawner.previewTick(now)

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

      _.remove Spawner.SPAWNERS, (s) -> s.getID() == spawner.getID()

    ###
    # @param [UIManager] ui
    # @param [Object] options
    ###
    constructor: (@ui, options) ->
      param.required options

      # Don't save this, as it is volatile (likely immediately deleted)
      template = param.required options.templateHandle

      super @ui,
        lifetimeStart: template.lifetimeStart_ms
        lifetimeEnd: template.lifetimeEnd_ms

      @_imitateHandle template

      @handleType = "Spawner"
      @setName "#{@handleType} #{@_id_numeric}"

      @_uid = ID.uID()

      @_actorRandomSpawnDelta = new Vec2(0, 0)

      @_spawns = []
      @_previewSpawns = []
      @_lastSpawnTime = Date.now()
      @_lastSpawnUpdateTime = Date.now()
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
      @_initPropertyState()
      @_initPropertyParticles()
      @_initPropertyDirection()
      @_initPropertyVelocity()
      @_initPropertyVelocityRange()
      @_overridePhysicsProperty()

      window.s ||= []
      window.s.push @

      @_properties.position.setVisibleInToolbar true
      @_properties.layer.setVisibleInToolbar true

      # Ensure the spawner update cycle is both running, and includes us
      Spawner.setupUpdateInterval()

    ###
    # Horrible method (check @updateInTime()) that we need to register ourselves
    # after birth...
    #
    # Actor time handling has to be heavily refactored, with all birth/death
    # management moved into actors. Aka, don't call updateInTime() expecting to
    # be in a valid time period (at the moment, the Timeline checks...)
    ###
    __fugly_postBirth: ->
      Spawner.registerSpawner @

    ###
    # Check if the preview spawns are active
    #
    # @return [Boolean] active
    ###
    isPreviewActive: ->
      @_properties.state.preview.getValue()

    ###
    # Check if the spawner is active
    #
    # @return [Boolean] active
    ###
    isActive: ->
      @_properties.state.active.getValue()

    ###
    # Set the active state of the spawner
    #
    # @param [Boolean] active
    ###
    setActive: (active) ->
      @_properties.state.active.setValue active

    ###
    # Set the active state of the preview spawns
    #
    # @param [Boolean] active
    ###
    setPreviewActive: (active) ->
      @_properties.state.preview.setValue active

    ###
    # Copy over all unique properties of the provided handle. This essentially
    # turns us into a base for our own spawns.
    #
    # NOTE: This should probably only be called once! Preferably in our
    #       constructor
    ###
    _imitateHandle: (handle) ->

      keepMethods = [
        "constructor"
        "delete"
        "load"
        "dump"
        "timelineDeath"
        "__fugly_postBirth"
      ]

      constructor_name = handle.constructor.name
      unless Actors[constructor_name]
        throw new Error "Unkown handle class #{constructor_name}!"

      # Copy over unique methods
      for name, method of Actors[constructor_name].prototype
        unless "#{@[name]}" == "#{method}" or _.contains keepMethods, name
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
    ###
    _initPropertyParticles: ->
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

    ###
    # Setup properties in charge of enabling us throughout time
    ###
    _initPropertyState: ->
      @_properties.state = new CompositeProperty()
      @_properties.state.active = new BooleanProperty()
      @_properties.state.preview = new BooleanProperty()

      @_properties.state.active.setValue false
      @_properties.state.preview.setValue false

      @_properties.state.addProperty "active", @_properties.state.active
      @_properties.state.addProperty "preview", @_properties.state.preview

    ###
    # Set up the property that specifies the end of a vector starting at our
    # origin, representing the direction of initial spawns
    ###
    _initPropertyDirection: ->
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
    _initPropertyVelocity: ->
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
    _initPropertyVelocityRange: ->
      @_properties.velocityRange = new CompositeProperty()
      @_properties.velocityRange.setVisibleInToolbar false

      @_properties.velocityRange.x = new NumericProperty()
      @_properties.velocityRange.x.setValue 2
      @_properties.velocityRange.y = new NumericProperty()
      @_properties.velocityRange.y.setValue 2

      @_properties.velocityRange.addProperty "x", @_properties.velocityRange.x
      @_properties.velocityRange.addProperty "y", @_properties.velocityRange.y

    ###
    # Replace the generic physics property handling. Maps property updates to
    # only those handles that support them
    ###
    _overridePhysicsProperty: ->
      @_properties.physics.enabled.setValue false

      @_properties.physics.mass.onUpdate = (mass) =>
        _.union(@_spawns, @_previewSpawns).map (handle) ->
          handle.setMass mass if handle.setMass

      @_properties.physics.elasticity.onUpdate = (elasticity) =>
        _.union(@_spawns, @_previewSpawns).map (handle) ->
          handle.setElasticity elasticity if handle.setElasticity

      @_properties.physics.friction.onUpdate = (friction) =>
        _.union(@_spawns, @_previewSpawns).map (handle) ->
          handle.setFriction friction if handle.setFriction

      @_properties.physics.enabled.onUpdate = (enabled) =>
        _.union(@_spawns, @_previewSpawns).map (handle) ->
          if enabled
            handle.enablePhysics() if handle.enablePhysics
          else
            handle.disablePhysics() if handle.disablePhysics

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
    # Deletes us, and all of our spawns
    ###
    delete: ->
      Spawner.unregisterSpawner @

      _.union(@_previewSpawns, @_spawns).map (spawn) -> spawn.delete()

      @_previewSpawns = []
      @_spawns = []

      super()

    ###
    # Called when we transition from life to death in time. De-registers us and
    # deletes all spawns
    ###
    timelineDeath: ->
      Spawner.unregisterSpawner @

      _.union(@_previewSpawns, @_spawns).map (spawn) -> spawn.delete()

      @_previewSpawns = []
      @_spawns = []

      super()

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
      time = param.optional time, Date.now()

      spawn = @_generateSpawn time

      @initializeSpawn spawn

      @_spawns.push spawn
      @

    ###
    # Spawn a new preview actor; This actor has a lower opacity
    #
    # @param [Number] time time of spawn (used with lifetime to expire spawn)
    # @return [Spawner] self
    ###
    spawnPreview: (time) ->
      time = param.optional time, Date.now()

      spawn = @_generateSpawn time
      spawn.getProperty("opacity").setValue 0.25

      @initializeSpawn spawn

      @_previewSpawns.push spawn
      @

    ###
    # Initialize spawn actor and properties
    #
    # @param [Handle] spawn
    ###
    initializeSpawn: (spawn) ->

      spawn.getProperty("layer").main.setValue @_properties.layer.main.getValue() - 0.1

      # Attach velocity
      velocityRange = @_properties.velocityRange.getValue()
      velocity = @_properties.velocity.getValue()
      pos = @_properties.position.getValue()

      finalVel =
        x: velocity.x + (Math.random() * velocityRange.x)
        y: velocity.y + (Math.random() * velocityRange.y)

      spawn._velocity = finalVel

      # Apply physics impulse directly on ARE actor (low-level, hacky)
      if @_properties.physics.enabled.getValue()
        ARE_id = spawn.getActor().getId()
        ARE_actor = _.find ARERenderer.actors, (a) -> a.getId() == ARE_id

        if ARE_actor and ARE_actor._body
          impulse = ARERenderer.screenToWorld
            x: finalVel.x * 1000
            y: finalVel.y * 1000

          ARE_actor._body.applyImpulse impulse, new cp.v(0, 0)

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

      actor = Actors[@getSpawnableClassName()].load @ui, @dump()
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
    # @param [Number] now time returned by Date.now()
    # @return [Spawner] self
    ###
    tick: (now) ->
      max = @_properties.particles.max.getValue()
      freq = @_properties.particles.frequency.getValue()

      if @isActive()
        if now - @_lastSpawnTime >= freq and @_spawns.length <= max
          @_lastSpawnTime = now
          @spawn now

      @preformUpdate now
      @

    ###
    # Called by our own preview interval, updates our preview visuals
    #
    # @param [Number] now time returned by Date.now()
    # @return [Spawner] self
    ###
    previewTick: (now) ->
      max = @_properties.particles.max.getValue()
      freq = @_properties.particles.frequency.getValue()

      if @isPreviewActive()
        if now - @_lastPreviewSpawnTime >= freq and @_previewSpawns.length <= max
          @_lastPreviewSpawnTime = now
          @spawnPreview now

      @preformPreviewUpdate now
      @

    ###
    # Update our preview actors in time. Velocity is pixels/second
    #
    # @param [Number] now time returned by Date.now()
    ###
    preformPreviewUpdate: (now) ->
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
          @updateSpawn spawn

    ###
    # Update our spawns in time. Velocity is pixels/second
    #
    # @param [Number] now time returned by Date.now()
    ###
    preformUpdate: (now) ->
      dt = (now - @_lastSpawnUpdateTime) / 1000
      @_lastSpawnUpdateTime = now

      return unless @_spawns.length > 0

      # Iterate backwards so we can safely splice expired actors
      for i in [@_spawns.length - 1..0]
        spawn = @_spawns[i]

        # Expire if we need to
        if (now - spawn._spawnTime) > @_properties.particles.lifetime.getValue()
          spawn.delete()
          @_spawns.splice i, 1
        else
          @updateSpawn spawn

    ###
    # Update spawned object, both preview and not
    #
    # @param [Handle] spawn
    ###
    updateSpawn: (spawn) ->
      unless spawn.getProperty("physics").enabled.getValue()
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
          label: "Lifetime"
          type: Number
          placeholder: "Enter lifetime in ms"
          value: @_properties.particles.lifetime.getValue()
          id: "lifetime"
          min: 0
        ,
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
        ,
          label: "Target X"
          type: Number
          placeholder: "Enter target x"
          value: @_properties.direction.x.getValue()
          id: "direction_x"
          halfw: true
        ,
          label: "Target Y"
          type: Number
          placeholder: "Enter target y"
          value: @_properties.direction.y.getValue()
          id: "direction_y"
          halfw: true
        ,
          label: "Velocity min X"
          type: Number
          placeholder: "Enter velocity min x"
          value: @_properties.velocity.x.getValue()
          id: "velocity_min_x"
          halfw: true
        ,
          label: "Velocity min Y"
          type: Number
          placeholder: "Enter velocity min y"
          value: @_properties.velocity.y.getValue()
          id: "velocity_min_y"
          halfw: true
        ,
          label: "Velocity max X"
          type: Number
          placeholder: "Enter velocity max x"
          value: @_properties.velocityRange.x.getValue()
          id: "velocity_max_x"
          halfw: true
        ,
          label: "Velocity max Y"
          type: Number
          placeholder: "Enter velocity max y"
          value: @_properties.velocityRange.y.getValue()
          id: "velocity_max_y"
          halfw: true
        ,
          label: "Physics"
          type: Boolean
          placeholder: "Enabled"
          value: @_properties.physics.enabled.getValue()
          id: "physics_enabled"
          halfw: true
        ,
          label: "Mass"
          type: Number
          placeholder: "Enter physics mass"
          value: @_properties.physics.mass.getValue()
          id: "physics_mass"
          halfw: true
        ,
          label: "Friction"
          type: Number
          placeholder: "Enter physics friction"
          value: @_properties.physics.friction.getValue()
          id: "physics_friction"
          halfw: true
        ,
          label: "Elasticity"
          type: Number
          placeholder: "Enter physics elasticity"
          value: @_properties.physics.elasticity.getValue()
          id: "physics_elasticity"
          halfw: true
        ]

        cb: (data) =>
          @_properties.particles.max.setValue data.max
          @_properties.particles.frequency.setValue data.frequency
          @_properties.particles.lifetime.setValue data.lifetime

          @_properties.direction.x.setValue data.direction_x
          @_properties.direction.y.setValue data.direction_y

          @_properties.velocity.x.setValue data.velocity_min_x
          @_properties.velocity.y.setValue data.velocity_min_y
          @_properties.velocityRange.x.setValue data.velocity_max_x
          @_properties.velocityRange.y.setValue data.velocity_max_y

          @_properties.physics.enabled.setValue data.physics_enabled
          @_properties.physics.mass.setValue data.physics_mass
          @_properties.physics.friction.setValue data.physics_friction
          @_properties.physics.elasticity.setValue data.physics_elasticity

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
      templateHandle = Actors[data.spawnableClassName].load ui, data
      spawner = new Spawner ui, templateHandle: templateHandle
      spawner.load data
      templateHandle.delete()

      spawner
