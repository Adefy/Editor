# Rectangular actor
class AHRectangle extends AHBaseActor

  # Instantiates an AJSRectangle and keeps track of it
  #
  # @param [Number] w actor width
  # @param [Number] h actor height
  # @param [Number] x x starting coordinate
  # @param [Number] y y starting coordinate
  constructor: (w, h, x, y) ->
    param.required w
    param.required h
    param.required x
    param.required y

    if w <= 0 or h <= 0 then throw new Error "Width/Height must be >0!"

    # Set up generic actor properties
    super()

    @_actor = new AJSRectangle
      psyx: false
      mass: 0
      friction: 0.3
      elasticity: 0.4
      w: w
      h: h
      position: new AJSVector2 x, y
      color: new AJSColor3 255, 255, 255