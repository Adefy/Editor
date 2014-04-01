define (require) ->

  param = require "util/param"
  BaseActor = require "handles/actors/base"

  # N-sided actor
  class PolygonActor extends BaseActor

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
    constructor: (@ui, birth, sides, radius, x, y, rotation, death, manualInit) ->
      param.required @ui
      param.required sides
      param.required radius
      param.required x
      param.required y
      manualInit = param.optional manualInit, false
      rotation = param.optional rotation, 0

      if sides < 3
        throw new Error "Can't create an ngon with less than 3 sides"

      # Negate negative radius
      if radius < 0 then radius *= -1

      # Take advantage of generic actor properties
      super @ui, birth, death
      @name = "Polygon"

      @_properties["position"].components["x"]._value = x
      @_properties["position"].components["y"]._value = y
      @_properties["rotation"].update rotation

      me = @

      # Add our side count, at the very least we are a triangle, no shame in that
      #
      # Sides and radius are cached locally
      @_properties["sides"] =
        type: "number"
        min: 3
        placeholder: 5
        float: false
        _value: sides
        live: true
        getValue: -> @_value

        # Side count updated! Rebuild, muahahaha
        update: (v) ->
          @_value = param.required v

          if me._AJSActor != null then me._AJSActor.setSegments Number(v)

        genAnimationOpts: (anim, opts) ->
          opts.startVal = anim._start.y
          opts

      @_properties["radius"] =
        type: "number"
        min: 0
        default: 50
        float: true
        live: true
        _value: radius
        getValue: -> @_value

        # Radius updated, rebuild
        update: (v) ->
          @_value = param.required v

          if me._AJSActor != null then me._AJSActor.setRadius Number(v)

        genAnimationOpts: (anim, opts) ->
          opts.startVal = anim._start.y
          opts

      # Finish our initialization
      if not manualInit then @postInit()

    # Get polygon side count
    #
    # @return [Number] sides
    getSides: -> @_properties["sides"]._value

    # Get rectangle radius value
    #
    # @return [Number] radius
    getRadius: -> @_properties["radius"]._value

    # Instantiate our AJS actor
    # @private
    _birth: ->
      if @_alive then return else @_alive = true

      _physics = @_properties["physics"].components["enabled"]._value
      _mass = @_properties["physics"].components["mass"]._value
      _friction = @_properties["physics"].components["friction"]._value
      _elasticity = @_properties["physics"].components["elasticity"]._value
      _radius = @_properties["radius"]._value
      _segments = @_properties["sides"]._value
      _x = @_properties["position"].components["x"]._value
      _y = @_properties["position"].components["y"]._value
      _rotation = @_properties["rotation"]._value
      _r = @_properties["color"].components["r"]._value
      _g = @_properties["color"].components["g"]._value
      _b = @_properties["color"].components["b"]._value

      @_AJSActor = new AJSPolygon
        physics: _physics
        mass: _mass
        friction: _friction
        elasticity: _elasticity
        radius: _radius
        segments: _segments
        position: new AJSVector2 _x, _y
        color: new AJSColor3 _r, _g, _b
        rotation: _rotation
