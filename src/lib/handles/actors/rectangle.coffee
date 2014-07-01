define (require) ->

  config = require "config"
  param = require "util/param"

  BaseActor = require "handles/actors/base"

  NumericProperty = require "handles/properties/numeric"

  # Rectangular actor
  window.RectangleActor = class RectangleActor extends BaseActor

    ###
    # Instantiates an ARERectangleActor and keeps track of it
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
    constructor: (@ui, birth, w, h, x, y, rotation, death, manualInit) ->
      param.required @ui
      param.required w
      param.required h
      param.required x
      param.required y

      if w <= 0 or h <= 0 then throw new Error "Width/Height must be >0!"

      super @ui, birth, death

      @handleType = "RectangleActor"
      @setName "Rectangle #{@_id_numeric}"
      @initPropertyWidth()
      @initPropertyHeight()

      @_properties.position.setValue x: x, y: y
      @_properties.width.setValue w
      @_properties.height.setValue h
      @_properties.rotation.setValue rotation or 0

      @postInit() unless !!manualInit

    ###
    # Initialize Actor width property
    ###
    initPropertyWidth: ->
      me = @
      @_properties.width = new NumericProperty()
      @_properties.width.setVisibleInSidebar true
      @_properties.width.setMin 0
      @_properties.width.setPlaceholder 100
      @_properties.width.setValue 1
      @_properties.width.setPrecision config.precision.width
      @_properties.width.requestUpdate = ->
        @setValue me._AREActor.getWidth() if me._AREActor

      @_properties.width.onUpdate = (width) =>
        @_AREActor.setWidth width if @_AREActor

      @_properties.width.genAnimationOpts = (animation, options) ->
        options.startVal = animation._start.y
        options

    ###
    # Initialize Actor height property
    ###
    initPropertyHeight: ->
      me = @
      @_properties.height = new NumericProperty()
      @_properties.height.setVisibleInSidebar true
      @_properties.height.setMin 0
      @_properties.height.setPlaceholder 100
      @_properties.height.setValue 1
      @_properties.height.setPrecision config.precision.height
      @_properties.height.requestUpdate = ->
        @setValue me._AREActor.getHeight() if me._AREActor

      @_properties.height.onUpdate = (height) =>
        @_AREActor.setHeight height if @_AREActor

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

      renderer = @ui.workspace.getARE().getRenderer()
      width = @_properties.width.getValue()
      height = @_properties.height.getValue()

      @_AREActor = new ARERectangleActor renderer, width, height
      @_AREActor.setPosition x: x, y: y
      @_AREActor.setColor r, g, b
      @_AREActor.setRotation @_properties.rotation.getValue()
      @_AREActor.setMass mass
      @_AREActor.setFriction friction
      @_AREActor.setElasticity elasticity
      @_AREActor.createPhysicsBody() if physicsEnabled

      super()

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

      actor = new RectangleActor ui, birth, w, h, x, y, rotation, death
      actor.load data
      actor
