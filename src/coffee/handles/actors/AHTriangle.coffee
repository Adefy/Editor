# Trianglular actor
class AHTriangle extends AHBaseActor

  # Creates an AJSTriangle and keeps track of it
  #
  # @param [Number] birth time in ms at which we are to be created
  # @param [Number] b base width
  # @param [Number] h triangle height
  # @param [Number] x x starting coordinate
  # @param [Number] y y starting coordinate
  constructor: (birth, b, h, x, y) ->
    param.required b
    param.required h
    param.required x
    param.required y

    if b <= 0 or h <= 0 then throw new Error "Base/Height must be >0!"

    # Set up generic actor properties
    super birth

    @name = "Triangle #{@_id.replace("ahandle-", "")}"

    @_properties["position"].components["x"]._value = x
    @_properties["position"].components["y"]._value = y

    me = @

    # Add our base and height as editable properties
    @_properties["base"] =
      type: "number"
      min: 0
      placeholder: 30
      live: true
      float: true
      _value: b
      getValue: -> @_value = me._actor.getBase()

      # Update base, rebuild
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setBase Number(v)

    @_properties["height"] =
      type: "number"
      min: 0
      placeholder: 60
      live: true
      float: true
      _value: h
      getValue: -> @_value = me._actor.getHeight()

      # Update height, rebuild
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setHeight Number(v)

    # Finish our initialization
    @postInit()

  # Instantiate our AJS actor
  # @private
  _birth: ->
    if @_alive then return else @_alive = true

    _psyx = @_properties["psyx"].components["enabled"]._value
    _mass = @_properties["psyx"].components["mass"]._value
    _friction = @_properties["psyx"].components["friction"]._value
    _elasticity = @_properties["psyx"].components["elasticity"]._value
    _base = @_properties["base"]._value
    _height = @_properties["height"]._value
    _x = @_properties["position"].components["x"]._value
    _y = @_properties["position"].components["y"]._value
    _r = @_properties["color"].components["r"]._value
    _g = @_properties["color"].components["g"]._value
    _b = @_properties["color"].components["b"]._value

    @_actor = new AJSTriangle
      psyx: _psyx
      mass: _mass
      friction: _friction
      elasticity: _elasticity
      base: _base
      height: _height
      position: new AJSVector2 _x, _y
      color: new AJSColor3 _r, _g, _b