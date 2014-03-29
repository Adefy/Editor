define (require) ->

  AUtilLog = require "util/log"
  ID = require "util/id"
  aformat = require "util/format"
  Tab = require "widgets/tabs/tab"
  ObjectPropertiesTemplate = require "templates/object_properties"

  class TabProperties extends Tab

    constructor: (parent) ->
      super
        id: ID.prefId("tab-properties")
        parent: parent
        classes: ["tab-properties"]

      @_actor = null

    ###
    # @param [BaseActor] actor
    ###
    setActor: (@_actor) ->

    ###
    # Creates a default properties object and returns it
    # @return [Object] properties a stubbed properties object
    # @private
    ###
    _genProperties: ->
      {
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
        physics:
          mass: aformat.num()
          elasticity: aformat.num(null, 2)
          friction: aformat.num(null, 2)
      }

    ###
    # @return [String]
    ###
    render: ->
      ObjectPropertiesTemplate @_genProperties()

    ###
    #
    ###
    update: ->
      properties = @_genProperties()

      if @_actor
        properties.basic.width = aformat.px @_actor.getWidth()
        properties.basic.height = aformat.px @_actor.getHeight()
        properties.basic.opacity = aformat.num @_actor.getOpacity(), 2
        properties.basic.rotation = aformat.degree @_actor.getRotation(), 2

        pos = @_actor.getPosition()
        properties.position.x = aformat.num pos.x
        properties.position.y = aformat.num pos.y

        color = @_actor.getColor(true)
        properties.color.r = aformat.num color.r, 2
        properties.color.g = aformat.num color.g, 2
        properties.color.b = aformat.num color.b, 2

        physics = @_actor.getPsyX()
        if physics.enabled
          properties.physics.mass = aformat.num physics.mass
          properties.physics.elasticity = aformat.num physics.elasticity, 2
          properties.physics.friction = aformat.num physics.friction, 2

      @getElement("#basic #width").text properties.basic.width
      @getElement("#basic #height").text properties.basic.height
      @getElement("#basic #opacity").text properties.basic.opacity
      @getElement("#basic #rotation").text properties.basic.rotation

      @getElement("#position #x").text properties.position.x
      @getElement("#position #y").text properties.position.y

      @getElement("#color #r").text properties.color.r
      @getElement("#color #g").text properties.color.g
      @getElement("#color #b").text properties.color.b

      @getElement("#physics #mass").text properties.physics.mass
      @getElement("#physics #elasticity").text properties.physics.elasticity
      @getElement("#physics #friction").text properties.physics.friction

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      if type == "selected.actor"
        @setActor params.actor
        @update()
