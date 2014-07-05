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
    # @param [Boolean] manualInit optional, @_postInit() not called if true
    ###
    constructor: (@ui, birth, sides, radius, x, y, rotation, death, manualInit) ->
      radius = Math.abs radius

      throw new Error "Can't create an ngon with less than 3 sides" if sides < 3

      super @ui, birth, death

      @_handleType = "PolygonActor"
      @setName "Polygon #{@_id_numeric}"
      @initPropertySides()
      @initPropertyRadius()

      @_properties.position.setValue x: x, y: y
      @_properties.sides.setValue sides
      @_properties.radius.setValue radius
      @_properties.rotation.setValue rotation or 0

      @_postInit() unless !!manualInit

    ###
    # Initialize Actor sides property
    ###
    initPropertySides: ->
      @_properties.sides = new NumericProperty()
      @_properties.sides.setVisibleInSidebar true
      @_properties.sides.setMin 3
      @_properties.sides.setPlaceholder 5
      @_properties.sides.setFloat false
      @_properties.sides.setValue 3
      @_properties.sides.setPrecision config.precision.sides
      @_properties.sides.onUpdate = (sides) =>
        @_AREActor.setSegments sides if @_AREActor

      @_properties.sides.genAnimationOpts = (animation, options) ->
        options.startVal = animation._start.y
        options

    ###
    # Initialize Actor radius property
    ###
    initPropertyRadius: ->
      @_properties.radius = new NumericProperty()
      @_properties.radius.setVisibleInSidebar true
      @_properties.radius.setMin 0
      @_properties.radius.setPlaceholder 50
      @_properties.radius.setValue 10
      @_properties.radius.setPrecision config.precision.radius
      @_properties.radius.onUpdate = (radius) =>
        @_AREActor.setRadius radius if @_AREActor

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
    birth: ->
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

      renderer = @ui.workspace.getARE().getRenderer()
      radius = @_properties.radius.getValue()
      segments = @_properties.sides.getValue()

      @_AREActor = new AREPolygonActor renderer, radius, segments
      @_AREActor.setPosition x: x, y: y
      @_AREActor.setColor r, g, b
      @_AREActor.setRotation @_properties.rotation.getValue()
      @_AREActor.setMass mass
      @_AREActor.setFriction friction
      @_AREActor.setElasticity elasticity
      @_AREActor.createPhysicsBody() if physicsEnabled

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

      actor = new PolygonActor ui, birth, sides, radius, x, y, rotation, death
      actor.load data
      actor
