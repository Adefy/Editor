# N-sided actor
class AMNGon extends AMBaseActor

  # Defines a variable-sided actor, psicktually
  constructor: ->

    # Take advantage of generic actor properties
    super()

    # Add our side count, at the very least we are a triangle, no shame in that
    @_properties["sides"] =
      type: "number"
      min: 3
      default: 5
      float: false

  # Override the render function to draw an appropriate ngon
  # Note that 'inner' should normally never be set, we just accept it since we
  # have to, in order to maintain the proper definition. If, for some reason,
  # in the future, if the US hasn't gone to war with Syria and such, we decide
  # to pass inner content to this render function. Then shame on us. Shame.
  #
  # @param [String] inner shameful html to wrap
  # @param [Number] x x coordinate of resulting object
  # @param [Number] y y coordinate of resulting object
  # @return [String] html visible representation
  renderWorkpace: (inner, x, y) ->
    param.required x
    param.required y

    _html = ""

    # This is where an epiphany occured. I didn't realize you can't render
    # arbitrary shapes in HTML (crazy).
    #
    # The first idea I had was to go with SVG, but then we can't texture
    # things, and implementing support for 3D will mean essentially building
    # a new editor.
    #
    # AWGL it is. Tomorrow. Too tired now.

    super _html