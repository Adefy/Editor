# N-sided actor
class AHPolygon extends AHBaseActor

  # Defines a variable-sided actor, psicktually
  #
  # @param [Number] birth time in ms at which we are to be created
  # @param [Number] sides the n in ngon
  # @param [Number] radius ngon radius
  # @param [Number] x x starting coordinate
  # @param [Number] y y starting coordinate
  constructor: (birth, sides, radius, x, y) ->
    param.required sides
    param.required radius
    param.required x
    param.required y

    if sides < 3
      throw new Error "Can't create an ngon with less than 3 sides"

    # Negate negative radius
    if radius < 0 then radius *= -1

    # Take advantage of generic actor properties
    super birth

    @name = "Polygon #{@_id.replace("ahandle-", "")}"

    @_actor = new AJSPolygon
      psyx: false
      mass: 0
      friction: 0.3
      elasticity: 0.4
      radius: radius
      segments: sides
      position: new AJSVector2 x, y
      color: new AJSColor3 255, 255, 255

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

        if me._actor != null then me._actor.setSegments Number(v)

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

        if me._actor != null then me._actor.setRadius Number(v)

    # Finish our initialization
    @postInit()