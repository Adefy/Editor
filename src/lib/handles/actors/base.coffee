###
@Changelog

  - "1.0.0": Initial
###

define (require) ->

  config = require "config"
  param = require "util/param"

  AUtilLog = require "util/log"
  Handle = require "handles/handle"
  Bezier = require "handles/bezier"
  BoundingBox = require "widgets/bounding_box"

  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"
  CompositeProperty = require "handles/properties/composite"
  Project = require "project"

  # Base manipulateable class for actors
  window.BaseActor = class BaseActor extends Handle

    ###
    # @property [Number] accuracy the number of digits animations round-off to
    ###
    ACCURACY: config.precision.base

    ###
    # Defines a raw actor, with no shape information or any other presets.
    # This serves as the base for the other actor classes
    #
    # @param [UIManager] ui
    # @param [Number] birthTime time at which we are created, in ms
    # @param [Number] deathTime time we are destroyed, defaults to end of ad
    ###
    constructor: (@ui, birthTime, deathTime) ->
      super()

      @setHandleType "BaseActor"
      @setName "Base Actor #{@_id_numeric}"

      @_AREActor = null
      @_alive = false
      @_initialized = false # True after _postInit() is called

      @_birthTime = Math.floor birthTime
      @_deathTime = Math.floor(deathTime or @ui.timeline.getDuration())

      @_ctx = _.extend @_ctx,
        copy:
          name: config.strings.copy
          cb: => @_contextFuncCopy @
        dup:
          name: config.strings.duplicate
          cb: => @_contextFuncDuplicate @

      @_initProperties @_birthTime, @_deathTime

    #####################################
    #####################################
    ### @mark Property Initialisation ###
    #####################################
    #####################################

    ###
    # Initialize all of our properties
    # @private
    ###
    _initProperties: (birth, death) ->
      return unless _.isEmpty @_properties

      @_initPropertyOpacity birth, death
      @_initPropertyRotation birth, death
      @_initPropertyPosition birth, death
      @_initPropertyLayer birth, death
      @_initPropertyColor birth, death
      @_initPropertyPhysics birth, death
      @_initPropertyTextureRepeat birth, death

    ###
    # Initialize Actor opacity property
    # @private
    ###
    _initPropertyOpacity: (birth, death) ->
      me = @

      @_properties.opacity = new NumericProperty
        birth: birth, death: death
        min: 0, max: 0, value: 1
        placeholder: 1
        float: true
        precision: config.precision.opacity

      @_properties.opacity.onUpdate = (opacity) =>
        @_AREActor.setOpacity opacity if @_AREActor
      @_properties.opacity.requestUpdate = ->
        @setValue me._AREActor.getOpacity() if me._AREActor

    ###
    # Initialize Actor rotation properties
    # @private
    ###
    _initPropertyRotation: (birth, death) ->
      me = @

      @_properties.rotation = new NumericProperty
        birth: birth, death: death
        min: 0, max: 360
        precision: config.precision.rotation

      @_properties.rotation.onUpdate = (rotation) =>
        @_AREActor.setRotation -rotation if @_AREActor
      @_properties.rotation.requestUpdate = ->
        @setValue me._AREActor.getRotation() if me._AREActor

    ###
    # Initialize Actor position properties
    # @private
    ###
    _initPropertyPosition: (birth, death) ->
      me = @

      @_properties.position = new CompositeProperty birth: birth, death: death
      @_properties.position.icon = config.icon.property_position
      @_properties.position.x = new NumericProperty
        birth: birth, death: death
        precision: config.precision.position
      @_properties.position.y = new NumericProperty
        birth: birth, death: death
        precision: config.precision.position

      @_properties.position.x.onUpdate = (value) =>
        return unless @_AREActor
        position = @_AREActor.getPosition()
        position.x = value
        @_AREActor.setPosition position

      @_properties.position.x.requestUpdate = ->
        @setValue me._AREActor.getPosition().x if me._AREActor

      @_properties.position.y.onUpdate = (value) =>
        return unless @_AREActor
        position = @_AREActor.getPosition()
        position.y = value
        @_AREActor.setPosition position

      @_properties.position.y.requestUpdate = ->
        @setValue me._AREActor.getPosition().y if me._AREActor

      @_properties.position.addProperty "x", @_properties.position.x
      @_properties.position.addProperty "y", @_properties.position.y

    ###
    # Initialize Actor layer properties
    # @private
    ###
    _initPropertyLayer: (birth, death) ->
      me = @

      @_properties.layer = new CompositeProperty birth: birth, death: death
      @_properties.layer.icon = config.icon.property_layer
      @_properties.layer.main = new NumericProperty
        birth: birth, death: death
        min: 0, value: 0
        precision: config.precision.layer

      @_properties.layer.main.onUpdate = (layer) =>
        @_AREActor.setLayer layer if @_AREActor

      @_properties.layer.physics = new NumericProperty
        birth: birth, death: death
        min: 0, max: 15, value: 0
        precision: config.precision.physicsLayer

      @_properties.layer.physics.validateValue = (val) ->
        val >= 0 && val < 16 && Math.round(val) == val

      @_properties.layer.physics.onUpdate = (layer) =>
        @_AREActor.setPhysicsLayer layer if @_AREActor

      @_properties.layer.addProperty "main", @_properties.layer.main
      @_properties.layer.addProperty "physics", @_properties.layer.physics

    ###
    # Initialize Actor color properties
    # @private
    ###
    _initPropertyColor: (birth, death) ->
      me = @

      @_properties.color = new CompositeProperty birth: birth, death: death
      @_properties.color.icon = config.icon.property_color

      @_properties.color.r = new NumericProperty
        birth: birth, death: death
        min: 0, max: 255, value: 0
        float: false
        placeholder: 255
        precision: config.precision.color

      @_properties.color.g = new NumericProperty birth: birth, death: death
      @_properties.color.b = new NumericProperty birth: birth, death: death
      @_properties.color.g.clone @_properties.color.r
      @_properties.color.b.clone @_properties.color.r

      @_properties.color.r.onUpdate = (value) =>
        return unless @_AREActor
        color = @_AREActor.getColor()
        color.setR value
        @_AREActor.setColor color

      @_properties.color.g.onUpdate = (value) =>
        return unless @_AREActor
        color = @_AREActor.getColor()
        color.setG value
        @_AREActor.setColor color

      @_properties.color.b.onUpdate = (value) =>
        return unless @_AREActor
        color = @_AREActor.getColor()
        color.setB value
        @_AREActor.setColor color

      @_properties.color.r.requestUpdate = ->
        @setValue me._AREActor.getColor().getR() if me._AREActor

      @_properties.color.g.requestUpdate = ->
        @setValue me._AREActor.getColor().getG() if me._AREActor

      @_properties.color.b.requestUpdate = ->
        @setValue me._AREActor.getColor().getB() if me._AREActor

      @_properties.color.addProperty "r", @_properties.color.r
      @_properties.color.addProperty "g", @_properties.color.g
      @_properties.color.addProperty "b", @_properties.color.b

    ###
    # Initialize Actor physics properties
    # @private
    ###
    _initPropertyPhysics: (birth, death) ->
      me = @

      @_properties.physics = new CompositeProperty birth: birth, death: death
      @_properties.physics.icon = config.icon.property_physics

      @_properties.physics.mass = new NumericProperty
        birth: birth, death: death
        min: 0, value: 50
        placeholder: 50
        precision: config.precision.physics_mass

      @_properties.physics.mass.onUpdate = (mass) =>
        @_AREActor.setMass mass if @_AREActor

      @_properties.physics.elasticity = new NumericProperty
        birth: birth, death: death
        min: 0, max: 1, value: 0.3
        placeholder: 0.3
        precision: config.precision.physics_elasticity

      @_properties.physics.elasticity.onUpdate = (elasticity) =>
        @_AREActor.setElasticity elasticity if @_AREActor

      @_properties.physics.friction = new NumericProperty
        birth: birth, death: death
        min: 0, max: 1, value: 0.2
        placeholder: 0.2
        precision: config.precision.physics_friction

      @_properties.physics.friction.onUpdate = (friction) =>
        @_AREActor.setFriction friction if @_AREActor


      @_properties.physics.enabled = new BooleanProperty
        birth: birth, death: death
      @_properties.physics.enabled.setValue false

      @_properties.physics.enabled.onUpdate = (enabled) =>
        return unless @_AREActor
        return unless enabled != @_AREActor.hasPhysics()

        mass = @_properties.physics.mass.getValue()
        elasticity = @_properties.physics.elasticity.getValue()
        friction = @_properties.physics.friction.getValue()

        if enabled
          @_AREActor.createPhysicsBody mass, friction, elasticity
        else
          @_AREActor.destroyPhysicsBody()

      @_properties.physics.addProperty "mass", @_properties.physics.mass
      @_properties.physics.addProperty "elasticity", @_properties.physics.elasticity
      @_properties.physics.addProperty "friction", @_properties.physics.friction
      @_properties.physics.addProperty "enabled", @_properties.physics.enabled

    ###
    # Initialize Actor texture_repeat properties
    # @private
    ###
    _initPropertyTextureRepeat: (birth, death) ->
      me = @

      @_properties.textureRepeat = new CompositeProperty
        birth: birth, death: death
      @_properties.textureRepeat.x = new NumericProperty
        birth: birth, death: death
        value: 1
        placeholder: 1
        float: true
        precision: config.precision.texture_repeat

      @_properties.textureRepeat.y = new NumericProperty
        birth: birth, death: death
      @_properties.textureRepeat.y.clone @_properties.textureRepeat.x

      @_properties.textureRepeat.x.onUpdate = (xRepeat) =>
        if @_AREActor
          texRep = @_AREActor.getTextureRepeat()
          @_AREActor.setTextureRepeat xRepeat, texRep.y

      @_properties.textureRepeat.y.onUpdate = (yRepeat) =>
        if @_AREActor
          texRep = @_AREActor.getTextureRepeat()
          @_AREActor.setTextureRepeat texRep.x, yRepeat

      @_properties.textureRepeat.x.requestUpdate = ->
        @setValue me._AREActor.getTextureRepeat().x if me._AREActor

      @_properties.textureRepeat.y.requestUpdate = ->
        @setValue me._AREActor.getTextureRepeat().y if me._AREActor

      @_properties.textureRepeat.addProperty "x", @_properties.textureRepeat.x
      @_properties.textureRepeat.addProperty "y", @_properties.textureRepeat.y

    #####################################
    #####################################
    ### @mark Accessors #################
    #####################################
    #####################################

    ###
    # Checks if we have any keyframes
    #
    # @return [Boolean] isAnimated
    ###
    isAnimated: ->
      for name, property of @_properties
        return true if property.hasKeyframes()

      false

    ###
    # Fetch a compiled hash of our property keyframes. The hash is structured
    # with time keys holding arrays of keyframe definitions
    ###
    getKeyframes: ->
      keyframes = {}

      for name, property of @_properties
        times = property.getKeyframeTimes()
        keys = property.getKeyframes()

        if times.length > 1
          for time in times
            if time != @getBirthTime() and time != @getDeathTime()
              keyframes[time] ||= []
              keyframes[time].push
                property: name
                value: keys[time]

      keyframes

    ###
    # Set low level handle type. Don't use this unless you know what you are
    # doing!
    #
    # @param [String] type
    ###
    setHandleType: (type) ->
      @_handleType = type

    ###
    # Get the low level handle type
    #
    # @return [String] type
    ###
    getHandleType: ->
      @_handleType

    ###
    # Get the time we are born, in MS
    #
    # @return [Number] time
    ###
    getBirthTime: ->
      @_birthTime

    ###
    # Get the time we die, in MS
    #
    # @return [Number] time
    ###
    getDeathTime: ->
      @_deathTime

    ###
    # Get actor property by name
    #
    # @param [String] name
    # @return [Property] property
    ###
    getProperty: (name) ->
      @_properties[name]

    ###
    # Get actor rotation
    #
    # @return [Number] angle in degrees
    ###
    getRotation: ->
      @_properties.rotation.getValue()

    ###
    # Return actor opacity
    #
    # @return [Number] opacity
    ###
    getOpacity: ->
      @_properties.opacity.getValue()

    ###
    # Return actor position as (x,y) relative to the GL world
    #
    # @return [Object] position
    ###
    getPosition: ->
      @_properties.position.getValue()

    ###
    # Return actor color as (r,g,b)
    #
    # @param [Boolean] float defaults to false, returns components as 0.0-1.0
    # @return [Object] color
    ###
    getColor: (float) ->
      float = !!float

      colorRaw = @_properties.color.getValue()
      color = new AREColor3 colorRaw.r, colorRaw.g, colorRaw.b

      {
        r: color.getR float
        g: color.getG float
        b: color.getB float
      }

    ###
    # Return actor physics properties as an object
    #
    # @return [Object] properties
    ###
    getPsyX: ->
      {
        enabled: @_properties.physics.getProperty("enabled").getValue()
        mass: @_properties.physics.getProperty("mass").getValue()
        elasticity: @_properties.physics.getProperty("elasticity").getValue()
        friction: @_properties.physics.getProperty("friction").getValue()
      }

    ###
    # @param [Boolean] visible
    ###
    setVisible: (visible) ->
      @_AREActor.setVisible visible if @_AREActor

    ###
    # Set actor position, relative to the GL world!
    #
    # @param [Number] x x coordinate
    # @param [Number] y y coordinate
    ###
    setPosition: (x, y) ->
      @_properties.position.setValue
        x: Number(x.toFixed @ACCURACY)
        y: Number(y.toFixed @ACCURACY)

    ###
    # Set actor rotation
    #
    # @param [Number] angle
    ###
    setRotation: (angle) ->
      @_properties.rotation.setValue Number(angle.toFixed @ACCURACY)

    ###
    # Set actor color with composite values, 0-255
    #
    # @param [Number] r
    # @param [Number] g
    # @param [Number] b
    ###
    setColor: (r, g, b) ->
      @_properties.color.setValue
        r: Number(r.toFixed @ACCURACY)
        g: Number(g.toFixed @ACCURACY)
        b: Number(b.toFixed @ACCURACY)

      @clearTexture()

    ###
    # Check if we have a texture applied
    #
    # @return [Boolean] texture
    ###
    hasTexture: ->
      if @_AREActor
        @_AREActor.hasTexture()
      else
        false

    ###
    # Clear our set texture (if any); reverts us to solid color rendering
    ###
    clearTexture: ->
      @_AREActor.clearTexture() if @_AREActor
      @_textureUID = null

    ###
    # Set our texture with a full texture object
    #
    # @param [Texture] texture
    ###
    setTexture: (@_texture) ->
      @_textureUID = @_texture.getUID()
      @_AREActor.setTexture @_texture.getUID() if @_texture and @_AREActor

    ###
    # Set a texture by uid by searching the project textures
    # @param [String] uid
    ###
    setTextureByUID: (uid) ->
      texture = _.find Project.current.getTextures(), (t) ->
        t.getUID() == uid

      @_textureUID = uid

      # This may fail if the texture hasn't fully loaded yet.
      try
        @setTexture texture

      @

    ###
    # Get the UID of the current texture, if we have one. Null otherwise
    #
    # @return [String] uid
    ###
    getTextureUID: ->
      @_textureUID

    ###
    # Get the actor's name
    #
    # @return [String] name
    ###
    getName: ->
      @name

    ###
    # Get internal actors' id. Note that the actor must exist for this!
    #
    # @return [Number] id
    ###
    getActorId: ->
      if @_AREActor
        @_AREActor.getId()
      else
        null

    ###
    # Get our internal actor
    #
    # @param [ARERawActor] actor
    ###
    getActor: ->
      @_AREActor

    ###
    # @param [Booleab] _visible
    ###
    getVisible: ->
      if @_AREActor
        @_AREActor.getVisible()
      else
        false

    ###
    # Get our living state
    #
    # @return [Boolean] alive
    ###
    isAlive: ->
      @_alive

    #####################################
    #####################################
    ### @mark Temporal Manipulation #####
    #####################################
    #####################################

    ###
    # Needs to be called after our are actor is instantiated, so we can prepare
    # our property buffer for proper use
    #
    # @private
    ###
    _postInit: ->
      return if @_initialized
      @_initialized = true

      @seekToBirth()

      # Set up properties by grabbing initial values
      @_properties[p].getValue() for p of @_properties

    ###
    # Kill the actor, needs to be respawned later with a call to @birth()
    ###
    death: ->
      return unless @_alive
      @_alive = false

      @hideBoundingBox()
      @_AREActor.destroy()
      @_AREActor = null

    showBoundingBox: ->
      return unless @_AREActor and !@_boundingBox

      @_boundingBox = new BoundingBox @ui
      @_AREActor.setOnOrientationChange (u) =>
        return unless @_boundingBox

        if u.position
          u.position = @ui.workspace.glToDom u.position.x, u.position.y

        @_boundingBox.updateOrientation u

      @_AREActor.setOnSizeChange (u) =>
        return unless @_boundingBox
        @_boundingBox.updateBounds u

    hideBoundingBox: ->
      return unless @_boundingBox

      @_boundingBox.remove()
      @_boundingBox = null

    boundingBoxVisible: ->
      !!@_boundingBox

    ###
    # Create the actor; can be killed later with a call to @death()
    #
    # MUST be overriden by specialised actors, as we do not update our @_alive
    # flag ourselves!
    ###
    birth: ->
      @showBoundingBox()

      # Make sure we have our texture (this lets us set the texture in the
      # constructor)
      @setTextureByUID @_textureUID if @_textureUID

    ###
    # Really, really ugly (FUGLY) method we need so spawners can register
    # themselves after birth (they can't override @birth....)
    #
    # @TODO GET RID OF THIS
    # @private
    ###
    __fugly_postBirth: ->

    ###
    # Seek the actor to the specified time; should be called by the timeline
    # in sync with all of the other actors.
    #
    # @param [Number] time valid timeline time in ms
    ###
    seekToTime: (time) ->
      @_ensureExistenceMatchesTime time
      return unless @isAlive()

      property.seekToTime time for name, property of @_properties

    ###
    # Equivalent of @seekToTime() with our birth time
    ###
    seekToBirth: ->
      @seekToTime @_birthTime

    ###
    # Equivalent of @seekToTime() with our death time
    ###
    seekToDeath: ->
      @seekToTime @_deathTime

    ###
    # Make sure we are either alive or dead, as necessary for the specified time
    #
    # @param [Number] time
    ###
    _ensureExistenceMatchesTime: (time) ->
      if @_alive and (time < @_birthTime or time >= @_deathTime)
        @death()
      else if not @_alive and (time >= @_birthTime and time < @_deathTime)
        @birth()

    #####################################
    #####################################
    ### @mark Utilities #################
    #####################################
    #####################################

    ###
    # Deletes us, muahahahaha. We notify the workspace, clear the properties
    # panel if it is targetting us, and destroy our actor.
    ###
    delete: ->
      @death()
      @ui.workspace.notifyDemise @
      super()

    ###
    # Make a clone of the current Actor
    # @return [BaseActor]
    ###
    duplicate: ->
      dumpdata = @dump()
      window[dumpdata.type].load @ui, dumpdata

    ###
    # Copy the current actor to the clipboard
    # @param [BaseActor] actor
    ###
    _contextFuncCopy: (actor) ->
      window.AdefyEditor.clipboard =
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
      newActor.setName "#{newActor.getName()} copy"
      pos = newActor.getPosition()
      newActor.setPosition pos.x + 16, pos.y + 16

      @ui.workspace.addActor newActor
      @

    ###
    # Dump actor into basic Object
    #
    # @return [Object] actorJSON
    ###
    dump: ->
      _.extend super(),
        actorBaseVersion: "2.0.0"
        birth: @getBirthTime()
        death: @getDeathTime()
        texture: @getTextureUID()

    ###
    # Loads properties, animations, and a prop buffer from a saved state
    #
    # @param [Object] data
    # @return [self]
    ###
    load: (data) ->
      @_birthTime = data.birth
      @_deathTime = data.death

      super data # Load basic properties

      @setTextureByUID data.texture if data.texture
      @
