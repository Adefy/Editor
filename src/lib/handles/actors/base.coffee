define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  Handle = require "handles/handle"
  Bezier = require "widgets/timeline/bezier"

  Timeline = require "widgets/timeline/timeline"

  CompositeProperty = require "handles/properties/composite"
  NumericProperty = require "handles/properties/numeric"
  BooleanProperty = require "handles/properties/boolean"

  # Base manipulateable class for actors
  window.BaseActor = class BaseActor extends Handle

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

      me = @

      @_properties.position = new CompositeProperty()
      @_properties.position.x = new NumericProperty()
      @_properties.position.y = new NumericProperty()

      @_properties.position.x.onUpdate = (value) =>
        return unless @_AJSActor
        position = @_AJSActor.getPosition()
        position.x = value
        @_AJSActor.setPosition position

      @_properties.position.y.onUpdate = (value) =>
        return unless @_AJSActor
        position = @_AJSActor.getPosition()
        position.y = value
        @_AJSActor.setPosition position

      @_properties.position.x.requestUpdate = ->
        @setValue me._AJSActor.getPosition().x if me._AJSActor

      @_properties.position.y.requestUpdate = ->
        @setValue me._AJSActor.getPosition().y if me._AJSActor

      @_properties.position.addProperty "x", @_properties.position.x
      @_properties.position.addProperty "y", @_properties.position.y

      @_properties.opacity = new NumericProperty()
      @_properties.opacity.setMin 0.0
      @_properties.opacity.setMax 1.0
      @_properties.opacity.setValue 1.0
      @_properties.opacity.setPlaceholder 1.0
      @_properties.opacity.setFloat true
      @_properties.opacity.setPrecision 6
      @_properties.opacity.onUpdate = (opacity) =>
        @_AJSActor.setOpacity opacity if @_AJSActor
      @_properties.opacity.requestUpdate = ->
        @setValue me._AJSActor.getOpacity() if me._AJSActor

      @_properties.rotation = new NumericProperty()
      @_properties.rotation.onUpdate = (rotation) =>
        @_AJSActor.setRotation rotation if @_AJSActor
      @_properties.rotation.requestUpdate = ->
        @setValue me._AJSActor.getRotation() if me._AJSActor


      @_properties.color = new CompositeProperty()
      @_properties.color.r = new NumericProperty()
      @_properties.color.r.setMin 0
      @_properties.color.r.setMax 255
      @_properties.color.r.setFloat false
      @_properties.color.r.setPlaceholder 255
      @_properties.color.r.setValue 0

      @_properties.color.g = new NumericProperty()
      @_properties.color.b = new NumericProperty()
      @_properties.color.g.clone @_properties.color.r
      @_properties.color.b.clone @_properties.color.r

      @_properties.color.r.onUpdate = (value) =>
        return unless @_AJSActor
        color = @_AJSActor.getColor()
        color.setR value
        @_AJSActor.setColor color

      @_properties.color.g.onUpdate = (value) =>
        return unless @_AJSActor
        color = @_AJSActor.getColor()
        color.setG value
        @_AJSActor.setColor color

      @_properties.color.b.onUpdate = (value) =>
        return unless @_AJSActor
        color = @_AJSActor.getColor()
        color.setB value
        @_AJSActor.setColor color

      @_properties.color.r.requestUpdate = ->
        @setValue me._AJSActor.getColor().getR() if me._AJSActor

      @_properties.color.g.requestUpdate = ->
        @setValue me._AJSActor.getColor().getG() if me._AJSActor

      @_properties.color.b.requestUpdate = ->
        @setValue me._AJSActor.getColor().getB() if me._AJSActor

      @_properties.color.addProperty "r", @_properties.color.r
      @_properties.color.addProperty "g", @_properties.color.g
      @_properties.color.addProperty "b", @_properties.color.b


      @_properties.physics = new CompositeProperty()
      @_properties.physics.mass = new NumericProperty()
      @_properties.physics.mass.setMin 0
      @_properties.physics.mass.setPlaceholder 50
      @_properties.physics.mass.setValue 50

      @_properties.physics.mass.onUpdate = (mass) =>
        @_AJSActor.setMass mass if @_AJSActor

      @_properties.physics.elasticity = new NumericProperty()
      @_properties.physics.elasticity.setMin 0
      @_properties.physics.elasticity.setMax 1
      @_properties.physics.elasticity.setPrecision 6
      @_properties.physics.elasticity.setPlaceholder 0.3
      @_properties.physics.elasticity.setValue 0.3

      @_properties.physics.elasticity.onUpdate = (elasticity) =>
        @_AJSActor.setElasticity elasticity if @_AJSActor

      @_properties.physics.friction = new NumericProperty()
      @_properties.physics.friction.setMin 0
      @_properties.physics.friction.setMax 1
      @_properties.physics.friction.setPrecision 6
      @_properties.physics.friction.setPlaceholder 0.2
      @_properties.physics.friction.setValue 0.2

      @_properties.physics.friction.onUpdate = (friction) =>
        @_AJSActor.setFriction friction if @_AJSActor


      @_properties.physics.enabled = new BooleanProperty()
      @_properties.physics.enabled.setValue false

      @_properties.physics.enabled.onUpdate = (enabled) =>
        return unless @_AJSActor

        if enabled
          @_AJSActor.enablePsyx()
        else
          @_AJSActor.disablePsyx()

      @_properties.physics.addProperty "mass", @_properties.physics.mass
      @_properties.physics.addProperty "elasticity", @_properties.physics.elasticity
      @_properties.physics.addProperty "friction", @_properties.physics.friction
      @_properties.physics.addProperty "enabled", @_properties.physics.enabled

    ###
    # Get the actor's name
    # @return [String] name
    ###
    getName: -> @name

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
        @_properties.rotation.getValue()
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

      colorRaw = @_properties.color.getValue()
      color = new AJSColor3 colorRaw.r, colorRaw.g, colorRaw.b

      {
        r: color.getR(float)
        g: color.getG(float)
        b: color.getB(float)
      }

    ###
    # Return actor physics
    #
    # @return [Object] physics properties
    ###
    getPsyX: ->

      {
        enabled: @_properties.physics.getProperty("enabled").getValue()
        mass: @_properties.physics.getProperty("mass").getValue()
        elasticity: @_properties.physics.getProperty("elasticity").getValue()
        friction: @_properties.physics.getProperty("friction").getValue()
      }

    ###
    # Get buffer entry
    #
    # @param [Number] time
    # @return [Object] entry prop buffer entry, may be undefined
    ###
    getBufferEntry: (time) -> @_propBuffer["#{Math.floor time}"]

    ###
    # Set the actor's name
    # @param [String] name
    ###
    setName: (_name) -> @name = _name

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

      @_properties.position.setValue x: x, y: y
      @updateInTime()

    ###
    # Set actor rotation
    #
    # @param [Number] angle
    ###
    setRotation: (angle) ->
      angle = Number (param.required angle).toFixed(@ACCURACY)

      @_properties.rotation.setValue angle
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

      @_properties.color.setValue r: r, g: g, b: b
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

      property = @_properties[property]
      return unless property

      if property.getType() == "composite"
        return unless property.getProperty(component).genAnimationOpts
        property.getProperty(component).genAnimationOpts anim, opts
      else
        property.genAnimationOpts anim, opts if property.genAnimationOpts

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
    # @param [Object] properties properties object to parse
    # @param [Method] cb callback to call with every property
    ###
    perProp: (properties, cb) ->
      for name, property of properties

        # Composite iterate over components
        if property.getType() == "composite"
          for name, component of property.getProperties()
            cb component, true

        # Call cb with property (non-composite)
        else
          cb property, false

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

      for pName, property of @_properties

        snapshot = {}

        if property.getType() == "composite"
          snapshot.components = {}

          for cName, cValue of property.getProperties()
            snapshot.components[cName] = value: cValue.getValue()

        else
          snapshot.value = property.getValue()

        unless isNaN snapshot.value
          snapshot.value = Number snapshot.value.toFixed @ACCURACY

        @_propSnapshot[pName] = snapshot

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
        next = @findNearestState next, right

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

          for cName, cValue of property.components
            update[cName] = cValue.value

          @_properties[name].setValue update

        else
          @_properties[name].setValue property.value

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

      # Ensure cursor is within our lifetime
      return if cursor < @lifetimeStart_ms or cursor > @lifetimeEnd_ms

      # If we don't have a saved state at the current cursor position, find the
      # nearest and calculate our time offset. Worst case, the closest state
      # is our birth
      nearest = cursor
      if @_propBuffer[String(cursor)] == undefined
        nearest = @findNearestState cursor

      # Apply intermediary states (up to ourselves if we have a state)
      @_applyKnownState nearest

      # Return if we have nothing else to do (cursor is at a known state)
      return if nearest == cursor

      # Next, bail if there are no states to the right of ourselves
      if @findNearestState(cursor, true) == -1
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
      while (from = @findNearestState(from, true)) != -1
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
        if _prop.getType() == "composite"

          val = {}

          for c of _prop.getProperties()
            _start = anim[v.name].components[c]._start.x

            # Ensure animation starts before us
            if _start <= cursor
              t = (cursor - _start) / (v.end - _start)

              val[c] = (anim[v.name].components[c].eval t).y

          # Store new value
          @_properties[v.name].setValue val

        else
          _start = anim[v.name]._start.x

          if _start <= cursor
            t = (cursor - _start) / (v.end - _start)

            val = (anim[v.name].eval t).y

            # Store new value
            @_properties[v.name].setValue val

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

        # Compare snapshot with live property
        if @_properties[name].getType() == "composite"

          # Iterate over components to detect modification
          for cName, cValue of @_properties[name].getProperties()
            if snapshot.components[cName].value != cValue.getValue()
              modified = true

        else if snapshot.value != @_properties[name].getValue()
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
        left = @findNearestState time, false, p

      left = 0 if left = -1

      # Check if we are in the middle of an animation ourselves. If so,
      # split it
      animCheck = @findNearestState time, true, p

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
          trueStart = @findNearestState @_lastTemporalState, false, p

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
    # Get animation by time
    #
    # @param [Number] time
    # @return [Object] animation
    ###
    getAnimation: (time) -> @_animations[time]

    ###
    # Fetch time of preceding animation, null if there is none
    #
    # @param [Number] source search start time
    # @return [Number] time
    ###
    findPrecedingAnimation: (source) ->
      times = _.keys @_animations
      times.sort (a, b) -> a - b

      index = _.findIndex times, (t) -> Number(t) == source

      if index > 0
        times[index - 1]
      else
        null

    ###
    # Fetch time of preceding animation, null if there is none
    #
    # @param [Number] source search start time
    # @return [Number] time
    ###
    findSucceedingAnimation: (source) ->
      times = _.keys @_animations
      times.sort (a, b) -> a - b

      index = _.findIndex times, (t) -> Number(t) == source

      if index > -1 and index < times.length - 1
        times[index + 1]
      else
        null

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
    findNearestState: (start, right, prop) ->
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
    # Move the keyframe at the specified time and of the specified property to
    # the target time.
    #
    # NOTE: This does not check the validity of the transformation! Make SURE
    #       the keyframe can be legally moved to the target time! It must not
    #       cross over any other keyframes belonging to the same property.
    #
    # @param [String] property
    # @param [Number] source source time
    # @param [Number] destination target time
    ###
    transplantKeyframe: (property, source, destination) ->
      source = Math.floor source
      destination = Math.floor destination

      return if source == destination

      # Move prop buffer entry first
      srcPBEntry = @_propBuffer[source][property]

      @_propBuffer[destination] = {} unless @_propBuffer[destination]
      @_propBuffer[destination][property] = srcPBEntry

      delete @_propBuffer[source][property]

      if _.keys(@_propBuffer[source]).length == 0
        delete @_propBuffer[source]

      # Now move animation, update affected surrounding animations
      srcAnimation = @_animations[source]

      # Update any animation to the right of us
      succeedingAnim = @findSucceedingAnimation source

      if succeedingAnim != null
        @mutatePropertyAnimation @_animations[succeedingAnim][property], (a) ->
          a.setStartTime destination

      # Finally, update our own animation
      @mutatePropertyAnimation @_animations[source][property], (a) ->
        a.setEndTime destination

      @_animations[destination] = @_animations[source]
      delete @_animations[source]

    ###
    # Runs the callback for each animation object found on the property
    # animation; runs it for each component for composites (useful). The
    # callback is given each animation object (Bezier)
    #
    # @param [Object] animationSet animation property entry
    # @param [Method] cb
    ###
    mutatePropertyAnimation: (animationSet, cb) ->
      if animationSet.components
        _.each _.values(animationSet.components), (animation) -> cb animation
      else
        cb animationSet

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
          needsSerialization = _.find(delta, (d) -> d == name) != undefined

        if needsSerialization
          props[name] = {}

          if value.getType() == "composite"
            props[name].components = {}

            for cName, cValue of value.getProperties()
              props[name].components[cName] = value: cValue.getValue()

          else
            props[name].value = value.getValue()

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
    # Dump actor into JSON representation
    #
    # @return [String] actorJSON
    ###
    serialize: ->
      data = super()

      data.propBuffer = @_propBuffer
      data.birth = @lifetimeStart_ms
      data.death = @lifetimeEnd_ms
      data.animations = {}

      for time, properties of @_animations
        animationSet = {}

        for property, propAnimation of properties

          if propAnimation.components
            animationData = components: {}

            for component, animation of propAnimation.components
              animationData.components[component] = animation.serialize()

          else
            animationData = propAnimation.serialize()

          animationSet[property] = animationData

        data.animations[time] = animationSet

      data

    ###
    # Loads properties, animations, and a prop buffer from a saved state
    #
    # @param [Object] state saved state object
    ###
    deserialize: (state) ->

      # Load basic properties
      super state

      # Load everything else
      @_propBuffer = state.propBuffer

      @_animations = {}
      for time, properties of state.animations
        animationSet = {}

        for property, propAnimation of properties

          if propAnimation.components
            animationData = components: {}

            for component, animation of propAnimation.components
              animationData.components[component] = Bezier.deserialize animation

          else
            animationData = Bezier.deserialize propAnimation

          animationSet[property] = animationData

        @_animations[time] = animationSet

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
