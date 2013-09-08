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

    @_actor = new AJSTriangle
      psyx: false
      mass: 0
      friction: 0.3
      elasticity: 0.4
      base: b
      height: h
      position: new AJSVector2 x, y
      color: new AJSColor3 255, 255, 255

    me = @

    # Add our base and height as editable properties
    @_properties["base"] =
      type: "number"
      min: 0
      placeholder: 30
      float: true
      getValue: -> @_value = me._actor.getBase()

      # Update base, rebuild
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setBase Number(v)

    @_properties["height"] =
      type: "number"
      min: 0
      placeholder: 60
      float: true
      getValue: -> @_value = me._actor.getHeight()

      # Update height, rebuild
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setHeight Number(v)