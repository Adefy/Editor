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
    @name = "Base Actor #{@_id.replace("ahandle-", "")}"

    # Lifetime properties, defines how we appear in the timeline and how we are
    # handled by the engine according to the current cursor position
    #
    # These are ms values, with -1 symbolizing the end of the scene
    @lifetimeStart = param.required lifetimestart
    @lifetimeEnd = param.optional lifetimeEnd, -1

    # If passed -1 as our death, get the current timeline duration and use it
    @lifetimeEnd = AWidgetTimeline.getMe().getDuration()

    # Our timebar color, can be changed freely (timeline requires notification)
    # To see avaliable colors, check AWidgetTimeline for their declarations,
    # and colors.styl for their definitions
    @timebarColor = AWidgetTimeline.getRandomTimebarColor()

    # Property buffer, holds values at different points in time. Current
    # property values are calculated based on the current cursor position,
    # nearest two values and the described bezier representing the transition
    #
    # NOTE: This gets relatively large for complex actor lifetimes
    @_propBuffer = {}

    # After a cursor time is selected current values are calculated from the
    # prop buffer. Live edits at the current cursor location are stored in
    # our properties object, while the state of our properties at the current
    # cursor time pre-modification is stored in _propSnapshot
    #
    # tl;dr this is where the current buffer snapshot is stored
    @_propSnapshot = null

    # True after postInit() is called
    @_initialized = false

    # Holds information on the bezier function to use for value changes between
    # states. If none is specified for a specific value change, the value is
    # assumed to change instantaneously upon leaving the start state!
    #
    # Keys are of the name "end" where 'end' is the state where animation ends
    # Values contain an array of individual animation objects, each containing
    # an ABezier instance for each property changed between the start and
    # end states
    #
    # If no control points are specified, linear interpolation is assumed
    @_animations = {}

    # Time of the last update, used to save our properties when the cursor is
    # moved. Note that this starts at our birth!
    @_lastTemporalState = Math.floor @lifetimeStart

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
    # Note that we expect composite update methods to take an object containing
    # the same keys as the composite has components. i.e. position takes (x, y)
    # and color takes (r, g, b)

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
        v.x = param.optional v.x, @components.x._value
        v.y = param.optional v.y, @components.y._value

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

        v.r = param.optional v.r, @components.r._value
        v.g = param.optional v.g, @components.g._value
        v.b = param.optional v.b, @components.b._value

        @components.r._value = v.r
        @components.g._value = v.g
        @components.b._value = v.b

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

  # Needs to be called after our awgl actor is instantiated, so we can prepare
  # our property buffer for proper use
  postInit: ->
    if @_initialized
      AUtilLog.warn "postInit already called, bailing"
      return

    # Prevent future calls
    @_initialized = true

    # Set up properties by grabbing initial values
    for p of @_properties
      @_properties[p].getValue()

    # Update prop buffer, injects our current values as our birth state
    @updateInTime()

  # Helper function to call a cb for each property. Useful to avoid writing
  # composite-aware property iterating code.
  #
  # Callback is called in the form cb(property, composite) where property is
  # the full property object, and composite is boolean
  #
  # @param [Object] obj properties object to parse
  # @param [Method] cb callback to call with every property
  perProp: (obj, cb) ->

    # Iterate over properties
    for p of obj

      # Composite iterate over components
      if obj[p].type == "composite" and obj[p].components != undefined
        for c of obj[p].components
          cb obj[p].components[c], true

      # Call cb with property (non-composite)
      else
        cb obj[p], false

  # Materialize the actor from various stored value deltas (woah, that sounds
  # epic). Essentially, update our prop buffer, and then the actors' current
  # state
  updateInTime: ->

    @_updatePropBuffer()
    @_updateActorState()
    @_genSnapshot()

    cursor = AWidgetTimeline.getMe().getCursorTime()
    @_lastTemporalState = Number Math.floor(cursor)

  # Generates a new snapshot from our current properties
  # @private
  _genSnapshot: ->

    @_propSnapshot = {}

    for p of @_properties

      _Sp = {}
      _p = @_properties[p]

      if _p.type == "composite" and _p.components != undefined
        _Sp.components = {}
        for c of _p.components
          _Sp.components[c] = {}
          _Sp.components[c].value = _p.components[c]._value

      else
        _Sp.value = _p._value

      @_propSnapshot[p] = _Sp

  # Finds states between our last temporal state, and the supplied state, and
  # applies them in order
  #
  # @param [Number] state
  # @private
  _applyKnownState: (state) ->
    param.required state

    if Number(state) == @_lastTemporalState then return

    # Apply saved state. Find all stored states between our previous state
    # and the current one. Then sort, and finally apply in order.
    #
    # NOTE: The order of application varies depending on the direction in
    #       time in which we moved!
    if state > @_lastTemporalState then right = true else right = false

    # Figure out intermediary states
    intermediaryStates = []
    next = @_lastTemporalState
    while next != state
      next = @_findNearestState next, right
      if Number(next) != Math.floor @lifetimeStart
        intermediaryStates.push next

    # Now sort accordingly
    intermediaryStates.sort (a, b) ->

      # We moved back in time, lastTemporalState is in front of the state
      if right == false
        if Number(a) > Number(b)
          return -1
        else if Number(a) < Number(b)
          return 1
        else return 0

      # We moved forwards in time, lastTemporalState is behind our state
      else
        if Number(a) > Number(b)
          return 1
        else if Number(a) < Number(b)
          return -1
        else return 0

    # Now apply our states in the order presented
    for s in intermediaryStates

      # Go through and update values
      for p of @_propBuffer[s]

        _prop = @_propBuffer[s][p]

        if _prop.components != undefined

          # Update component-wise
          _update = {}
          for c of _prop.components
            _update[c] = _prop.components[c].value

          @_properties[p].update _update

        # No components, update directly
        else
          @_properties[p]._value = _prop.value

  # Updates our state according to the current cursor position. Goes through
  # our prop buffer, and calculates a new snapshot and property object
  # accordingly.
  #
  # This is actually a tad complicated, as buffer entries are not full
  # property snapshots. Instead, they are snapshots of properties modified
  # at that point in time, with only our birth providing a full snapshot.
  #
  # Our properties object is fully specified initially using our birth
  # snapshot. From then on, all changes are incremental. So if we have 5 buffer
  # entries available and want to update our actor to the state specified
  # by the 4th, we need to apply birth state, followed by our updates in
  # the 2nd state, then 3rd, and finally 4th.
  #
  # Optimally however, we can remember our previous state, and only update
  # using the buffer entries we've passed over. In this case, if we are on
  # state 3 and want to move to state 5, we'd only apply state 4 inbetween.
  #
  # If we are, however, moving to a state that does not exist, we must
  # apply to the nearest state, and then calculate value deltas accordingly.
  # If we are not surrounded by two states (rare), our state is as specified
  # by the previous one we applied. If we are though (most often), we must
  # calculate new values using the specific bezier function each value
  # requires.
  #
  # The bezier function we require is stored in _animations (for each property)
  # with a name consisting of "end" where 'end' is the buffer entry for the
  # end state
  #
  # @private
  _updateActorState: ->

    ##
    ## First, apply intermediary states
    ##

    cursor = Math.floor AWidgetTimeline.getMe().getCursorTime()

    # If we haven't moved, drop out early
    if cursor == @_lastTemporalState then return

    # If we don't have a saved state at the current cursor position, find the
    # nearest and calculate our time offset. Worst case, the closest state
    # is our birth
    nearest = cursor
    if @_propBuffer[String(cursor)] == undefined
      nearest = @_findNearestState cursor

    # Apply intermediary states (up to ourselves if we have a state)
    @_applyKnownState nearest

    # Return if we have nothing else to do (cursor is at a known state)
    if nearest == cursor then return

    ##
    ## Next, bail if there are no states to the right of ourselves
    ##
    if @_findNearestState(cursor, true) == -1 then return

    # Reset the cursor value
    cursor = Math.floor AWidgetTimeline.getMe().getCursorTime()

    ##
    ## Now the fun part; find all values defined to the right of us
    ##
    ## Varying stores objects containing a property name and end cap
    varying = []

    # Helper
    _pushUnique = (p) ->
      unique = true
      for v in varying
        if v == p.name
          unique = false
          break
      if unique then varying.push p

    from = String(cursor)
    while (from = @_findNearestState(from, true)) != -1
      for p of @_propBuffer[from]
        _pushUnique { name: p, end: from }

    ##
    ## Now that we've built that list, go through and apply the delta of each
    ## property to ourselves
    ##
    for v in varying

      anim = @_animations["#{v.end}"]
      _prop = @_properties[v.name]

      # Sanity checks
      if _prop == undefined
        throw new Error "We don't have the property #{v.name}!"

      if anim == undefined
        throw new Error "Animation does not exist for #{right}!"

      if anim[v.name] == undefined
        throw new Error "Animation doesn't effect #{v.name}!"

      # The property to be animated is composite. Apply the state change
      # to each component individually.
      if _prop.type == "composite" and _prop.components != undefined

        val = {}

        for c of _prop.components

          _start = anim[v.name].components[c]._start.x
          t = (cursor - _start) / (v.end - _start)

          val[c] = (anim[v.name].components[c].eval t).y
          label = "#{_start}-|#{cursor}|-#{v.end}"
          console.log "#{label} #{v.name}.#{c} #{val[c]}"

          # Store new value
          @_properties[v.name].update val

      else

        # Evaluate new property value
        _start = anim[v.name]._start.x
        t = (cursor - _start) / (v.end - _start)

        val = (anim[v.name].eval t).y
        console.log "Change #{v.name} to #{val} [#{t}]"

        # Store new value
        @_properties[v.name].update val

      # Update property bar, wooooo
      # TODO: Update individual properties
      $("body").data("default-properties").refresh @

  # Calculates new prop buffer state, using current prop snapshot, cursor
  # position and existing properties.
  #
  # @private
  _updatePropBuffer: ->

    # propSnapshot is null when we have just been initialized, current
    # properties are defaults. Set up our birth state
    if @_propSnapshot == null

      # Save current property values
      @_propBuffer[@_lastTemporalState] = @_serializeProperties()

    else

      # Check which properties have changed
      # NOTE: We expect the prop snapshot to be valid, and contain the
      #       structure required by each property in it!
      delta = []
      for p of @_propSnapshot
        modified = false

        _p = @_properties[p]
        _Sp = @_propSnapshot[p]

        # Compare snapshot with live property ()
        if _p.type == "composite" and _p.components != undefined

          # Iterate over components to detect modification
          for c of _p.components
            if _Sp.components[c].value != _p.components[c]._value
              modified = true

        else if _Sp.value != _p._value
          modified = true

        # Differs, ship to delta
        if modified then delta.push p

      # If we have anything to save, ship to our buffer, and create a new
      # animation entry.
      #
      # cursor is our last temporal state, since the current cursor position
      # is not where the properties were set!
      if delta.length > 0

        _serialized = @_serializeProperties delta
        @_propBuffer[@_lastTemporalState] = _serialized

        # Ensure we are not at birth!
        if @_lastTemporalState == Math.floor @lifetimeStart then return

        # Define our animation
        # Note that an animation is an object with a bezier function for
        # every component changed in our end object
        @_animations["#{@_lastTemporalState}"] = {}

        # Go through and set up individual variable beziers. Note that for
        # composites the same bezier is made for each component in an identical
        # manner! Since we assume linear interpolation, we fill in blank
        # objects with no control points.
        for p in delta

          # Create a bezier class; this would be the place to do that
          # per-component
          #
          # We find our start value by going back through our prop buffer and
          # finding the nearest reference to the property we now modify
          #
          # _findNearestPropReference...
          trueStart = @_findNearestState @_lastTemporalState, false, p

          _startP = @_propBuffer[String(trueStart)][p]
          _endP = @_propBuffer[@_lastTemporalState][p]

          # Create multiple beziers if so required
          if _endP.components != undefined
            @_animations["#{@_lastTemporalState}"][p] = { components: {} }
            for c of _endP.components

              _start =
                x: Number trueStart
                y: _startP.components[c].value

              _end =
                x: Number @_lastTemporalState
                y: _endP.components[c].value

              # Note that we enable buffering!
              bezzie = new ABezier _start, _end, 0, [], true
              @_animations["#{@_lastTemporalState}"][p].components[c] = bezzie
          else
            _start =
              x: Number trueStart
              y: _startP.value

            _end =
              x: Number @_lastTemporalState
              y: _endP.value

            # Note that we enable buffering!
            bezzie = new ABezier _start, _end, 0, [], true
            @_animations["#{@_lastTemporalState}"][p] = bezzie

  # Find the nearest prop buffer entry to the left/right of the supplied state
  # An optional property can be passed in, adding its existence as a criteria
  # for the returned state. Validation of the property is also performed
  #
  # @param [String] start prop buffer entry name to start from
  # @param [Boolean] right search to the right, defaults to false
  # @param [String] prop property name
  # @return [String] nearest key into @_propBuffer, or -1 if not found
  # @private
  _findNearestState: (start, right, prop) ->
    param.required start
    right = param.optional right, false
    prop = param.optional prop, null

    start = Number(start)
    nearest = -1

    for p of @_propBuffer
      if @_propBuffer[p] != undefined
        if right
          if Number(p) > start and (Number(p) < nearest or nearest == -1)
            if prop == null then nearest = p
            else if @_propBuffer[p][prop] != undefined then nearest = p
        else
          if Number(p) < start and Number(p) > nearest
            if prop == null then nearest = p
            else if @_propBuffer[p][prop] != undefined then nearest = p

    if nearest == -1 then return -1 else return String nearest

  # Prepares our properties object for injection into the buffer. In essence,
  # builds a new object containing only current values, and returns it for
  # inclusion in the buffer.
  #
  # @param [Array<String>] delta array of property names to serialize
  # @return [Object] serialProps properties ready to be buffered
  # @private
  _serializeProperties: (delta) ->

    # If no property names are supplied, serialize all properties
    delta = param.optional delta, []

    # Go through and build an object for our buffer, simple
    props = {}

    for p of @_properties

      # Check if we are meant to serialize this property
      needsSerialization = false
      if delta.length == 0
        needsSerialization = true
      else
        for d in delta
          if p == d
            needsSerialization = true
            break

      if needsSerialization

        _prop = @_properties[p]
        props[p] = {}

        if _prop.type == "composite" and _prop.components != undefined
          props[p].components = {}
          for c of _prop.components
            props[p].components[c] = {}
            props[p].components[c].value = _prop.components[c]._value
        else
          props[p].value = _prop._value

    props

  # Takes serialized properties at the specified cursor time, and de-serializes
  # them; essentially reading out values and setting them appropriately in our
  # live properties object.
  #
  # @param [String] time string index into our prop buffer (cursor time in ms)
  # @private
  _deserializeProperties: (time) ->

    # Should never happen as we are only used internally
    if @_propBuffer[time] == undefined
      throw new Error "Can't deserialize, invalid time provided! #{time}"

    props = @_propBuffer[time]

    # Manually set property values
    for p of props

      # Set values component-wise if required, otherwise direct
      if props[p].components != undefined
        for c of props[p].components
          @_properties[p].components[c]._value = props[p].components[c].value
      else
        @_properties[p]._value = props[p].value

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