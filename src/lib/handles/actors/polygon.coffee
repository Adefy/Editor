define (require) ->

  config = require "config"
  param = require "util/param"

  BaseActor = require "handles/actors/base"

  NumericProperty = require "handles/properties/numeric"

  # N-sided actor
  window.PolygonActor = class PolygonActor extends BaseActor

    ###
    # Defines a variable-sided actor, psicktually
    #
    # @param [UIManager] ui
    # @param [Number] birth time in ms at which we are to be created
    # @param [Number] sides the n in ngon
    # @param [Number] radius ngon radius
    # @param [Number] x x starting coordinate
    # @param [Number] y y starting coordinate
    # @param [Number] rotation optional, angle in degrees
    # @param [Number] death optional death time specification
    # @param [Boolean] manualInit optional, postInit() not called if true
    ###
    constructor: (@ui, birth, sides, radius, x, y, rotation, death, manualInit) ->
      param.required @ui
      param.required sides
      radius = Math.abs param.required radius
      param.required x
      param.required y
      manualInit = param.optional manualInit, false
      rotation = param.optional rotation, 0

      throw new Error "Can't create an ngon with less than 3 sides" if sides < 3

      super @ui, birth, death

      @handleType = "PolygonActor"

      @setName "Polygon #{@_id_n}"

      @_properties.position.setValue x: x, y: y
      @_properties.rotation.setValue rotation

      @_properties.sides = new NumericProperty()
      @_properties.sides.setMin 3
      @_properties.sides.setPlaceholder 5
      @_properties.sides.setFloat false
      @_properties.sides.setValue sides
      @_properties.sides.setPrecision config.precision.sides
      @_properties.sides.onUpdate = (sides) =>
        @_AJSActor.setSegments sides if @_AJSActor

      @_properties.sides.genAnimationOpts = (animation, options) ->
        options.startVal = animation._start.y
        options

      @_properties.radius = new NumericProperty()
      @_properties.radius.setMin 0
      @_properties.radius.setPlaceholder 50
      @_properties.radius.setValue radius
      @_properties.radius.setPrecision config.precision.radius
      @_properties.radius.onUpdate = (radius) =>
        @_AJSActor.setRadius radius if @_AJSActor

      @_properties.sides.genAnimationOpts = (animation, options) ->
        options.startVal = animation._start.y
        options

      @postInit() unless manualInit

    # Get polygon side count
    #
    # @return [Number] sides
    getSides: -> @_properties.sides.getValue()

    # Get rectangle radius value
    #
    # @return [Number] radius
    getRadius: -> @_properties.radius.getValue()

    # Instantiate our AJS actor
    # @private
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

      @_AJSActor = new AJSPolygon
        physics: physicsEnabled
        mass: mass
        friction: friction
        elasticity: elasticity
        radius: @_properties.radius.getValue()
        segments: @_properties.sides.getValue()
        position: new AJSVector2 x, y
        color: new AJSColor3 r, g, b
        rotation: @_properties.rotation.getValue()

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

      actor = new PolygonActor ui, birth, sides, radius, x, y, rotation, death
      actor.load data
      actor
