# Base manipulateable class for actors
class AHBaseActor extends AHandle

  # Defines a raw actor, with no shape information or any other presets.
  # This serves as the base for the other actor classes
  constructor: ->

    # Set up properties object (global defaults set)
    super()

    # Note that we don't create an actual actor!
    @_actor = null

    me = @

    # Properties are interesting, and complex enough to warrant a description
    #
    # TODO: Decribe

    # Default actor properties, common to all actors
    @_properties["position"] =
      type: "composite"
      preview: true
      components:
        x:
          type: "number"
          float: true
          placeholder: 0
          getValue: -> @_value
        y:
          type: "number"
          float: true
          placeholder: 0
          getValue: -> @_value

      # Fetch actor position
      getValue: ->

        if me._actor != null
          pos = me._actor.getPosition()

          @components.x._value = pos.x
          @components.y._value = pos.y

      # Position update, we expect val to be a composite
      update: (v) ->
        param.required v
        param.required v.x
        param.required v.y

        @components.x._value = v.x
        @components.y._value = v.y

        if me._actor != null
          me._actor.setPosition new AJSVector2(v.x, v.y)

    @_properties["rotation"] =
      type: "number"
      preview: true
      min: 0
      max: 360
      float: true
      placeholder: 0

      # Fetch our angle from our actor
      getValue: -> @_value = me._actor.getRotation()

      # Val simply contains our new angle in degrees
      update: (v) ->
        @_value = param.required v

        if me._actor != null then me._actor.setRotation v

    @_properties["color"] =
      type: "composite"
      preview: true
      components:
        r:
          type: "number"
          min: 0
          max: 255
          float: false
          placeholder: 255
          getValue: -> @_value
        g:
          type: "number"
          min: 0
          max: 255
          float: false
          placeholder: 255
          getValue: -> @_value
        b:
          type: "number"
          min: 0
          max: 255
          float: false
          placeholder: 255
          getValue: -> @_value

      # We fetch color information from our actor, and set composite
      # values accordingly
      getValue: ->

        if me._actor != null
          col = me._actor.getColor()

          @components.r._value = col.getR()
          @components.g._value = col.getG()
          @components.b._value = col.getB()

        null

      # Color update, expect val to be composite
      update: (v) ->
        param.required v

        @components.r._value = param.required v.r
        @components.g._value = param.required v.g
        @components.b._value = param.required v.b

        if me._actor != null
          me._actor.setColor new AJSColor3 v.r, v.g, v.b

    @_properties["psyx"] =
      type: "composite"
      preview: false

      # We cache component values locally, and just pass those through
      components:
        mass:
          type: "number"
          min: 0
          float: true
          placeholder: 50
          _value: 50
          getValue: -> @_value
        elasticity:
          type: "number"
          min: 0
          max: 1
          float: true
          placeholder: 0.3
          _value: 0.3
          getValue: -> @_value
        friction:
          type: "number"
          min: 0
          max: 1
          float: true
          placeholder: 0.2
          _value: 0.2
          getValue: -> @_value
        enabled:
          type: "bool"
          _value: false
          getValue: -> @_value

      # Physics values are stored locally, and only changed when we change them
      # As such, we cache everything internally and just pass that to our
      # properties panel. Because of this, our outer composite getValue()
      # does nothing
      getValue: -> # dud

      # Physics update! Composite and fanciness, preview is disabled so all
      # values are updated at once (yay!)
      update: (v) ->
        param.required v

        # Save values internally
        @components.mass._value = param.required v.mass
        @components.elasticity._value = param.required v.elasticity
        @components.friction._value = param.required v.friction
        @components.enabled._value = param.required v.enabled

        if me._actor != null

          # Note that we re-create the physics body every time!
          # TODO: Optimize this
          me._actor.disablePsyx()

          if v.enabled
            me._actor.enablePsyx v.mass, v.friction, v.elasticity

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
