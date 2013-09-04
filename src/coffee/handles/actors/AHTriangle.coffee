# Trianglular actor
class AHTriangle extends AHBaseActor

  # Creates an AJSTriangle and keeps track of it
  #
  # @param [Number] b base width
  # @param [Number] h triangle height
  # @param [Number] x x starting coordinate
  # @param [Number] y y starting coordinate
  constructor: (b, h, x, y) ->
    param.required b
    param.required h
    param.required x
    param.required y

    if b <= 0 or h <= 0 then throw new Error "Base/Height must be >0!"

    # Set up generic actor properties
    super()

    @_actor = new AJSTriangle
      psyx: false
      mass: 0
      friction: 0.3
      elasticity: 0.4
      base: b
      height: h
      position: new AJSVector2 x, y
      color: new AJSColor3 255, 255, 255