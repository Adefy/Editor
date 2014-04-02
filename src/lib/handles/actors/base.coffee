define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  Handle = require "handles/handle"
  Bezier = require "widgets/timeline/bezier"

  Timeline = require "widgets/timeline/timeline"

  # Base manipulateable class for actors
  class BaseActor extends Handle

    ###
    # @property [Number] accuracy the number of digits we round animations to
    ###
    ACCURACY: 4

    # Defines a raw actor, with no shape information or any other presets.
    # This serves as the base for the other actor classes
    #
    # @param [UIManager] ui
    # @param [Number] lifetimeStart_ms time at which we are created, in ms
    # @param [Number] lifetimeEnd_ms time we are destroyed, defaults to end of ad
    constructor: (@ui, lifetimeStart, lifetimeEnd) ->
      param.required @ui

      super()

      @_AJSActor = null
      @name = "Base Actor"
      @_alive = false
      @_initialized = false # True after postInit() is called

      @lifetimeStart_ms = param.required lifetimeStart
      @lifetimeEnd_ms = param.optional lifetimeEnd, @ui.timeline.getDuration()

      ###
      # Property buffer, holds values at different points in time. Current
      # property values are calculated based on the current cursor position,
      # nearest two values and the described bezier representing the transition
      #
      # NOTE: This gets relatively large for complex actor lifetimes
      ###
      @_propBuffer = {}

      ###
      # This saves the state of our actor at the current cursor time, before
      # any modifications are made. Changes are calculated as the difference
      # between this snapshot, and our properties object.
      ###
      @_propSnapshot = null

      ###
      # Holds information on the bezier function to use for value changes
      # between states. If none is specified for a specific value change, the
      # value is assumed to change instantaneously upon leaving the start state
      #
      # Keys are named by the point in time where the associated animation ends
      # in ms. Values contain an array of individual animation objects, each
      # containing an Bezier instance for each property changed between the
      # start and end states
      #
      # If no control points are specified, linear interpolation is assumed
      ###
      @_animations = {}

      # Set to true if the cursor is to the right of our last prop buffer, and
      # _capState() has been called
      @_capped = false

      # Time of the last update, used to save our properties when the cursor is
      # moved. Note that this starts at our birth!
      @_lastTemporalState = Math.floor @lifetimeStart_ms

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
      # Each type needs to have a getValue() method, an optional genAnimationOpts
      # method, and an update() method. Components of composites shouldn't
      # provide an update() method, as the parent composite takes care of
      # updating all components.
      #
      # The genAnimationOpts method needs to return an animations object suitable
      # for export, that can be passed to AJS.animate when animating the property
      # using the provided animation object.
      #
      # The genAnimationOpts method is only required if the property is not
      # natively supported by the engine.
      #
      # All top-level properties should fetch up-to-date information in their
      # getValue() methods, and save it locally as _value. Composites doing this
      # must perform the saving for their children.
      #
      # Note that we expect composite update methods to take an object containing
      # the same keys as the composite has components. i.e. position takes (x, y)
      # and color takes (r, g, b)

      me = @

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

          if me._AJSActor != null
            pos = me._AJSActor.getPosition()

            @components.x._value = Number pos.x.toFixed me.ACCURACY
            @components.y._value = Number pos.y.toFixed me.ACCURACY

        # Position update, we expect val to be a composite
        update: (v) ->
          param.required v

          v.x = param.optional v.x, @components.x._value
          v.y = param.optional v.y, @components.y._value

          @components.x._value = v.x
          @components.y._value = v.y

          if me._AJSActor != null
            me._AJSActor.setPosition new AJSVector2(v.x, v.y)

      @_properties["rotation"] =
        type: "number"
        live: true
        min: 0
        max: 360
        float: true
        placeholder: 0

        # Fetch our angle from our actor
        getValue: ->
          @_value = Number me._AJSActor.getRotation().toFixed me.ACCURACY

        # Val simply contains our new angle in degrees
        update: (v) ->
          @_value = param.required v
          me._AJSActor.setRotation v if me._AJSActor != null

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
            _value: 0
            getValue: -> @_value
          g:
            type: "number"
            min: 0
            max: 255
            float: false
            placeholder: 255
            _value: 0
            getValue: -> @_value
          b:
            type: "number"
            min: 0
            max: 255
            float: false
            placeholder: 255
            _value: 0
            getValue: -> @_value

        # We fetch color information from our actor, and set composite
        # values accordingly
        getValue: ->

          if me._AJSActor != null
            col = me._AJSActor.getColor()

            @components.r._value = Number col.getR().toFixed me.ACCURACY
            @components.g._value = Number col.getG().toFixed me.ACCURACY
            @components.b._value = Number col.getB().toFixed me.ACCURACY

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

          if me._AJSActor != null
            me._AJSActor.setColor new AJSColor3 v.r, v.g, v.b

      @_properties["physics"] =
        type: "composite"
        live: false

        # We cache component values locally, and just pass those through
        components:
          enabled:
            type: "bool"
            _value: false
            getValue: -> @_value
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
          @components.enabled._value = param.required v.enabled
          @components.mass._value = param.required v.mass
          @components.elasticity._value = param.required v.elasticity
          @components.friction._value = param.required v.friction

          if me._AJSActor != null

            # Note that we re-create the physics body every time!
            # TODO: Optimize this
            me._AJSActor.disablePsyx()

            if v.enabled
              me._AJSActor.enablePsyx v.mass, v.friction, v.elasticity


    ###
    # Get internal actors' id. Note that the actor must exist for this!
    #
    # @return [Number] id
    ###
    getActorId: ->
      if @_AJSActor
        @_AJSActor.getId()
      else
        null

    ###
    # Get our internal actor
    #
    # @param [AJSBaseActor] actor
    ###
    getActor: -> @_AJSActor

    ###
    # @param [Booleab] _visible
    ###
    getVisible: ->
      if @_AJSActor
        @_AJSActor.getVisible()
      else
        false

    ###
    # Return actor opacity
    #
    # @return [Number] opacity
    ###
    getOpacity: -> 1.0

    ###
    # Return actor position as (x,y) relative to the GL world
    #
    # @return [Object] position
    ###
    getPosition: ->
      if @_AJSActor
        @_AJSActor.getPosition()
      else
        null

    ###
    # Get actor rotation
    #
    # @return [Number] angle in degrees
    ###
    getRotation: ->
      if @_AJSActor
        @_properties["rotation"].getValue()
      else
        null

    ###
    # Return actor color as (r,g,b)
    #
    # @param [Boolean] float defaults to false, returns components as 0.0-1.0
    # @return [Object] color
    ###
    getColor: (float) ->
      float = param.optional float, false

      if @_AJSActor
        _col = @_AJSActor.getColor()

        {
          r: _col.getR(float)
          g: _col.getG(float)
          b: _col.getB(float)
        }
      else
        null

    ###
    # Return actor physics
    #
    # @return [Object] physics properties
    ###
    getPsyX: ->
      if @_AJSActor
        _physics = @_properties["physics"].components

        {
          enabled: _physics.enabled.getValue()
          mass: _physics.mass.getValue()
          elasticity: _physics.elasticity.getValue()
          friction: _physics.friction.getValue()
        }
      else
        null

    ###
    # Get buffer entry
    #
    # @param [Number] time
    # @return [Object] entry prop buffer entry, may be undefined
    ###
    getBufferEntry: (time) -> @_propBuffer["#{Math.floor time}"]

    ###
    # @param [Boolean] visible
    ###
    setVisible: (visible) ->
      @_AJSActor.setVisible visible if @_AJSActor
      @updateInTime()

    ###
    # @param [Number] opacity
    ###
    setOpacity: (opacity) ->
      opacity = Number (param.required opacity).toFixed(@ACCURACY)

      AUtilLog.warn "AJS does not support actor with an opacity, yet."
      # @_AJSActor.setOpacity opacity if @_AJSActor
      @updateInTime()

    ###
    # Set actor position, relative to the GL world!
    #
    # @param [Number] x x coordinate
    # @param [Number] y y coordinate
    ###
    setPosition: (x, y) ->
      x = Number (param.required x).toFixed(@ACCURACY)
      y = Number (param.required y).toFixed(@ACCURACY)

      @_properties["position"].update x: x, y: y
      @updateInTime()

    ###
    # Set actor rotation
    #
    # @param [Number] angle
    ###
    setRotation: (angle) ->
      angle = Number (param.required angle).toFixed(@ACCURACY)

      @_properties["rotation"].update angle
      @updateInTime()

    ###
    # Set actor color with composite values, 0-255
    #
    # @param [Number] r
    # @param [Number] g
    # @param [Number] b
    ###
    setColor: (r, g, b) ->
      r = Number (param.required r).toFixed(@ACCURACY)
      g = Number (param.required g).toFixed(@ACCURACY)
      b = Number (param.required b).toFixed(@ACCURACY)

      @_properties["color"].update r: r, g: g, b: b
      @updateInTime()

    ###
    # @param [Texture] texture
    ###
    setTexture: (texture) ->
      @_AJSActor.setTexture texture
      @updateInTime()

    ###
    # Used when exporting, executes the corresponding property genAnimationOpts
    # method if one exists. Returns null if the property does not exist, or if
    # the property does not have a genAnimationOpts method.
    #
    # @param [String] property property name
    # @param [Object] animation animation object
    # @param [Object] options input options
    # @param [String] component optional component name
    # @return [Object] options output options
    ###
    genAnimationOpts: (property, anim, opts, component) ->
      param.required property
      param.required anim
      param.required opts
      component = param.optional component, ""

      prop = @_properties[property]

      return null unless prop

      if prop.components
        return null unless prop.components[component].genAnimationOpts
        prop.components[component].genAnimationOpts anim, opts
      else
        return null unless prop.genAnimationOpts == undefined
        prop.genAnimationOpts anim, opts

    ###
    # Called when the cursor leaves our lifetime on the timeline. We delete
    # our AJS actor if not already dead
    ###
    timelineDeath: ->
      return unless @_alive
      @_alive = false

      @_AJSActor.destroy()
      @_AJSActor = null

    ###
    # Virtual method that our children need to implement, called when our AJS
    # actor needs to be instantiated
    # @private
    ###
    _birth: ->

    ###
    # Get our living state
    #
    # @return [Boolean] alive
    ###
    isAlive: -> @_alive

    ###
    # Needs to be called after our are actor is instantiated, so we can prepare
    # our property buffer for proper use
    ###
    postInit: ->
      return if @_initialized
      @_initialized = true

      @_birth()

      # Set up properties by grabbing initial values
      @_properties[p].getValue() for p of @_properties

      @updateInTime()

    ###
    # Helper function to call a cb for each property. Useful to avoid writing
    # composite-aware property iterating code.
    #
    # Callback is called in the form cb(property, composite) where property is
    # the full property object, and composite is boolean
    #
    # @param [Object] obj properties object to parse
    # @param [Method] cb callback to call with every property
    ###
    perProp: (obj, cb) ->
      for p of obj

        # Composite iterate over components
        if obj[p].type == "composite" and obj[p].components
          for c of obj[p].components
            cb obj[p].components[c], true

        # Call cb with property (non-composite)
        else
          cb obj[p], false

    ###
    # Calls the default handle updateProperties() method, then updates us in
    # time
    #
    # @param [Object] updates object containing property:value pairs
    ###
    updateProperties: (updates) ->
      super updates
      @updateInTime()

    ###
    # Materialize the actor from various stored value deltas (woah, that sounds
    # epic). Essentially, update our prop buffer, and then the actors' current
    # state
    ###
    updateInTime: ->
      @_birth() unless @_alive

      cursor = @ui.timeline.getCursorTime()

      # return if Number(Math.floor(cursor)) == @_lastTemporalState

      @_updatePropBuffer()
      @_updateActorState()
      @_genSnapshot()

      # Save state
      @_lastTemporalState = Number Math.floor(cursor)

      @ui.pushEvent "actor.update.intime", actor: @

    ###
    # Generates a new snapshot from our current properties
    # @private
    ###
    _genSnapshot: ->

      @_propSnapshot = {}

      for p of @_properties

        _Sp = {}
        _p = @_properties[p]

        if _p.type == "composite" and _p.components
          _Sp.components = {}

          for c of _p.components
            _Sp.components[c] = {}
            _Sp.components[c].value = _p.components[c]._value

        else
          _Sp.value = _p._value

        unless isNaN _Sp.value
          _Sp.value = Number _Sp.value.toFixed @ACCURACY

        @_propSnapshot[p] = _Sp

    ###
    # Finds states between our last temporal state, and the supplied state, and
    # applies them in order
    #
    # @param [Number] state
    # @private
    ###
    _applyKnownState: (state) ->
      state = Number param.required state

      return if state == @_lastTemporalState

      # Apply saved state. Find all stored states between our previous state
      # and the current one. Then sort, and finally apply in order.
      #
      # NOTE: The order of application varies depending on the direction in
      #       time in which we moved!
      if state > @_lastTemporalState
        right = true
      else
        right = false

      # Figure out intermediary states
      intermStates = []
      next = @_lastTemporalState

      while next != state and next != -1
        next = @_findNearestState next, right

        if next != Math.floor(@lifetimeStart_ms) and next != -1

          # Ensure next hasn't overshot us
          if (right and next < state) or (!right and next > state)
            intermStates.push next

      # Now sort accordingly
      intermStates.sort (a, b) ->

        # We moved back in time, lastTemporalState is in front of the state
        if right == false
          if a > b
            -1
          else if a < b
            1
          else
            0

        # We moved forwards in time, lastTemporalState is behind our state
        else
          if a > b
            1
          else if a < b
            -1
          else
            0

      # Now apply our states in the order presented
      for s in intermStates
        @_applyPropBuffer @_propBuffer["#{s}"]

    ###
    # Applies data in prop buffer entry
    #
    # @param [Object] buffer
    # @private
    ###
    _applyPropBuffer: (buffer) ->
      param.required buffer

      for name, property of buffer

        if property.components
          update = {}
          update[c] = property.components[c].value for c of property.components

          @_properties[name].update update

        else
          @_properties[name].update property.value

    ###
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
    # THIS IS SPARTAAAAAAA
    #
    # @private
    ###
    _updateActorState: ->

      ##
      ## First, apply intermediary states
      ##
      cursor = Math.floor @ui.timeline.getCursorTime()

      # If we haven't moved, drop out early
      return if cursor == @_lastTemporalState

      # Ensure cursor is within our lifetime
      return if cursor < @lifetimeStart_ms or cursor > @lifetimeEnd_ms

      # If we don't have a saved state at the current cursor position, find the
      # nearest and calculate our time offset. Worst case, the closest state
      # is our birth
      nearest = cursor
      if @_propBuffer[String(cursor)] == undefined
        nearest = @_findNearestState cursor

      # Apply intermediary states (up to ourselves if we have a state)
      @_applyKnownState nearest

      # Return if we have nothing else to do (cursor is at a known state)
      return if nearest == cursor

      # Next, bail if there are no states to the right of ourselves
      if @_findNearestState(cursor, true) == -1
        return @_capState()

      @_capped = false

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

        varying.push p if unique

      from = cursor
      while (from = @_findNearestState(from, true)) != -1
        for p of @_propBuffer[String from]
          _pushUnique { name: p, end: from }

      ##
      ## Now that we've built that list, go through and apply the delta of each
      ## property to ourselves
      ##
      for v in varying

        anim = @_animations["#{v.end}"]
        _prop = @_properties[v.name]

        # Sanity checks
        # TODO: Refactor these into log messages + returns
        if _prop == undefined
          throw new Error "We don't have the property #{v.name}!"

        if anim == undefined
          throw new Error "Animation does not exist for #{v.end}!"

        if anim[v.name] == undefined
          throw new Error "Animation doesn't effect #{v.name}!"

        # The property to be animated is composite. Apply the state change
        # to each component individually.
        if _prop.type == "composite" and _prop.components != undefined

          val = {}

          for c of _prop.components
            _start = anim[v.name].components[c]._start.x

            # Ensure animation starts before us
            if _start <= cursor
              t = (cursor - _start) / (v.end - _start)

              val[c] = (anim[v.name].components[c].eval t).y

              # Store new value
              @_properties[v.name].update val

        else
          _start = anim[v.name]._start.x

          if _start <= cursor
            t = (cursor - _start) / (v.end - _start)

            val = (anim[v.name].eval t).y

            # Store new value
            @_properties[v.name].update val

    ###
    # This gets called if the cursor is to the right of us, and it has not yet
    # been called since the cursor has been in that state. It applies all buffer
    # states in order
    #
    # @private
    ###
    _capState: ->
      return if @_capped
      @_capped = true

      # Sort prop buffer entries
      _buff = _.keys(@_propBuffer).map (b) -> Number b
      _buff.sort (a, b) -> a - b

      # Apply buffers in order
      @_applyPropBuffer @_propBuffer["#{b}"] for b in _buff

    ###
    # Returns an array containing the names of properties that have been
    # modified since our last snapshot. Used in @_updatePropBuffer
    #
    # @return [Array<String>] delta
    # @private
    ###
    _getPropertiesDelta: ->

      # Check which properties have changed
      # NOTE: We expect the prop snapshot to be valid, and contain the
      #       structure required by each property in it!
      delta = []
      for name, snapshot of @_propSnapshot
        modified = false

        prop = @_properties[name]

        # Compare snapshot with live property
        if prop.type == "composite" and prop.components

          # Iterate over components to detect modification
          for c of prop.components
            if snapshot.components[c].value != prop.components[c]._value
              modified = true

        else if snapshot.value != prop._value
          modified = true

        # Differs, ship to delta
        delta.push name if modified

      delta

    ###
    # Split the animation containing 'time', if it operates on prop. Used in
    # @_updatePropBuffer
    #
    # @param [Number] time
    # @param [String] prop property key
    # @param [String] left optional pre-calculated left cap
    # @private
    ###
    _splitAnimation: (time, p, left) ->
      param.required time
      param.required p

      unless left
        left = @_findNearestState time, false, p

      left = 0 if left = -1

      # Check if we are in the middle of an animation ourselves. If so,
      # split it
      animCheck = @_findNearestState time, true, p

      # If we are on the tip of an animation, then bail
      return if @_animations["#{time}"]

      _startP = @_propBuffer["#{left}"][p]
      _endP = @_propBuffer["#{time}"][p]

      if animCheck != -1

        # An animation overlaps us. Perform an integrity check on it, then
        # split.
        anim = @_animations[animCheck]

        if anim[p].components
          for c of anim[p].components

            # Rebase animation by calculating new start value
            _newX = time
            _newY = _endP.components[c].value

            @_animations[animCheck][p].components[c]._start.x = _newX
            @_animations[animCheck][p].components[c]._start.y = _newY

        else
          if anim[p]._start.x != Number left
            throw new Error "Existing animation invalid!"

          _newX = time
          _newY = _endP.value

          @_animations[animCheck][p]._start.x = _newX
          @_animations[animCheck][p]._start.y = _newY

    ###
    # Calculates new prop buffer state, using current prop snapshot, cursor
    # position and existing properties.
    #
    # @private
    ###
    _updatePropBuffer: ->

      # propSnapshot is null when we have just been initialized, current
      # properties are defaults. Set up our birth state
      if @_propSnapshot == null

        # Save current property values
        @_propBuffer[@_lastTemporalState] = @_serializeProperties()

      delta = @_getPropertiesDelta()

      # If we have anything to save, ship to our buffer, and create a new
      # animation entry.
      #
      # cursor is our last temporal state, since the current cursor position
      # is not where the properties were set!
      if delta.length > 0

        _serialized = @_serializeProperties delta
        @_propBuffer[@_lastTemporalState] = _serialized

        # Ensure we are not at birth!
        return if @_lastTemporalState == Math.floor @lifetimeStart_ms

        # Define our animation
        # Note that an animation is an object with a bezier function for
        # every component changed in our end object
        if @_animations["#{@_lastTemporalState}"] == undefined
          @_animations["#{@_lastTemporalState}"] = {}

        # Go through and set up individual variable beziers. Note that for
        # composites the same bezier is made for each component in an identical
        # manner! Since we assume linear interpolation, we fill in blank
        # objects with no control points.
        #
        # If we are between two end points in which the property changes, split
        # the animation appropriately
        for p in delta

          # Create a bezier class; this would be the place to do that
          # per-component
          #
          # We find our start value by going back through our prop buffer and
          # finding the nearest reference to the property we now modify
          trueStart = @_findNearestState @_lastTemporalState, false, p

          # Split animation if necessary
          @_splitAnimation @_lastTemporalState, p, trueStart

          _startP = @_propBuffer["#{trueStart}"][p]
          _endP = @_propBuffer["#{@_lastTemporalState}"][p]

          # Create multiple beziers if so required
          if _endP.components
            @_animations["#{@_lastTemporalState}"][p] = components: {}
            for c of _endP.components

              _start =
                x: trueStart
                y: _startP.components[c].value

              _end =
                x: @_lastTemporalState
                y: _endP.components[c].value

              # We no longer enable buffering, since saving our state creates an
              # obnoxiously large buffer!
              bezzie = new Bezier _start, _end, 0, [], false
              @_animations["#{@_lastTemporalState}"][p].components[c] = bezzie
          else
            _start =
              x: trueStart
              y: _startP.value

            _end =
              x: @_lastTemporalState
              y: _endP.value

            # We no longer enable buffering, since saving our state creates an
            # obnoxiously large buffer!
            bezzie = new Bezier _start, _end, 0, [], false
            @_animations["#{@_lastTemporalState}"][p] = bezzie

    ###
    # Return animations array
    #
    # @return [Array<Object>] animations
    ###
    getAnimations: -> @_animations

    ###
    # Find the nearest prop buffer entry to the left/right of the supplied state
    # An optional property can be passed in, adding its existence as a criteria
    # for the returned state. Validation of the property is also performed
    #
    # @param [String] start prop buffer entry name to start from
    # @param [Boolean] right search to the right, defaults to false
    # @param [String] prop property name
    # @return [Number] nearest key into @_propBuffer
    # @private
    ###
    _findNearestState: (start, right, prop) ->
      start = Number param.required start
      right = param.optional right, false
      prop = param.optional prop, null

      nearest = -1

      for time, buffer of @_propBuffer
        time = Number time

        if buffer
          if right and (time > start) and (time < nearest or nearest == -1)
            nearest = time if prop == null or buffer[prop]
          else if !right and (time < start) and (time > nearest)
            nearest = time if prop == null or buffer[prop]

      nearest

    ###
    # Prepares our properties object for injection into the buffer. In essence,
    # builds a new object containing only current values, and returns it for
    # inclusion in the buffer.
    #
    # @param [Array<String>] delta array of property names to serialize
    # @return [Object] serialProps properties ready to be buffered
    # @private
    ###
    _serializeProperties: (delta) ->

      # If no property names are supplied, serialize all properties
      delta = param.optional delta, []

      # Go through and build an object for our buffer, simple
      props = {}

      for name, value of @_properties
        needsSerialization = false

        if delta.length == 0
          needsSerialization = true
        else
          for d in delta
            if name == d
              needsSerialization = true
              break

        if needsSerialization
          props[name] = {}

          if value.type == "composite" and value.components
            props[name].components = {}

            for c of value.components
              props[name].components[c] = {}
              props[name].components[c].value = value.components[c]._value

          else
            props[name].value = value._value

      props

    ###
    # Takes serialized properties at the specified cursor time, and de-serializes
    # them; essentially reading out values and setting them appropriately in our
    # live properties object.
    #
    # @param [String] time string index into our prop buffer (cursor time in ms)
    # @private
    ###
    _deserializeProperties: (time) ->
      props = @_propBuffer[time]

      # Manually set property values
      for p of props

        # Set values component-wise if required, otherwise direct
        if props[p].components
          for c of props[p].components
            @_properties[p].components[c]._value = props[p].components[c].value
        else
          @_properties[p]._value = props[p].value

    ###
    # Deletes us, muahahahaha. We notify the workspace, clear the properties
    # panel if it is targetting us, and destroy our actor.
    ###
    delete: ->
      if @_AJSActor != null

        # Notify the workspace
        @ui.workspace.notifyDemise @

        # Go through and remove ourselves from
        @_AJSActor.destroy()
        @_AJSActor = null

      super()
