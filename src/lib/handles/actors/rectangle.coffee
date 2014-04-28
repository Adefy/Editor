define (require) ->

  config = require "config"
  param = require "util/param"

  Actors = require "handles/actors"
  BaseActor = require "handles/actors/base"

  NumericProperty = require "handles/properties/numeric"

  # Rectangular actor
  Actors.RectangleActor = class RectangleActor extends BaseActor

    ###
    # Instantiates an AJSRectangle and keeps track of it
    #
    # @param [UIManager] ui
    # @param [Number] birth time in ms at which we are to be created
    # @param [Number] w actor width
    # @param [Number] h actor height
    # @param [Number] x x starting coordinate
    # @param [Number] y y starting coordinate
    # @param [Number] rotation optional, angle in degrees
    # @param [Number] death optional death time specification
    # @param [Boolean] manualInit optional, postInit() not called if true
    ###
    constructor: (@ui, options) ->
      param.required @ui
      param.required options
      w = param.required options.width
      h = param.required options.height

      manualInit = param.optional options.manualInit, false
      rotation = param.optional options.rotation, 0

      if w <= 0 or h <= 0 then throw new Error "Width/Height must be >0!"

      super @ui, options

      @handleType = "RectangleActor"

      @setName "Rectangle #{@_id_numeric}"

      @initPropertyWidth()
      @initPropertyHeight()

      @_properties.width.setValue w
      @_properties.height.setValue h
      @_properties.rotation.setValue rotation

      @postInit() unless manualInit

    ###
    # Initialize Actor width property
    ###
    initPropertyWidth: ->
      me = @
      @_properties.width = new NumericProperty()
      @_properties.width.setMin 0
      @_properties.width.setPlaceholder 100
      @_properties.width.setValue 1
      @_properties.width.setPrecision config.precision.width
      @_properties.width.requestUpdate = ->
        @setValue me._AJSActor.getWidth() if me._AJSActor

      @_properties.width.onUpdate = (width) =>
        @_AJSActor.setWidth width if @_AJSActor

      @_properties.width.genAnimationOpts = (animation, options) ->
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
    # Get rectangle height value
    #
    # @return [Number] height
    ###
    getHeight: -> @_properties.height.getValue()

    ###
    # Get rectangle width value
    #
    # @return [Number] width
    ###
    getWidth: -> @_properties.width.getValue()

    ###
    # Instantiate our AJS actor
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

      @_AJSActor = new AJSRectangle
        physics: physicsEnabled
        mass: mass
        friction: friction
        elasticity: elasticity
        w: @_properties.width.getValue()
        h: @_properties.height.getValue()
        position: new AJSVector2 x, y
        color: new AJSColor3 r, g, b
        rotation: @_properties.rotation.getValue()

    ###
    # Initializes a new RectangleActor using serialized data
    #
    # @param [UIManager] ui
    # @param [Object] data
    ###
    @load: (ui, data) ->

      birth = data.birth
      death = data.death

      position = data.properties.position

      w = data.properties.width.value
      h = data.properties.height.value
      x = position.x.value
      y = position.y.value
      rotation = data.properties.rotation.value

      actor = new RectangleActor ui,
        lifetimeStart: birth
        lifetimeEnd: death
        width: w
        height: h
        position: x: x, y: y
        rotation: rotation

      actor.load data
      actor
