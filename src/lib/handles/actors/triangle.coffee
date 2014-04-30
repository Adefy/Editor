define (require) ->

  config = require "config"
  param = require "util/param"

  BaseActor = require "handles/actors/base"

  NumericProperty = require "handles/properties/numeric"

  # Trianglular actor
  window.TriangleActor = class TriangleActor extends BaseActor

    ###
    # Creates an AJSTriangle and keeps track of it
    #
    # @param [UIManager] ui
    # @param [Number] birth time in ms at which we are to be created
    # @param [Number] b base width
    # @param [Number] h triangle height
    # @param [Number] x x starting coordinate
    # @param [Number] y y starting coordinate
    # @param [Number] rotation optional, angle in degrees
    # @param [Number] death optional death time specification
    # @param [Boolean] manualInit optional, postInit() not called if true
    ###
    constructor: (@ui, birth, b, h, x, y, rotation, death, manualInit) ->
      param.required @ui
      param.required b
      param.required h
      param.required x
      param.required y
      manualInit = param.optional manualInit, false
      rotation = param.optional rotation, 0

      if b <= 0 or h <= 0 then throw new Error "Base/Height must be >0!"

      super @ui, birth, death

      @handleType = "TriangleActor"

      @name = "Triangle #{@_id_numeric}"

      @initPropertyBase()
      @initPropertyHeight()

      @_properties.position.setValue x: x, y: y
      @_properties.base.setValue b
      @_properties.height.setValue h
      @_properties.rotation.setValue rotation

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
        @setValue me._AJSActor.getBase() if me._AJSActor

      @_properties.base.onUpdate = (base) =>
        @_AJSActor.setBase base if @_AJSActor

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
        @setValue me._AJSActor.getHeight() if me._AJSActor

      @_properties.height.onUpdate = (height) =>
        @_AJSActor.setHeight height if @_AJSActor

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
    # Instantiate our AJS actor
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

      @_AJSActor = new AJSTriangle
        physics: physicsEnabled
        mass: mass
        friction: friction
        elasticity: elasticity
        base: @_properties.base.getValue()
        height: @_properties.height.getValue()
        position: new AJSVector2 x, y
        color: new AJSColor3 r, g, b
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

      actor = new TriangleActor ui, birth, b, h, x, y, rotation, death
      actor.load data
      actor
