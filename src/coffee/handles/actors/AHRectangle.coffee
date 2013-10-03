##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Rectangular actor
class AHRectangle extends AHBaseActor

  # Instantiates an AJSRectangle and keeps track of it
  #
  # @param [Number] birth time in ms at which we are to be created
  # @param [Number] w actor width
  # @param [Number] h actor height
  # @param [Number] x x starting coordinate
  # @param [Number] y y starting coordinate
  # @param [Number] rotation optional, angle in degrees
  # @param [Number] death optional death time specification
  # @param [Boolean] manualInit optional, postInit() not called if true
  constructor: (birth, w, h, x, y, rotation, death, manualInit) ->
    param.required w
    param.required h
    param.required x
    param.required y
    manualInit = param.optional manualInit, false
    rotation = param.optional rotation, 0

    if w <= 0 or h <= 0 then throw new Error "Width/Height must be >0!"

    # Set up generic actor properties
    super birth, death

    @name = "Rectangle #{@_id.replace("ahandle-", "")}"

    @_properties["position"].components["x"]._value = x
    @_properties["position"].components["y"]._value = y
    @_properties["rotation"].update rotation

    me = @

    # Add our width and height as editable properties
    @_properties["width"] =
      type: "number"
      min: 0
      placeholder: 100
      float: true
      live: true
      _value: w
      getValue: -> @_value = me._actor.getWidth()

      # Update width, rebuild
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setWidth Number(v)

      genAnimationOpts: (anim, opts) ->
        opts.startVal = anim._start.y
        opts

    @_properties["height"] =
      type: "number"
      min: 0
      placeholder: 100
      float: true
      live: true
      _value: h
      getValue: -> @_value = me._actor.getHeight()

      # Update height, rebuild
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setHeight Number(v)

      genAnimationOpts: (anim, opts) ->
        opts.startVal = anim._start.y
        opts

    # Finish our initialization
    if not manualInit then @postInit()

  # Get rectangle height value
  #
  # @return [Number] height
  getHeight: -> @_properties["height"]._value

  # Get rectangle width value
  #
  # @return [Number] width
  getWidth: -> @_properties["width"]._value

  # Instantiate our AJS actor
  # @private
  _birth: ->
    if @_alive then return else @_alive = true

    _psyx = @_properties["psyx"].components["enabled"]._value
    _mass = @_properties["psyx"].components["mass"]._value
    _friction = @_properties["psyx"].components["friction"]._value
    _elasticity = @_properties["psyx"].components["elasticity"]._value
    _w = @_properties["width"]._value
    _h = @_properties["height"]._value
    _x = @_properties["position"].components["x"]._value
    _y = @_properties["position"].components["y"]._value
    _rotation = @_properties["rotation"]._value
    _r = @_properties["color"].components["r"]._value
    _g = @_properties["color"].components["g"]._value
    _b = @_properties["color"].components["b"]._value

    @_actor = new AJSRectangle
      psyx: _psyx
      mass: _mass
      friction: _friction
      elasticity: _elasticity
      w: _w
      h: _h
      position: new AJSVector2 _x, _y
      color: new AJSColor3 _r, _g, _b
      rotation: _rotation