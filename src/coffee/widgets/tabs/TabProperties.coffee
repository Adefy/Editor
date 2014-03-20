# @depend Tab.coffee
class AWidgetTabProperties extends AWidgetTab

  constructor: (parent) ->
    @_actor = null
    super parent

  setActor: (actor) ->
    @_actor = actor

  render: ->
    properties =
      basic:
        width: "--px"
        height: "--px"
        opacity: "-.-"
        rotation: "-.-°"
      position:
        x: "-.-"
        y: "-.-"
      color:
        r: "-.-"
        g: "-.-"
        b: "-.-"
      physics:
        mass: "--"
        elasticity: "-.-"
        friction: "-.-"

    if @_actor
      properties.basic.width = "#{@_actor.width}px"
      properties.basic.height = "#{@_actor.height}px"
      properties.basic.opacity = "#{@_actor.opacity}"
      properties.basic.rotation = "#{@_actor.rotation}°"

      properties.position.x = "#{@_actor.x}"
      properties.position.y = "#{@_actor.y}"

      properties.color.r = "#{@_actor.color.r}"
      properties.color.g = "#{@_actor.color.g}"
      properties.color.b = "#{@_actor.color.b}"

      properties.physics.mass = "#{@_actor.mass}"
      properties.physics.elasticity = "#{@_actor.elasticity}"
      properties.physics.friction = "#{@_actor.friction}"

    ATemplate.objectProperties(properties)