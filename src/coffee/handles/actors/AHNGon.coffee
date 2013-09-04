# N-sided actor
class AHNGon extends AHBaseActor

  # Defines a variable-sided actor, psicktually
  #
  # @param [Number] sides the n in ngon
  # @param [Number] radius ngon radius
  # @param [Number] x x starting coordinate
  # @param [Number] y y starting coordinate
  constructor: (sides, radius, x, y) ->
    param.required sides
    param.required radius
    param.required x
    param.required y

    if sides < 3
      throw new Error "Can't create an ngon with less than 3 sides"

    # Negate negative radius
    if radius < 0 then radius *= -1

    # Take advantage of generic actor properties
    super()

    # Add our side count, at the very least we are a triangle, no shame in that
    @_properties["sides"] =
      type: "number"
      min: 3
      default: sides
      float: false

    @_properties["radius"] =
      type: "number"
      min: 0
      default: radius
      float: true

    @_actor = new AJSNGon
      psyx: false
      mass: 0
      friction: 0.3
      elasticity: 0.4
      radius: radius
      segments: sides
      position: new AJSVector2 x, y
      color: new AJSColor3 255, 255, 255
