# Base manipulateable class for actors
class AHBaseActor extends AHandle

  # Defines a raw actor, with no shape information or any other presets.
  # This serves as the base for the other actor classes
  constructor: ->

    # Set up properties object (global defaults set)
    super()

    # Note that we don't create an actual actor!
    @_actor = null

    # Default actor properties, common to all actors
    @_properties["position"] =
      type: "composite"
      preview: true
      components:
        x:
          type: "number"
          float: true
          default: 0
        y:
          type: "number"
          float: true
          default: 0

      # Position update, we expect val to be a composite
      update: (v) =>
        param.required v
        param.required v.x
        param.required v.y

        if @_actor != null then @_actor.setPosition new AJSVector2(v.x, v.y)

    @_properties["rotation"] =
      type: "number"
      preview: true
      min: 0
      max: 360
      float: true
      default: 0

      # Val simply contains our new angle in degrees
      update: (v) =>
        param.required v

        if @_actor != null then @_actor.setRotation v

    @_properties["color"] =
      type: "composite"
      preview: true
      components:
        r:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 255
        g:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 255
        b:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 255

      # Color update, expect val to be composite
      update: (v) =>
        param.required v
        param.required v.r
        param.required v.g
        param.required v.b

        if @_actor != null then @_actor.setColor new AJSColor3 v.r, v.g, v.b

    @_properties["psyx"] =
      type: "composite"
      preview: false
      components:
        mass:
          type: "number"
          min: 0
          float: true
          default: 50
        elasticity:
          type: "number"
          min: 0
          max: 1
          float: true
          default: 0.3
        friction:
          type: "number"
          min: 0
          max: 1
          float: true
          default: 0.2
        enabled:
          type: "bool"
          default: "false"

      # Physics update! Composite and fanciness, preview is disabled so all
      # values are updated at once (yay!)
      update: (v) =>
        param.required v
        param.required v.mass
        param.required v.elasticity
        param.required v.friction
        param.required v.enabled

        if @_actor != null
          if v.enabled
            @_actor.enablePsyx v.mass, v.friction, v.elasticity
          else
            @_actor.disablePsyx()

  delete: ->

    # For now, this is simple, we just delete the actor. In the future, we will
    # need to remove associated manipulatables, such as timeline elements
    if @_actor != null

      # Notify the workspace
      AWidgetWorkspace.getMe().notifyDemise @

      # Go through and remove ourselves from
      @_actor.destroy()
      @_actor = null

    super()

  # Get internal actors' id. Note that the actor must exist for this!
  #
  # @return [Number] id
  getActorId: -> @_actor.getId()
