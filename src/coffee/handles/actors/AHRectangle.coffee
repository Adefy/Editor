# Rectangular actor
class AHRectangle extends AHBaseActor

  # Instantiates an AJSRectangle and keeps track of it
  #
  # @param [Number] birth time in ms at which we are to be created
  # @param [Number] w actor width
  # @param [Number] h actor height
  # @param [Number] x x starting coordinate
  # @param [Number] y y starting coordinate
  constructor: (birth, w, h, x, y) ->
    param.required w
    param.required h
    param.required x
    param.required y

    if w <= 0 or h <= 0 then throw new Error "Width/Height must be >0!"

    # Set up generic actor properties
    super birth

    @name = "Rectangle #{@_id.replace("ahandle-", "")}"

    @_actor = new AJSRectangle
      psyx: false
      mass: 0
      friction: 0.3
      elasticity: 0.4
      w: w
      h: h
      position: new AJSVector2 x, y
      color: new AJSColor3 255, 255, 255

    me = @

    # Add our width and height as editable properties
    @_properties["width"] =
      type: "number"
      min: 0
      placeholder: 100
      float: true
      getValue: -> @_value = me._actor.getWidth()

      # Update width, rebuild
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setWidth Number(v)

    @_properties["height"] =
      type: "number"
      min: 0
      placeholder: 100
      float: true
      getValue: -> @_value = me._actor.getHeight()

      # Update height, rebuild
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setHeight Number(v)