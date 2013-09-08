# Base manipulateable class for actors
class AHBaseActor extends AHandle

  # Defines a raw actor, with no shape information or any other presets.
  # This serves as the base for the other actor classes
  #
  # @param [Number] lifetimeStart time at which we are created, in ms
  # @param [Number] lifetimeEnd time we are destroyed, defaults to end of ad
  constructor: (lifetimestart, lifetimeEnd) ->

    # Set up properties object (global defaults set)
    super()

    # Note that we don't create an actual actor!
    @_actor = null

    # Our name as it appears in the timeline actor list and properties panel
    @name = "Base Actor #{@_id.replace("ahandle", "")}"

    # Lifetime properties, defines how we appear in the timeline and how we are
    # handled by the engine according to the current cursor position
    #
    # These are ms values, with -1 symbolizing the end of the scene
    @lifetimeStart = param.required lifetimestart
    @lifetimeEnd = param.optional lifetimeEnd, -1

    # If passed -1 as our death, get the current timeline duration and use it
    @lifetimeEnd = AWidgetTimeline.getMe().getDuration()

    me = @
    # Properties are interesting, and complex enough to warrant a description
    #
    # Currently, there are 3 basic types avaliable.
    #
    #   'number' - appears as a numeric input field
    #     'max'         - the number can have an optional enforced maximum
    #     'min'         - the number can have an optional enformed minimum
    #     'float'       - if false, input is enforced as integer-only
    #     'placeholder' - optional placeholder to display on the input
    #
    #   'text' - appears as a standard text input field
    #   'bool' - appears as a checkbox
    #
    # There is a 4th complex type named 'composite', which has a property
    # named 'components', full of other basic types. Composite nesting has
    # not been tested as of 9/5/2013, but in theory should be possible.
    #
    # Each type needs to have a getValue() method, and an update() method.
    # Components of composites shouldn't provide an update() method, as the
    # parent composite takes care of updating all components.
    #
    # All top-level properties should fetch up-to-date information in their
    # getValue() methods, and save it locally as _value. Composites doing this
    # must perform the saving for their children.
    #
    # TODO: Decribe

    # Default actor properties, common to all actors
    @_properties["position"] =
      type: "composite"
      live: true
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
      live: true
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
      live: true
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
      live: false

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

      # Physics update! Composite and fanciness, live is disabled so all
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

  # Deletes us, muahahahaha. We notify the workspace, clear the properties
  # panel if it is targetting us, and destroy our actor.
  delete: ->

    if @_actor != null

      # Notify the workspace
      AWidgetWorkspace.getMe().notifyDemise @

      # Clear the properties panel if it is tied to us
      _prop = $("body").data "default-properties"
      if _prop instanceof AWidgetSidebarProperties
        if _prop.privvyIface("get_id") == @_actor.getId()
          _prop.clear()

      # Go through and remove ourselves from
      @_actor.destroy()
      @_actor = null

    super()

  # Get internal actors' id. Note that the actor must exist for this!
  #
  # @return [Number] id
  getActorId: ->
    if @_actor != null then return @_actor.getId()
    AUtilLog.warn "No actor, can't get id!"

  # Return actor position as (x,y) relative to the GL world
  #
  # @return [Object]
  getPosition: ->

    if @_actor != null
      _pos = @_actor.getPosition()
      return { x: _pos.x, y: _pos.y }

    AUtilLog.warn "No actor, can't get position!"

  # Set actor position, relative to the GL world!
  #
  # @param [Number] x x coordinate
  # @param [Number] y y coordinate
  setPosition: (x, y) ->
    if @_actor != null
      @_actor.setPosition new AJSVector2(x, y)
    else
      AUtilLog.warn "No actor, can't set position!"

  # Get our internal actor
  #
  # @param [AJSBaseActor] actor
  getActor: -> @_actor