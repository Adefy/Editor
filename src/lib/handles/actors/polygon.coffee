define (require) ->

  config = require "config"
  param = require "util/param"

  Actors = require "handles/actors"
  BaseActor = require "handles/actors/base"

  NumericProperty = require "handles/properties/numeric"

  # N-sided actor
  Actors.PolygonActor = class PolygonActor extends BaseActor

    ###
    # Defines a variable-sided actor, psicktually
    #
    # @param [UIManager] ui
    # @param [Object] options
    #   @option [Number] lifetimeStart  time in ms at which we are to be created
    #   @option [Number] lifetimeEnd  death time specification
    #     @optional
    #   @option [Number] sides  the n in ngon
    #   @option [Number] radius  ngon radius
    #   @option [Vec2] position  x starting coordinates
    #   @option [Number] rotation  angle in degrees
    #     @optional
    #   @option [Boolean] manualInit  postInit() not called if true
    #     @optional
    ###
    constructor: (@ui, options) ->
      param.required @ui
      param.required options

      sides      = param.required options.sides
      radius     = Math.abs param.required options.radius
      manualInit = !!options.manualInit

      throw new Error "Can't create an ngon with less than 3 sides" if sides < 3

      super @ui, options

      @handleType = "PolygonActor"

      @setName "Polygon #{@_id_numeric}"

      @initPropertySides()
      @initPropertyRadius()

      @_properties.sides.setValue sides
      @_properties.radius.setValue radius

      @postInit() unless manualInit

    ###
    # Initialize Actor sides property
    ###
    initPropertySides: ->
      @_properties.sides = new NumericProperty()
      @_properties.sides.setMin 3
      @_properties.sides.setPlaceholder 5
      @_properties.sides.setFloat false
      @_properties.sides.setValue 3
      @_properties.sides.setPrecision config.precision.sides
      @_properties.sides.onUpdate = (sides) =>
        @_areActor.setSegments sides if @_areActor

      @_properties.sides.genAnimationOpts = (animation, options) ->
        options.startVal = animation._start.y
        options

    ###
    # Initialize Actor radius property
    ###
    initPropertyRadius: ->
      @_properties.radius = new NumericProperty()
      @_properties.radius.setMin 0
      @_properties.radius.setPlaceholder 50
      @_properties.radius.setValue 10
      @_properties.radius.setPrecision config.precision.radius
      @_properties.radius.onUpdate = (radius) =>
        @_areActor.setRadius radius if @_areActor

      @_properties.sides.genAnimationOpts = (animation, options) ->
        options.startVal = animation._start.y
        options


    ###
    # Get polygon side count
    #
    # @return [Number] sides
    ###
    getSides: -> @_properties.sides.getValue()

    ###
    # Get rectangle radius value
    #
    # @return [Number] radius
    ###
    getRadius: -> @_properties.radius.getValue()

    ###
    # Instantiate our ARE actor
    # @private
    ###
    _birth: ->
      return if @_alive
      @_alive = true

      physicsEnabled = @_properties.physics.getProperty("enabled").getValue()
      mass = @_properties.physics.getProperty("mass").getValue()
      friction = @_properties.physics.getProperty("friction").getValue()
      elasticity = @_properties.physics.getProperty("elasticity").getValue()

      x = @_properties.position.getProperty("x").getValue()
      y = @_properties.position.getProperty("y").getValue()

      r = @_properties.color.getProperty("r").getValue()
      g = @_properties.color.getProperty("g").getValue()
      b = @_properties.color.getProperty("b").getValue()

      radius = @_properties.radius.getValue()
      segments = @_properties.sides.getValue()
      rotation = @_properties.rotation.getValue()
      position = new AREVector2 x, y
      color = new AREColor3 r, g, b

      @_areActor = new AREPolygonActor @ui.getARERenderer(), radius, segments
      if physicsEnabled
        @_areActor.createPhysicsBody mass, friction, elasticity

      @_areActor.setPosition position
      @_areActor.setColor color
      @_areActor.setRotation rotation

      super()

    ###
    # Initializes a new PolygonActor using serialized data
    #
    # @param [UIManager] ui
    # @param [Object] data
    ###
    @load: (ui, data) ->

      birth = data.birth
      death = data.death

      position = data.properties.position

      sides = data.properties.sides.value
      radius = data.properties.radius.value
      x = position.x.value
      y = position.y.value
      rotation = data.properties.rotation.value

      actor = new PolygonActor ui,
        lifetimeStart: birth
        lifetimeEnd: death
        sides: sides
        radius: radius
        position: x: x, y: y
        rotation: rotation
      actor.load data
      actor
