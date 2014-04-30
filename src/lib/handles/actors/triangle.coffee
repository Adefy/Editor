define (require) ->

  config = require "config"
  param = require "util/param"

  Actors = require "handles/actors"
  BaseActor = require "handles/actors/base"

  NumericProperty = require "handles/properties/numeric"

  # Trianglular actor
  Actors.TriangleActor = class TriangleActor extends BaseActor

    ###
    # Creates an ARETriangle and keeps track of it
    #
    # @param [UIManager] ui
    # @param [Object] options
    #   @option [Number] lifetimeStart  time in ms at which we are to be created
    #   @option [Number] lifetimeEnd  death time specification
    #     @optional
    #   @option [Number] base  triangle width
    #   @option [Number] height  triangle height
    #   @option [Vec2] position  starting coordinates
    #   @option [Number] rotation  angle in degrees
    #     @optional
    #   @option [Boolean] manualInit  postInit() not called if true
    #     @optional
    ###
    constructor: (@ui, options) ->
      param.required @ui
      param.required options

      b = param.required options.base
      h = param.required options.height

      manualInit = param.optional manualInit, false

      if b <= 0 or h <= 0 then throw new Error "Base/Height must be >0!"

      super @ui, options

      @handleType = "TriangleActor"

      @name = "Triangle #{@_id_numeric}"

      @initPropertyBase()
      @initPropertyHeight()

      @_properties.base.setValue b
      @_properties.height.setValue h

      @postInit() unless manualInit

    ###
    # Initialize Actor base property
    ###
    initPropertyBase: ->
      me = @
      @_properties.base = new NumericProperty()
      @_properties.base.setMin 0
      @_properties.base.setPlaceholder 100
      @_properties.base.setValue 1
      @_properties.base.setPrecision config.precision.base
      @_properties.base.requestUpdate = ->
        @setValue me._areActor.getBase() if me._areActor

      @_properties.base.onUpdate = (base) =>
        @_areActor.setBase base if @_areActor

      @_properties.base.genAnimationOpts = (animation, options) ->
        options.startVal = animation._start.y
        options

    ###
    # Initialize Actor height property
    ###
    initPropertyHeight: ->
      me = @
      @_properties.height = new NumericProperty()
      @_properties.height.setMin 0
      @_properties.height.setPlaceholder 100
      @_properties.height.setValue 1
      @_properties.height.setPrecision config.precision.height
      @_properties.height.requestUpdate = ->
        @setValue me._areActor.getHeight() if me._areActor

      @_properties.height.onUpdate = (height) =>
        @_areActor.setHeight height if @_areActor

      @_properties.height.genAnimationOpts = (animation, options) ->
        options.startVal = animation._start.y
        options

    ###
    # Get triangle base value
    #
    # @return [Number] base
    ###
    getBase: -> @_properties.base.getValue()

    ###
    # Get triangle height value
    #
    # @return [Number] height
    ###
    getHeight: -> @_properties.height.getValue()

    ###
    # Instantiate our ARE actor
    # @private
    ###
    _birth: ->
      if @_alive then return else @_alive = true

      physicsEnabled = @_properties.physics.getProperty("enabled").getValue()
      mass = @_properties.physics.getProperty("mass").getValue()
      friction = @_properties.physics.getProperty("friction").getValue()
      elasticity = @_properties.physics.getProperty("elasticity").getValue()

      x = @_properties.position.getProperty("x").getValue()
      y = @_properties.position.getProperty("y").getValue()

      r = @_properties.color.getProperty("r").getValue()
      g = @_properties.color.getProperty("g").getValue()
      b = @_properties.color.getProperty("b").getValue()

      ## Right, ARE doesn't have a triangle actor...
      #@_areActor = new ARETriangleActor
      @_areActor = new AREPolygonActor
        physics: physicsEnabled
        mass: mass
        friction: friction
        elasticity: elasticity
        base: @_properties.base.getValue()
        height: @_properties.height.getValue()
        position: new AREVector2 x, y
        color: new AREColor3 r, g, b
        rotation: @_properties.rotation.getValue()

      super()

    ###
    # Initializes a new TriangleActor using serialized data
    #
    # @param [UIManager] ui
    # @param [Object] data
    ###
    @load: (ui, data) ->

      birth = data.birth
      death = data.death

      position = data.properties.position

      b = data.properties.base.value
      h = data.properties.height.value
      x = position.x.value
      y = position.y.value
      rotation = data.properties.rotation.value

      actor = new TriangleActor ui,
        lifetimeStart: birth
        lifetimeEnd: death
        base: b
        height: h
        position: x: x, y: y
        rotation: rotation

      actor.load data
      actor
