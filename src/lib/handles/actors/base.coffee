###
@Changelog

  - "1.0.0": Initial
###

define (require) ->

  config = require "config"

  param = require "util/param"
  AUtilLog = require "util/log"

  Project = require "core/project"

  Handle = require "handles/handle"
  Bezier = require "handles/bezier"

  Actors = require "handles/actors"

  CompositeProperty = require "handles/properties/composite"
  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"

  # Base manipulateable class for actors
  Actors.BaseActor = class BaseActor extends Handle

    ###
    # @property [Number] accuracy the number of digits animations round-off to
    ###
    ACCURACY: config.precision.animation

    ###
    # Defines a raw actor, with no shape information or any other presets.
    # This serves as the base for the other actor classes
    #
    # @param [UIManager] ui
    # @param [Object] options
    #   @option [Number] lifetimeStart_ms  time at which we are created, in ms
    #   @option [Number] lifetimeEnd_ms  time we are destroyed, defaults to end of ad
    #   @option [Vec2] position  x starting coordinates
    #   @option [Number] rotation  angle in degrees
    #     @optional
    ###
    constructor: (@ui, options) ->
      param.required @ui
      param.required options

      super()

      position = param.optional options.position, { x: 0, y: 0 }
      rotation = param.optional options.rotation, 0

      @handleType = "BaseActor"

      @_AJSActor = null
      @setName "Base Actor #{@_id_numeric}"
      @_alive = false
      @_initialized = false # True after postInit() is called

      @lifetimeStart_ms = param.required options.lifetimeStart
      @lifetimeEnd_ms = param.optional options.lifetimeEnd, @ui.timeline.getDuration()

      ###
      # Property buffer, holds values at different points in time. Current
      # property values are calculated based on the current cursor position,
      # nearest two values and the described bezier representing the transition
      #
      # NOTE: This gets relatively large for complex actor lifetimes
      ###
      @_propBuffer = {}

      ###
      # This saves the state of our actor at the current cursor time, before
      # any modifications are made. Changes are calculated as the difference
      # between this snapshot, and our properties object.
      ###
      @_propSnapshot = null

      ###
      # Holds information on the bezier function to use for value changes
      # between states. If none is specified for a specific value change, the
      # value is assumed to change instantaneously upon leaving the start state
      #
      # Keys are named by the point in time where the associated animation ends
      # in ms. Values contain an array of individual animation objects, each
      # containing an Bezier instance for each property changed between the
      # start and end states
      #
      # If no control points are specified, linear interpolation is assumed
      ###
      ## TODO * Spin the mapping around, from Time Hash<String, Value> to
      ## String Hash<Time, Value>
      @_animations = {}

      # Set to true if the cursor is to the right of our last prop buffer, and
      # _capState() has been called
      @_capped = false

      # Time of the last update, used to save our properties when the cursor is
      # moved. Note that this starts at our birth!
      @_lastTemporalState = Math.floor @lifetimeStart_ms

      @enableTemporalUpdates()

      # should this actor not spawn events when updating?
      @_silentUpdate = false

      @_ctx = _.extend @_ctx,
        copy:
          name: config.locale.copy
          cb: => @_contextFuncCopy @
        dup:
          name: config.locale.duplicate
          cb: => @_contextFuncDuplicate @
        setTexture:
          name: config.locale.label.texture_modal
          cb: => @_contextFuncSetTexture @
        setTextureRepeat:
          name: config.locale.label.texture_repeat_modal
          cb: => @_contextFuncSetTextureRepeat @
        editPhysics:
          name: config.locale.label.physics_modal
          cb: => @_contextFuncEditPhysics @
        makeSpawner:
          name: config.locale.ctx.base_actor.make_spawner
          cb: => @ui.workspace.transformActorIntoSpawner @

      @initPropertyOpacity()
      @initPropertyRotation()
      @initPropertyPosition()
      @initPropertyLayer()
      @initPropertyColor()
      @initPropertyPhysics()
      @initPropertyTextureRepeat()

      @_properties.position.setValue position
      @_properties.rotation.setValue rotation

    ###
    # Initialize Actor opacity properties
    ###
    initPropertyOpacity: ->
      me = @

      @_properties.opacity = new NumericProperty()
      @_properties.opacity.setMin 0.0
      @_properties.opacity.setMax 1.0
      @_properties.opacity.setValue 1.0
      @_properties.opacity.setPlaceholder 1.0
      @_properties.opacity.setFloat true
      @_properties.opacity.setPrecision config.precision.opacity
      @_properties.opacity.onUpdate = (opacity) =>
        @_AJSActor.setOpacity opacity if @_AJSActor
      @_properties.opacity.requestUpdate = ->
        @setValue me._AJSActor.getOpacity() if me._AJSActor

    ###
    # Initialize Actor rotation properties
    ###
    initPropertyRotation: ->
      me = @

      @_properties.rotation = new NumericProperty()
      @_properties.rotation.setVisibleInToolbar false
      @_properties.rotation.setMin 0
      @_properties.rotation.setMax 360
      @_properties.rotation.setPrecision config.precision.rotation
      @_properties.rotation.onUpdate = (rotation) =>
        @_AJSActor.setRotation rotation if @_AJSActor
      @_properties.rotation.requestUpdate = ->
        @setValue me._AJSActor.getRotation() if me._AJSActor

    ###
    # Initialize Actor position properties
    ###
    initPropertyPosition: ->
      me = @

      @_properties.position = new CompositeProperty()
      @_properties.position.icon = config.icon.property_position
      @_properties.position.x = new NumericProperty()
      @_properties.position.y = new NumericProperty()

      @_properties.position.x.setPrecision config.precision.position
      @_properties.position.x.onUpdate = (value) =>
        return unless @_AJSActor
        position = @_AJSActor.getPosition()
        position.x = value
        @_AJSActor.setPosition position

      @_properties.position.y.setPrecision config.precision.position
      @_properties.position.y.onUpdate = (value) =>
        return unless @_AJSActor
        position = @_AJSActor.getPosition()
        position.y = value
        @_AJSActor.setPosition position

      @_properties.position.addProperty "x", @_properties.position.x
      @_properties.position.addProperty "y", @_properties.position.y

    ###
    # Initialize Actor layer properties
    ###
    initPropertyLayer: ->
      me = @

      @_properties.layer = new CompositeProperty()
      @_properties.layer.icon = config.icon.property_layer
      @_properties.layer.main = new NumericProperty()
      @_properties.layer.main.setValue 0
      @_properties.layer.main.setPrecision config.precision.layer

      @_properties.layer.physics = new NumericProperty()
      @_properties.layer.physics.clone @_properties.layer.main

      @_properties.layer.main.onUpdate = (layer) =>
        @_AJSActor.setLayer layer if @_AJSActor

      @_properties.layer.main.requestUpdate = ->
        @setValue me._AJSActor.getLayer() if me._AJSActor

      @_properties.layer.physics.onUpdate (layer) =>
        @_AJSActor.setPhysicsLayer layer if @_AJSActor

      @_properties.layer.physics.requestUpdate = ->
        @setValue me._AJSActor.getPhysicsLayer() if me._AJSActor

      @_properties.layer.addProperty "main", @_properties.layer.main
      @_properties.layer.addProperty "physics", @_properties.layer.physics

    ###
    # Initialize Actor color properties
    ###
    initPropertyColor: ->
      me = @

      @_properties.color = new CompositeProperty()
      @_properties.color.icon = config.icon.property_color

      ##
      ## Temporary, untill we have a color picker
      ##
      @_properties.color.setVisibleInToolbar false
      ##
      ##
      ##

      @_properties.color.r = new NumericProperty()
      @_properties.color.r.setMin 0
      @_properties.color.r.setMax 255
      @_properties.color.r.setFloat false
      @_properties.color.r.setPlaceholder 255
      @_properties.color.r.setValue 255
      @_properties.color.r.setPrecision config.precision.color

      @_properties.color.g = new NumericProperty()
      @_properties.color.b = new NumericProperty()
      @_properties.color.g.clone @_properties.color.r
      @_properties.color.b.clone @_properties.color.r

      @_properties.color.r.onUpdate = (value) =>
        return unless @_AJSActor
        color = @_AJSActor.getColor()
        color.setR value
        @_AJSActor.setColor color

      @_properties.color.g.onUpdate = (value) =>
        return unless @_AJSActor
        color = @_AJSActor.getColor()
        color.setG value
        @_AJSActor.setColor color

      @_properties.color.b.onUpdate = (value) =>
        return unless @_AJSActor
        color = @_AJSActor.getColor()
        color.setB value
        @_AJSActor.setColor color

      @_properties.color.r.requestUpdate = ->
        @setValue me._AJSActor.getColor().getR() if me._AJSActor

      @_properties.color.g.requestUpdate = ->
        @setValue me._AJSActor.getColor().getG() if me._AJSActor

      @_properties.color.b.requestUpdate = ->
        @setValue me._AJSActor.getColor().getB() if me._AJSActor

      @_properties.color.addProperty "r", @_properties.color.r
      @_properties.color.addProperty "g", @_properties.color.g
      @_properties.color.addProperty "b", @_properties.color.b

    ###
    # Initialize Actor physics properties
    ###
    initPropertyPhysics: ->
      me = @

      @_properties.physics = new CompositeProperty()
      @_properties.physics.icon = config.icon.property_physics

      @_properties.physics.mass = new NumericProperty()
      @_properties.physics.mass.setVisibleInToolbar false

      @_properties.physics.mass.setMin 0
      @_properties.physics.mass.setPlaceholder 50
      @_properties.physics.mass.setValue 50
      @_properties.physics.mass.setPrecision config.precision.physics_mass

      @_properties.physics.mass.onUpdate = (mass) =>
        @_AJSActor.setMass mass if @_AJSActor

      @_properties.physics.elasticity = new NumericProperty()
      @_properties.physics.elasticity.setVisibleInToolbar false
      @_properties.physics.elasticity.setMin 0
      @_properties.physics.elasticity.setMax 1
      @_properties.physics.elasticity.setPrecision config.precision.physics_elasticity
      @_properties.physics.elasticity.setPlaceholder 0.3
      @_properties.physics.elasticity.setValue 0.3

      @_properties.physics.elasticity.onUpdate = (elasticity) =>
        @_AJSActor.setElasticity elasticity if @_AJSActor

      @_properties.physics.friction = new NumericProperty()
      @_properties.physics.friction.setVisibleInToolbar false
      @_properties.physics.friction.setMin 0
      @_properties.physics.friction.setMax 1
      @_properties.physics.friction.setPrecision config.precision.physics_friction
      @_properties.physics.friction.setPlaceholder 0.2
      @_properties.physics.friction.setValue 0.2

      @_properties.physics.friction.onUpdate = (friction) =>
        @_AJSActor.setFriction friction if @_AJSActor


      @_properties.physics.enabled = new BooleanProperty()
      @_properties.physics.enabled.setValue false

      @_properties.physics.enabled.onUpdate = (enabled) =>
        return unless @_AJSActor

        if enabled
          @_AJSActor.enablePsyx()
        else
          @_AJSActor.disablePsyx()

      @_properties.physics.addProperty "mass", @_properties.physics.mass
      @_properties.physics.addProperty "elasticity", @_properties.physics.elasticity
      @_properties.physics.addProperty "friction", @_properties.physics.friction
      @_properties.physics.addProperty "enabled", @_properties.physics.enabled

    ###
    # Initialize Actor texture_repeat properties
    ###
    initPropertyTextureRepeat: ->
      me = @

      @_properties.textureRepeat = new CompositeProperty()
      @_properties.textureRepeat.x = new NumericProperty()
      @_properties.textureRepeat.x.setValue 1.0
      @_properties.textureRepeat.x.setPlaceholder 1.0
      @_properties.textureRepeat.x.setFloat true
      @_properties.textureRepeat.x.setPrecision config.precision.texture_repeat
      @_properties.textureRepeat.y = new NumericProperty()
      @_properties.textureRepeat.y.clone @_properties.textureRepeat.x

      @_properties.textureRepeat.x.onUpdate = (xRepeat) =>
        if @_AJSActor
          texRep = @_AJSActor.getTextureRepeat()
          @_AJSActor.setTextureRepeat xRepeat, texRep.y

      @_properties.textureRepeat.y.onUpdate = (yRepeat) =>
        if @_AJSActor
          texRep = @_AJSActor.getTextureRepeat()
          @_AJSActor.setTextureRepeat texRep.x, yRepeat

      @_properties.textureRepeat.x.requestUpdate = ->
        @setValue me._AJSActor.getTextureRepeat().x if me._AJSActor

      @_properties.textureRepeat.y.requestUpdate = ->
        @setValue me._AJSActor.getTextureRepeat().y if me._AJSActor

      @_properties.textureRepeat.addProperty "x", @_properties.textureRepeat.x
      @_properties.textureRepeat.addProperty "y", @_properties.textureRepeat.y

    ###
    # Get actor property by name
    #
    # @param [String] name
    # @return [Property] property
    ###
    getProperty: (name) ->
      @_properties[name]

    ###
    # Get the actor's name
    # @return [String] name
    ###
    getName: -> @name

    ###
    # Helper to get the index into our prop buffer for the birth entry
    #
    # @return [Number] index
    ###
    getBirthIndex: ->
      Math.floor @lifetimeStart_ms

    ###
    # Get internal actors' id. Note that the actor must exist for this!
    #
    # @return [Number] id
    ###
    getActorId: ->
      if @_AJSActor
        @_AJSActor.getId()
      else
        null

    ###
    # Get our internal actor
    #
    # @param [AJSBaseActor] actor
    ###
    getActor: -> @_AJSActor

    ###
    # @param [Booleab] _visible
    ###
    getVisible: ->
      if @_AJSActor
        @_AJSActor.getVisible()
      else
        false

    ###
    # Return actor opacity
    #
    # @return [Number] opacity
    ###
    getOpacity: -> 1.0

    ###
    # Return actor position as (x,y) relative to the GL world
    #
    # @return [Object] position
    ###
    getPosition: ->
      if @_AJSActor
        @_AJSActor.getPosition()
      else
        null

    ###
    # Get actor rotation
    #
    # @return [Number] angle in degrees
    ###
    getRotation: ->
      if @_AJSActor
        @_properties.rotation.getValue()
      else
        null

    ###
    # Return actor color as (r,g,b)
    #
    # @param [Boolean] float defaults to false, returns components as 0.0-1.0
    # @return [Object] color
    ###
    getColor: (float) ->
      float = param.optional float, false

      colorRaw = @_properties.color.getValue()
      color = new AJSColor3 colorRaw.r, colorRaw.g, colorRaw.b

      {
        r: color.getR(float)
        g: color.getG(float)
        b: color.getB(float)
      }

    ###
    # Return actor physics
    #
    # @return [Object] physics properties
    ###
    getPsyX: ->

      {
        enabled: @_properties.physics.getProperty("enabled").getValue()
        mass: @_properties.physics.getProperty("mass").getValue()
        elasticity: @_properties.physics.getProperty("elasticity").getValue()
        friction: @_properties.physics.getProperty("friction").getValue()
      }

    ###
    # Get buffer entry
    #
    # @param [Number] time
    # @return [Object] entry prop buffer entry, may be undefined
    ###
    getBufferEntry: (time) -> @_propBuffer[Math.floor time]

    ###
    # Check if the specified value is our birth (floors it)
    #
    # @param [Number] value
    # @return [Boolean] isBirth
    ###
    isBirth: (val) ->
      Math.floor(val) == Math.floor(@lifetimeStart_ms)

    ###
    # @param [Boolean] visible
    ###
    setVisible: (visible) ->
      @_AJSActor.setVisible visible if @_AJSActor
      @updateInTime()

    ###
    # Set actor position, relative to the GL world!
    #
    # @param [Number] x x coordinate
    # @param [Number] y y coordinate
    ###
    setPosition: (x, y) ->
      x = Number (param.required x).toFixed(@ACCURACY)
      y = Number (param.required y).toFixed(@ACCURACY)

      @_properties.position.setValue x: x, y: y
      @updateInTime()

    ###
    # Set actor rotation
    #
    # @param [Number] angle
    ###
    setRotation: (angle) ->
      angle = Number (param.required angle).toFixed(@ACCURACY)

      @_properties.rotation.setValue angle
      @updateInTime()

    ###
    # Set actor color with composite values, 0-255
    #
    # @param [Number] r
    # @param [Number] g
    # @param [Number] b
    ###
    setColor: (r, g, b) ->
      r = Number (param.required r).toFixed(@ACCURACY)
      g = Number (param.required g).toFixed(@ACCURACY)
      b = Number (param.required b).toFixed(@ACCURACY)

      @_properties.color.setValue r: r, g: g, b: b
      @updateInTime()

    ###
    # @param [Texture] texture
    ###
    setTexture: (@_texture) ->
      @_textureUID = @_texture.getUID()
      @_AJSActor.setTexture @_texture.getUID() if @_texture and @_AJSActor
      @updateInTime()

    ###
    # Set a texture by uid by searching the project textures
    # @param [String] uid
    ###
    setTextureByUID: (uid) ->
      texture = _.find Project.current.getTextures(), (t) ->
        t.getUID() == uid

      @_textureUID = uid

      try
        @setTexture texture
      catch e
        AUtilLog.warn "Texture not loaded yet, but continuing... [#{uid}]"

      @

    ###
    # Get the UID of the current texture, if we have one. Null otherwise
    #
    # @return [String] uid
    ###
    getTextureUID: ->
      @_textureUID

    ###
    # Used when exporting, executes the corresponding property genAnimationOpts
    # method if one exists. Returns null if the property does not exist, or if
    # the property does not have a genAnimationOpts method.
    #
    # @param [String] property property name
    # @param [Object] animation animation object
    # @param [Object] options input options
    # @param [String] component optional component name
    # @return [Object] options output options
    ###
    genAnimationOpts: (property, anim, opts, component) ->
      param.required property
      param.required anim
      param.required opts
      component = param.optional component, ""

      property = @_properties[property]
      return unless property

      if property.getType() == "composite"
        return unless property.getProperty(component).genAnimationOpts
        property.getProperty(component).genAnimationOpts anim, opts
      else
        property.genAnimationOpts anim, opts if property.genAnimationOpts

    ###
    # Called when the cursor leaves our lifetime on the timeline. We delete
    # our AJS actor if not already dead
    ###
    timelineDeath: ->
      return unless @_alive
      @_alive = false

      @_AJSActor.destroy()
      @_AJSActor = null

    ###
    # Virtual method that our children need to implement, called when our AJS
    # actor needs to be instantiated
    # @private
    ###
    _birth: ->

    ###
    # Get our living state
    #
    # @return [Boolean] alive
    ###
    isAlive: -> @_alive

    ###
    # Needs to be called after our are actor is instantiated, so we can prepare
    # our property buffer for proper use
    ###
    postInit: ->
      return if @_initialized
      @_initialized = true

      @_birth()

      # Set up properties by grabbing initial values
      @_properties[p].getValue() for p of @_properties

      # Make sure we have our texture (this lets us set the texture in the
      # constructor)
      @setTextureByUID @_textureUID if @_textureUID

      @updateInTime()

    ###
    # Seed the birth position in our property buffer with our current values
    ###
    seedBirth: ->
      @_propBuffer[Math.floor(@lifetimeStart_ms)] = @_serializeProperties()

    ###
    # Store the provided property deltas in a new buffer entry at the specified
    # time
    #
    # @param [Number] time
    # @param [Array<String>] deltas array of property names
    ###
    serializeDeltasToBufferEntry: (time, deltas) ->
      param.required time
      param.required deltas

      @_propBuffer[Math.floor(time)] ||= {}
      _.extend @_propBuffer[Math.floor(time)], @_serializeProperties deltas

    ###
    # Helper function to call a cb for each property. Useful to avoid writing
    # composite-aware property iterating code.
    #
    # Callback is called in the form cb(property, composite) where property is
    # the full property object, and composite is boolean
    #
    # @param [Object] properties properties object to parse
    # @param [Method] cb callback to call with every property
    ###
    perProp: (properties, cb) ->
      for name, property of properties

        # Composite iterate over components
        if property.getType() == "composite"
          for name, component of property.getProperties()
            cb component, true

        # Call cb with property (non-composite)
        else
          cb property, false

    ###
    # Calls the default handle updateProperties() method, then updates us in
    # time
    #
    # @param [Object] updates object containing property:value pairs
    ###
    updateProperties: (updates) ->
      super updates
      @updateInTime()

    ###
    # @return [BaseActor] self
    ###
    disableTemporalUpdates: ->
      @_temporalUpdatesEnabled = false

    ###
    # @return [BaseActor] self
    ###
    enableTemporalUpdates: ->
      @_temporalUpdatesEnabled = true

    ###
    # @return [Boolean] enabled
    ###
    areTemporalUpdatesEnabled: ->
      @_temporalUpdatesEnabled

    ###
    # Materialize the actor from various stored value deltas (woah, that sounds
    # epic). Essentially, update our prop buffer, and then the actors' current
    # state
    ###
    updateInTime: (time) ->
      @_birth() unless @_alive
      return unless @_temporalUpdatesEnabled

      time = Math.floor(param.optional time, @ui.timeline.getCursorTime())

      if @_propSnapshot == null
        @seedBirth()
        seededBirth = true
      else
        seededBirth = false

      @_updatePropBuffer()
      @_updateActorState time
      @_genSnapshot()

      @seedBirth() if @isBirth(time) and !seededBirth

      # Save state
      @_lastTemporalState = Number time

      unless @_silentUpdate
        @ui.events.push "actor", "update.intime", actor: @

      @

    ###
    # Generates a new snapshot from our current properties
    # @private
    ###
    _genSnapshot: ->

      @_propSnapshot = {}

      for pName, property of @_properties

        snapshot = {}

        if property.getType() == "composite"
          snapshot.components = {}

          for cName, cValue of property.getProperties()
            snapshot.components[cName] = value: cValue.getValue()

        else
          snapshot.value = property.getValue()

        unless isNaN snapshot.value
          snapshot.value = Number snapshot.value.toFixed @ACCURACY

        @_propSnapshot[pName] = snapshot

    ###
    # Finds states between our last temporal state, and the supplied state, and
    # applies them in order
    #
    # @param [Number] state
    # @private
    ###
    _applyKnownState: (state) ->
      state = Number param.required state
      return if state == @_lastTemporalState

      # Apply saved state. Find all stored states between our previous state
      # and the current one. Then sort, and finally apply in order.
      #
      # NOTE: The order of application varies depending on the direction in
      #       time in which we moved!
      right = state > @_lastTemporalState

      # Figure out intermediary states
      intermStates = []
      next = @_lastTemporalState

      while next != state and next != -1
        next = @findNearestState next, right

        if next != -1

          # Ensure next hasn't overshot us
          if (right and next <= state) or (!right and next >= state)
            intermStates.push next

      # Now sort accordingly
      intermStates.sort (a, b) ->

        # We moved back in time, lastTemporalState is in front of the state
        if right == false
          if a > b
            -1
          else if a < b
            1
          else
            0

        # We moved forwards in time, lastTemporalState is behind our state
        else
          if a > b
            1
          else if a < b
            -1
          else
            0

      # Now apply our states in the order presented
      @_applyPropBuffer @_propBuffer[s] for s in intermStates

    ###
    # Applies data in prop buffer entry
    #
    # @param [Object] buffer
    # @private
    ###
    _applyPropBuffer: (buffer) ->
      param.required buffer

      for name, property of buffer

        if property
          if property.components
            update = {}

            for cName, cValue of property.components
              update[cName] = cValue.value

            @_properties[name].setValue update

          else
            @_properties[name].setValue property.value

    ###
    # @param [Object]
    #   @property [Number] start
    #   @property [Number] end
    #   @property [Boolean] scaleToFit
    #     @optional
    # @return [self]
    ###
    adjustLifetime: (options) ->
      start = param.required options.start
      end = param.required options.end
      scaleToFit = param.optional options.scaleToFit, false

      oldStart = @lifetimeStart_ms
      oldEnd = @lifetimeEnd_ms

      # nothing has changed
      return if (oldStart == start) && (oldEnd == end)

      @lifetimeStart_ms = start
      @lifetimeEnd_ms = end

      animKeys = _.keys @_animations
      propKeys = _.keys @_propBuffer

      newAnimations = {}
      newPropBuffer = {}

      ratio = 1.0
      if scaleToFit
        ratio = (@lifetimeEnd_ms - @lifetimeStart_ms) / (oldEnd - oldStart)

      for time in propKeys
        newPropBuffer[Math.floor(start + (time - oldStart) * ratio)] = @_propBuffer[time]

      for time in animKeys
        newAnimations[Math.floor(start + (time - oldStart) * ratio)] = @_animations[time]

      @_propBuffer = newPropBuffer
      @_animations = newAnimations

      for key, animation of @_animations
        for property of animation
          @updateKeyframeTime property, key

    ###
    # Checks if the specified time is within our lifetime
    #
    # @param [Number] time
    # @return [Boolean] inLifetime
    ###
    inLifetime: (time) ->
      time >= @lifetimeStart_ms and time <= @lifetimeEnd_ms

    ###
    # Updates our state according to the current cursor position. Goes through
    # our prop buffer, and calculates a new snapshot and property object
    # accordingly.
    #
    # This is actually a tad complicated, as buffer entries are not full
    # property snapshots. Instead, they are snapshots of properties modified
    # at that point in time, with only our birth providing a full snapshot.
    #
    # Our properties object is fully specified initially using our birth
    # snapshot. From then on, all changes are incremental. So if we have 5 buffer
    # entries available and want to update our actor to the state specified
    # by the 4th, we need to apply birth state, followed by our updates in
    # the 2nd state, then 3rd, and finally 4th.
    #
    # Optimally however, we can remember our previous state, and only update
    # using the buffer entries we've passed over. In this case, if we are on
    # state 3 and want to move to state 5, we'd only apply state 4 inbetween.
    #
    # If we are, however, moving to a state that does not exist, we must
    # apply to the nearest state, and then calculate value deltas accordingly.
    # If we are not surrounded by two states (rare), our state is as specified
    # by the previous one we applied. If we are though (most often), we must
    # calculate new values using the specific bezier function each value
    # requires.
    #
    # The bezier function we require is stored in _animations (for each property)
    # with a name consisting of "end" where 'end' is the buffer entry for the
    # end state
    #
    # THIS IS SPARTAAAAAAA
    #
    # @private
    ###
    _updateActorState: (time) ->
      cursor = param.required time
      return unless @inLifetime cursor

      # If it's our birth state, take a shortcut and just apply it directly
      if cursor == Math.floor @lifetimeStart_ms
        return @_applyPropBuffer @_propBuffer[Math.floor @lifetimeStart_ms]

      # Find the nearest state to the left of ourselves
      if @_propBuffer[cursor]
        nearestState = cursor
      else
        nearestState = @findNearestState cursor

      @_applyKnownState nearestState if nearestState != @_lastAppliedState
      @_lastAppliedState = nearestState

      # Return if we have nothing else to do (cursor is at a known state)
      return if nearestState == cursor

      # Next, bail if there are no states to the right of ourselves
      return @_capState() if @findNearestState(cursor, true) == -1

      @_capped = false

      ##
      ## Now the fun part; find all values defined to the right of us
      ##
      ## Varying stores objects containing a property name and end cap
      varying = []

      # Helper
      _pushUnique = (p) ->
        unique = true

        for v in varying
          if v == p.name
            unique = false
            break

        varying.push p if unique

      from = nearestState
      while (from = @findNearestState(from, true)) != -1
        for p of @_propBuffer[from]
          _pushUnique { name: p, end: from }

      ##
      ## Now that we've built that list, go through and apply the delta of each
      ## property to ourselves
      ##
      for v in varying

        anim = @_animations[v.end]
        _prop = @_properties[v.name]

        # Sanity checks
        # TODO: Refactor these into log messages + returns
        unless _prop
          AUtilLog.error "Expected actor to have prop #{v.name}!"
          continue

        unless anim
          AUtilLog.error "Expected animation @ to exist #{v.end}!"
          continue

        continue unless anim[v.name]

        # The property to be animated is composite. Apply the state change
        # to each component individually.
        if _prop.getType() == "composite"

          val = {}

          for c of _prop.getProperties()
            _start = anim[v.name].components[c]._start.x

            # Ensure animation starts before us
            if _start <= cursor
              t = (cursor - _start) / (v.end - _start)

              val[c] = (anim[v.name].components[c].eval t).y

          # Store new value
          @_properties[v.name].setValue val

        else
          _start = anim[v.name]._start.x

          if _start <= cursor
            t = (cursor - _start) / (v.end - _start)

            val = (anim[v.name].eval t).y

            # Store new value
            @_properties[v.name].setValue val

    ###
    # This gets called if the cursor is to the right of us, and it has not yet
    # been called since the cursor has been in that state. It applies all buffer
    # states in order
    #
    # @private
    ###
    _capState: ->
      return if @_capped
      @_capped = true

      # Sort prop buffer entries
      entries = _.keys(@_propBuffer).map (b) -> Number b
      entries.sort (a, b) -> a - b

      # Apply buffers in order
      @_applyPropBuffer(@_propBuffer[entry]) for entry in entries

    ###
    # Returns an array containing the names of properties that have been
    # modified since our last snapshot. Used in @_updatePropBuffer
    #
    # @return [Array<String>] delta
    # @private
    ###
    _getPropertiesDelta: ->

      # Check which properties have changed
      # NOTE: We expect the prop snapshot to be valid, and contain the
      #       structure required by each property in it!
      delta = []
      for name, snapshot of @_propSnapshot
        modified = false

        # Compare snapshot with live property
        if @_properties[name].getType() == "composite"

          # Iterate over components to detect modification
          for cName, cValue of @_properties[name].getProperties()
            if snapshot.components[cName].value != cValue.getValue()
              modified = true

        else if snapshot.value != @_properties[name].getValue()
          modified = true

        # Differs, ship to delta
        delta.push name if modified

      delta

    ###
    # Split the animation overlapping the specified time, and operating on the
    # specified property. This replaces the animation (if there is one) with
    # two new animations to the left & right of it.
    #
    # @param [Object] animation property animation object to modify
    # @param [Object] startTime new start time
    # @param [Object] startP start position prop buffer entry
    # @private
    ###
    setAnimationStart: (animation, startTime, startP) ->
      param.required animation
      param.required startTime
      param.required startP

      if animation.components
        for c, componentVal of animation.components
          componentVal._start.x = startTime
          componentVal._start.y = startP.components[c].value

      else
        animation._start.x = startTime
        animation._start.y = startP.value

    ###
    # Create a new animation object ready for our @_animations hash
    #
    # @param [Object] options
    #   @option [Number] start start time
    #   @option [Number] end end time
    #   @option [Object] startSnapshot starting snapshot for property
    #   @option [Object] endSnapshot ending snapshot for property
    # @return [Object] animation
    ###
    createNewAnimation: (options) ->
      param.required options.start
      param.required options.end
      param.required options.startSnapshot
      param.required options.endSnapshot

      animation = {}

      if options.endSnapshot.components
        unless options.endSnapshot.components and options.startSnapshot.components
          throw new Error "Start and end snapshots don't both have components!"

        animation.components = {}

        for c, cVal of options.endSnapshot.components
          startPoint = x: options.start, y: options.startSnapshot.components[c].value
          endPoint = x: options.end, y: cVal.value

          bezzie = new Bezier startPoint, endPoint, 0, [], false
          animation.components[c] = bezzie
      else
        startPoint = x: options.start, y: options.startSnapshot.value
        endPoint = x: options.end, y: options.endSnapshot.value

        bezzie = new Bezier startPoint, endPoint, 0, [], false
        animation = bezzie

      animation

    ###
    # Calculates new prop buffer state, using current prop snapshot, cursor
    # position and existing properties.
    #
    # @private
    ###
    _updatePropBuffer: ->

      # If we have anything to save, ship to our buffer, and create a new
      # animation entry.
      #
      # cursor is our last temporal state, since the current cursor position
      # is not where the properties were set!
      if (deltas = @_getPropertiesDelta()).length > 0

        @serializeDeltasToBufferEntry @_lastTemporalState, deltas

        ###
        # Generate new animation entry for each changed property
        ###
        for p in deltas

          deltaStartTime = @findNearestState @_lastTemporalState, false, p
          deltaEndTime = @_lastTemporalState

          ###
          # Check if there is another animation after us; if so, update its
          # starting point.
          ###
          if (nextAnim = @findNearestState(@_lastTemporalState, true, p)) != -1

            startTime = @_lastTemporalState
            startP = @_propBuffer[@_lastTemporalState][p]

            @setAnimationStart @_animations[nextAnim][p], startTime, startP

          unless deltaStartTime == -1

            ###
            # Create a new transition if there is another state to the left
            ###
            @_animations[@_lastTemporalState] ||= {}
            @_animations[@_lastTemporalState][p] = @createNewAnimation
              start: deltaStartTime
              end: deltaEndTime
              startSnapshot: @_propBuffer[deltaStartTime][p]
              endSnapshot: @_propBuffer[deltaEndTime][p]

    ###
    # Return animations array
    #
    # @return [Array<Object>] animations
    ###
    getAnimations: -> @_animations

    ###
    # Get animation by time
    #
    # @param [Number] time
    # @return [Object] animation
    ###
    getAnimation: (time) -> @_animations[time]

    ###
    # Fetch time of preceding animation, null if there is none
    #
    # @param [Number] source search start time
    # @param [String] property finetune by finiding the nearest property
    #   @optional
    # @return [Number] time
    ###
    findPrecedingAnimationTime: (source, property) ->
      times = _.keys @_animations
      times.sort (a, b) -> a - b

      index = _.findIndex times, (t) -> Number(t) == source

      if property != undefined
        if (index > 0 && (index < times.length))
          for i in [(index-1)..0]
            time = times[i]
            if @_animations[time] && @_animations[time][property]
              return time
        else
          return _.find times.reverse(), (t) =>
            source > Number(t) && (@_animations[t] && @_animations[t][property])
      else
        if (index > 0 && (index < times.length))
          return times[index - 1]
        else
          return _.find times.reverse(), (t) -> source > Number(t)

      null

    ###
    # Fetch time of preceding animation, null if there is none
    #
    # @param [Number] source search start time
    # @param [String] property finetune by finiding the nearest property
    #   @optional
    # @return [Number] time
    ###
    findSucceedingAnimationTime: (source, property) ->
      times = _.keys @_animations
      times.sort (a, b) -> a - b

      index = _.findIndex times, (t) -> Number(t) == source

      if property != undefined
        if (index >= 0 && (index < times.length-1))
          for i in [(index+1)..(times.length-1)]
            time = times[i]
            if @_animations[time] && @_animations[time][property]
              return time
        else
          return _.find times, (t) =>
            Number(t) > source && (@_animations[t] && @_animations[t][property])
      else
        if (index >= 0 && (index < times.length-1))
          return times[index + 1]
        else
          return _.find times, (t) -> Number(t) > source

      null

    ###
    # Retrieve the nearest animation based on a source time
    # @return [Object] animation
    ###
    getNearestAnimationTime: (source, options) ->
      options = param.optional options, {}
      time = null

      if options.right
        time = @findSucceedingAnimationTime(source, options.property)
      else if options.left
        time = @findPrecedingAnimationTime(source, options.property)
      else
        lefttime = @findPrecedingAnimationTime(source, options.property)
        righttime = @findSucceedingAnimationTime(source, options.property)
        if (source - lefttime) < (righttime - source)
          time = lefttime
        else
          time = righttime

      time

    ###
    # Find the nearest prop buffer entry to the left/right of the supplied state
    # An optional property can be passed in, adding its existence as a criteria
    # for the returned state. Validation of the property is also performed
    #
    # @param [String] start prop buffer entry name to start from
    # @param [Boolean] right search to the right, defaults to false
    # @param [String] prop property name
    # @return [Number] nearest key into @_propBuffer
    # @private
    ###
    findNearestState: (start, right, prop) ->
      start = Number param.required start
      right = param.optional right, false
      prop = param.optional prop, null

      nearest = -1

      for time, buffer of @_propBuffer
        time = Number time

        if buffer
          if right and (time > start) and (time < nearest or nearest == -1)
            nearest = time if prop == null or buffer[prop]
          else if !right and (time < start) and (time > nearest)
            nearest = time if prop == null or buffer[prop]

      nearest

    ###
    # @param [String] property name of the property to affect
    # @param [Number] frametime the center frame time
    # @private
    ###
    updateKeyframeTime: (property, frametime) ->

      currentAnim = null

      succAnim = @findSucceedingAnimationTime frametime, property
      predAnim = @findPrecedingAnimationTime frametime, property

      # if a current frame exists...
      if @_animations[frametime]
        currentAnim = frametime

      # is there a current frame
      if currentAnim != null && currentAnim != undefined && \
       @_animations[currentAnim][property]
        @mutatePropertyAnimation @_animations[currentAnim][property], (a) =>
          a.setStartTime predAnim || Math.floor @lifetimeStart_ms
          a.setEndTime currentAnim

      # is there a succeeding frame?
      if succAnim != null && succAnim != undefined && \
       @_animations[succAnim][property]
        @mutatePropertyAnimation @_animations[succAnim][property], (a) =>
          a.setStartTime currentAnim || predAnim || Math.floor @lifetimeStart_ms
          a.setEndTime succAnim

    ###
    # Move the keyframe at the specified time and of the specified property to
    # the target time.
    #
    # NOTE: This does not check the validity of the transformation! Make SURE
    #       the keyframe can be legally moved to the target time! It must not
    #       cross over any other keyframes belonging to the same property.
    #
    # @param [String] property
    # @param [Number] source source time
    # @param [Number] destination target time
    ###
    transplantKeyframe: (property, source, destination) ->
      source = Math.floor source
      destination = Math.floor destination

      ##
      # If the source keyframe pos and destination keyframe pos are the same
      # skip transplanting.
      return if source == destination

      ##
      # Move prop buffer entry first
      if @_propBuffer[source]
        @_propBuffer[destination] ||= {}
        @_propBuffer[destination][property] = @_propBuffer[source][property]
        ##
        # Destroy the old property entry
        delete @_propBuffer[source][property]
        ##
        # If the property is now empty, delete it completely
        if _.keys(@_propBuffer[source]).length == 0
          delete @_propBuffer[source]

      ##
      # Now move the animation, update affected surrounding animations
      if @_animations[source]
        @_animations[destination] ||= {}
        @_animations[destination][property] = @_animations[source][property]
        ##
        # Destory the old property entry
        delete @_animations[source][property]
        ##
        # If the property is now empty, delete it completely
        if _.keys(@_animations[source]).length == 0
          delete @_animations[source]

      # update all sorrounding keyframes for both the source and destination
      @updateKeyframeTime property, source
      @updateKeyframeTime property, destination

    ###
    # Runs the callback for each animation object found on the property
    # animation; runs it for each component for composites (useful). The
    # callback is given each animation object (Bezier)
    #
    # @param [Object] animationSet animation property entry
    # @param [Method] cb
    ###
    mutatePropertyAnimation: (animationSet, cb) ->
      if animationSet.components
        _.each _.values(animationSet.components), (animation) -> cb animation
      else
        cb animationSet

    ###
    # Prepares our properties object for injection into the buffer. In essence,
    # builds a new object containing only current values, and returns it for
    # inclusion in the buffer.
    #
    # @param [Array<String>] delta array of property names to serialize
    # @return [Object] serialProps properties ready to be buffered
    # @private
    ###
    _serializeProperties: (delta) ->

      # If no property names are supplied, serialize all properties
      delta = param.optional delta, []

      # Go through and build an object for our buffer, simple
      props = {}

      for name, value of @_properties
        needsSerialization = false

        if delta.length == 0
          needsSerialization = true
        else
          needsSerialization = _.find(delta, (d) -> d == name) != undefined

        props[name] = value.getBufferSnapshot() if needsSerialization

      props

    ###
    # Takes serialized properties at the specified cursor time, and de-serializes
    # them; essentially reading out values and setting them appropriately in our
    # live properties object.
    #
    # @param [String] time string index into our prop buffer (cursor time in ms)
    # @private
    ###
    _deserializeProperties: (time) ->
      props = @_propBuffer[time]

      # Manually set property values
      for p of props

        # Set values component-wise if required, otherwise direct
        if props[p].components
          for c of props[p].components
            @_properties[p].components[c]._value = props[p].components[c].value
        else
          @_properties[p]._value = props[p].value

    ###
    # Deletes us, muahahahaha. We notify the workspace, clear the properties
    # panel if it is targetting us, and destroy our actor.
    ###
    delete: ->
      if @_AJSActor != null

        # Go through and remove ourselves from
        @_AJSActor.disablePsyx()
        @_AJSActor.destroy()
        @_AJSActor = null

      # Notify the workspace
      @ui.workspace.notifyDemise @

      super()

    ###
    # Make a clone of the current Actor
    # @return [BaseActor]
    ###
    duplicate: ->

      dumpdata = @dump()
      Actors[dumpdata.type].load @ui, dumpdata

    ###
    # Set Texture context menu function
    # @param [BaseActor] actor
    ###
    _contextFuncSetTexture: (actor) ->
      @ui.modals.showSetTexture actor
      @

    ###
    # Open a settings widget for texture repeat editing
    # @param [BaseActor] actor
    ###
    _contextFuncSetTextureRepeat: (actor) ->
      @ui.modals.showActorTextureRepeatSettings actor
      @

    ###
    # Copy the current actor to the clipboard
    # @param [BaseActor] actor
    ###
    _contextFuncCopy: (actor) ->
      AdefyEditor.clipboard =
        type: "actor"
        reason: "copy"
        data: @

      @

    ###
    # Immediately copy and paste the current actor into the workspace
    # @param [BaseActor] actor
    ###
    _contextFuncDuplicate: (actor) ->

      newActor = actor.duplicate()
      newActor.setName(newActor.getName() + " copy")
      pos = newActor.getPosition()
      newActor.setPosition pos.x + 16, pos.y + 16

      @ui.workspace.addActor newActor
      @

    ###
    # Open a settings widget for physics editing
    # @param [BaseActor] actor
    ###
    _contextFuncEditPhysics: (actor) ->
      @ui.modals.showEditActorPsyx actor
      @

    ###
    # Goes through and makes sure that our birth state contains an entry for
    # each of our properties. Deletes buffer entries if they reference
    # properties we don't have.
    #
    # This makes sure older saves can be loaded by newer actor code.
    ###
    _ensureBufferIntegrity: ->
      @_ensureBirthIntegrity()
      @_normalizePropBuffer()

    ###
    # Make sure each of our properties is represented in the prop buffer birth
    # entry, and delete any foreign ones.
    #
    # WARNING: This uses the current values of our properties in case they are
    #          found to be missing!
    ###
    _ensureBirthIntegrity: ->
      birth = @_propBuffer[@getBirthIndex()]

      for prop, propValue of @_properties

        # Property exists, confirm composite nature if necessary
        if birth[prop]
          if birth[prop].components and propValue.getType() != "composite"

            AUtilLog.warning "Invalid birth entry [#{prop}] expected composite"
            AUtilLog.warning "Repairing birth entry"
            birth[prop] = propValue.getBufferSnapshot()
        else
          AUtilLog.warning "Birth entry not found for [#{prop}], repairing.."
          birth[prop] = propValue.getBufferSnapshot()

    ###
    # Go through and delete any entries in our prop buffer that don't exist in
    # our properties hash. This makes loading old saves safer, in case of them
    # including entries we no longer support
    ###
    _normalizePropBuffer: ->
      for entry, buffer of @_propBuffer
        for prop of buffer
          unless @_properties[prop]
            AUtilLog.warning "Unsupported property in prop buffer [#{prop}]"
            AUtilLog.warning "Removing #{prop} from buffer entry #{entry}"
            delete @_propBuffer[entry][prop]

    ###
    # Dump actor into basic Object
    #
    # @return [Object] actorJSON
    ###
    dump: ->
      data = super()

      data.actorBaseVersion = "1.0.0"
      data.propBuffer = _.clone @_propBuffer, true
      data.birth = @lifetimeStart_ms
      data.death = @lifetimeEnd_ms
      data.texture = @getTextureUID()
      data.animations = {}

      for time, properties of @_animations
        animationSet = {}

        for property, propAnimation of properties

          if propAnimation.components
            animationData = components: {}

            for component, animation of propAnimation.components
              animationData.components[component] = animation.dump()

          else
            animationData = propAnimation.dump()

          animationSet[property] = animationData

        data.animations[time] = animationSet

      data

    ###
    # Loads properties, animations, and a prop buffer from a saved state
    #
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->

      # Load basic properties
      super data

      # Load everything else
      @_propBuffer = data.propBuffer

      # Ensure the prop buffer contains entries for each of our properties (it
      # won't if we've added something and are loading an older save)
      @_ensureBufferIntegrity()

      @setTextureByUID data.texture if data.texture

      @_animations = {}
      for time, properties of data.animations
        animationSet = {}

        for property, propAnimation of properties

          if propAnimation.components
            animationData = components: {}

            for component, animation of propAnimation.components
              animationData.components[component] = Bezier.load animation

          else
            animationData = Bezier.load propAnimation

          animationSet[property] = animationData

        @_animations[time] = animationSet

      @
