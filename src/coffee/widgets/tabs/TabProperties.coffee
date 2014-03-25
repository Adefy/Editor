##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# @depend Tab.coffee
class AWidgetTabProperties extends AWidgetTab

  constructor: (parent) ->
    super prefId("tab-properties"), parent, ["tab-properties"]

    @_actor = null

  ###
  # @param [AHBaseActor] actor
  ###
  setActor: (actor) ->
    @_actor = actor

  ###
  # Creates a default properties object and returns it
  # @return [Object] properties a stubbed properties object
  # @private
  ###
  _genProperties: ->
    return
      basic:
        width: aformat.px()
        height: aformat.px()
        opacity: aformat.num(null, 2)
        rotation: aformat.degree(null, 2)
      position:
        x: aformat.num(null)
        y: aformat.num(null)
      color:
        r: aformat.num(null, 2)
        g: aformat.num(null, 2)
        b: aformat.num(null, 2)
      psyx:
        mass: aformat.num()
        elasticity: aformat.num(null, 2)
        friction: aformat.num(null, 2)

  ###
  # @return [String]
  ###
  render: ->
    properties = @_genProperties()

    ATemplate.objectProperties(properties)

  ###
  #
  ###
  update: ->
    properties = @_genProperties()

    if @_actor
      properties.basic.width = aformat.px @_actor.width
      properties.basic.height = aformat.px @_actor.height
      properties.basic.opacity = aformat.num @_actor.opacity, 2
      properties.basic.rotation = aformat.degree @_actor.rotation, 2

      properties.position.x = aformat.num @_actor.x
      properties.position.y = aformat.num @_actor.y

      properties.color.r = aformat.num @_actor.color.r, 2
      properties.color.g = aformat.num @_actor.color.g, 2
      properties.color.b = aformat.num @_actor.color.b, 2

      properties.psyx.mass = aformat.num @_actor.mass
      properties.psyx.elasticity = aformat.num @_actor.elasticity, 2
      properties.psyx.friction = aformat.num @_actor.friction, 2

    @getElement("#basic #width").text properties.basic.width
    @getElement("#basic #height").text properties.basic.height
    @getElement("#basic #opacity").text properties.basic.opacity
    @getElement("#basic #rotation").text properties.basic.rotation

    @getElement("#position #x").text properties.position.x
    @getElement("#position #y").text properties.position.y

    @getElement("#color #r").text properties.color.r
    @getElement("#color #g").text properties.color.g
    @getElement("#color #b").text properties.color.b

    @getElement("#psyx #mass").text properties.psyx.mass
    @getElement("#psyx #elasticity").text properties.psyx.elasticity
    @getElement("#psyx #friction").text properties.psyx.friction