define (require) ->
  config = require "config"
  AUtilLog = require "util/log"
  param = require "util/param"

  PolygonActor = require "handles/actors/polygon"
  TriangleActor = require "handles/actors/triangle"
  RectangleActor = require "handles/actors/rectangle"

  UIManager = require "ui"

  Notification = require "widgets/notification"
  Modal = require "widgets/modal"
  
  Bezier = require "widgets/timeline/bezier"

  class Editor

    ###
    # Editor version number
    # @type [String]
    ###
    @version: "0.0.1"

    ###
    # @type [Editor]
    ###
    @__instance: null

    ###
    # Editor execution starts here. We spawn all other objects ourselves. If a
    # selector is not supplied, we go with #editor
    #
    # @param [String] sel container selector, created if non-existent
    ###
    constructor: (sel) ->

      # We can't run properly in Opera, as it does not let us override the
      # right-click context menu. Notify the user
      _agent = navigator.userAgent
      if _agent.search("Opera") != -1 || _agent.search("OPR") != -1
        alert "Opera does not fully support our editor, please use Chrome or FF!"

      # Array of widgets to be managed internally
      @widgets = []

      $(document).ready => @onDocumentReady()

      Editor.__instance = this

    onDocumentReady: ->
      headSelector = "#{config.selector} header"
      bodySelector = "#{config.selector} section#main"
      footSelector = "#{config.selector} footer"

      @ui = new UIManager

      ##
      # First, trigger onResize to initialize all the widgets/elements
      # Second, register the resize callback to the window
      # Third, call onResize again:
      #   For some reason, it has to be called a second time for things to settle
      #   properly (I'm looking at you Sidebar), so call it again
      @onResize()
      $(window).resize => @onResize()
      setTimeout =>
        @onResize()
      , 10

      AUtilLog.info "Adefy Editor created id(#{config.selector})"

    ###
    # Creates the editor toolbox
    # I don't believe this is used anymore/yet
    # @param [CSSSelector] selector
    # @return [Sidebar]
    ###
    createToolbox: (sidebar) ->
      return

      # Add some items to the left sidebar
      primGroup = new SidebarObjectGroup "Primitives", sidebar
      rectPrimitive = primGroup.createItem "Rectangle"
      ngonPrimitive = primGroup.createItem "Polgyon"
      triPrimitive = primGroup.createItem "Triangle"

      rectPrimitive.icon = "img/icon_rectangle.png"
      ngonPrimitive.icon = "img/icon_hexagon.png"
      triPrimitive.icon = "img/icon_triangle.png"

      rectPrimitive.dropped = (target, x, y) ->
        param.required target
        param.required x
        param.required y

        if target != "workspace" then return null

        new RectangleActor Timeline.getMe().getCursorTime(), 100, 100, x, y

      ngonPrimitive.dropped = (target, x, y) ->
        param.required target
        param.required x
        param.required y

        if target != "workspace" then return null

        new PolygonActor Timeline.getMe().getCursorTime(), 5, 100, x, y

      triPrimitive.dropped = (target, x, y) ->
        param.required target
        param.required x
        param.required y

        if target != "workspace" then return null

        new TriangleActor Timeline.getMe().getCursorTime(), 20, 30, x, y

      primGroup

    ###
    # This function gets called immediately upon creation, and whenever
    # our parent element is resized. Other elements register listeners are to be
    # called within it
    ###
    onResize: ->
      doc = $(window)
      header = $("#{config.selector} header")
      footer = $("#{config.selector} footer")
      $("#{config.selector} .main").height doc.height() - header.height() - footer.height()

      for w in @widgets
        if w.onResize != undefined then w.onResize()

    ###
    # Clears the workspace, creating a new ad
    ###
    newAd: ->

      # Trigger a workspace reset
      @ui.workspace.reset()

    ###
    # Serialize all ad data in the workspace to send to the server
    #
    # @return [String] data
    # @private
    ###
    _serialize: ->

      data = {}

      # Cursor position
      data.cursorPosition = Timeline.getMe().getCursorTime()

      # Actors!
      data.actors = []

      # Add the data we need to fully re-build each actor
      for a in Workspace.getMe().actorObjects
        _actor = {}

        # Figure out type, save relevant information
        if a instanceof TriangleActor
          _actor.type = "TriangleActor"
          _actor.base = a.getBase()
          _actor.height = a.getHeight()
        else if a instanceof RectangleActor
          _actor.type = "RectangleActor"
          _actor.width = a.getWidth()
          _actor.height = a.getHeight()
        else if a instanceof PolygonActor
          _actor.type = "PolygonActor"
          _actor.radius = a.getRadius()
          _actor.sides = a.getSides()
        else
          AUtilLog.warn "Actor of unknown type, not saving: #{a.name}"

        # Continue saving
        if _actor.type != undefined

          # Saved elements are self-explanatory
          _actor.name = a.name
          _actor.timebarColor = a.timebarColor
          _actor.lifetimeStart = a.lifetimeStart
          _actor.lifetimeEnd = a.lifetimeEnd
          _actor.propBuffer = a._propBuffer
          _actor.lastTemporalState = a._lastTemporalState
          _actor.x = a.getPosition().x
          _actor.y = a.getPosition().y
          _actor.r = a.getRotation()
          _actor.color = a.getColor()

          # Save the information we need to re-create all animations
          _actor.animations = {}

          for anim, anim_val of a._animations
            _actor.animations[anim] = {}

            for prop, prop_val of anim_val

              _anim = {}

              # Check for components
              if prop_val.components != undefined
                _anim.components = {}
                for c, c_val of prop_val.components
                  _anim.components[c] = @_serializeAnimation c_val
              else _anim = @_serializeAnimation prop_val

              _actor.animations[anim][prop] = _anim

          data.actors.push _actor

      JSON.stringify data

    ###
    # Serialize an animation (expects an existing bezier func)
    #
    # @param [Bezier] anim
    # @return [Object] serialized
    # @private
    ###
    _serializeAnimation: (anim) ->

      ret = {}
      ret.x1 = anim._start.x
      ret.y1 = anim._start.y
      ret.x2 = anim._end.x
      ret.y2 = anim._end.y

      if anim._control[0] != undefined
        ret.cp1x = anim._control[0].x
        ret.cp1y = anim._control[0].y

      if anim._control[1] != undefined
        ret.cp2x = anim._control[1].x
        ret.cp2y = anim._control[1].y

      ret

    # Deserialize an animation that's been serialized by _serializeAnimation.
    # Returns a built bezier function
    #
    # @param [Object] anim
    # @return [Bezier] bezier
    # @private
    _deserializeAnimation: (anim) ->

      _start =
        x: anim.x1
        y: anim.y1

      _end =
        x: anim.x2
        y: anim.y2

      _degree = 0

      if anim.cp1x != undefined and anim.cp1y != undefined
        _control = []
        _control.push
          x: anim.cp1x
          y: anim.cp1y
        _degree = 1

      if anim.cp2x != undefined and anim.cp2y != undefined
        _control.push
          x: anim.cp2x
          y: anim.cp2y
        _degree = 2

      new Bezier _start, _end, _degree, _control, false

    # Take JSON from the server, de-serialize and apply it.
    #
    # @param [String] data
    # @private
    _deserialize: (data) ->
      param.required data

      # Ad data is empty if it has just been created
      if data.length == 0 then return

      # Parse and validate structure
      data = JSON.parse data
      param.required data.cursorPosition
      param.required data.actors

      # Note that we clear the current state!
      Workspace.getMe().reset()

      # Set up actors
      for a in data.actors

        # Validate
        valid = a.type != undefined
        valid = valid && (a.name != undefined)
        valid = valid && (a.timebarColor != undefined)
        valid = valid && (a.lifetimeStart != undefined)
        valid = valid && (a.lifetimeEnd != undefined)
        valid = valid && (a.propBuffer != undefined)
        valid = valid && (a.lastTemporalState != undefined)
        valid = valid && (a.animations != undefined)
        valid = valid && (a.x != undefined)
        valid = valid && (a.y != undefined)
        valid = valid && (a.r != undefined)
        valid = valid && (a.color != undefined)

        # Apply the cursor position
        Timeline.getMe().setCursorTime data.cursorPosition

        # Throw an error, since this should never happen if the data is from a
        # valid source. Failing quietly is just saddening.
        if not valid then throw new Error "Data invalid: #{JSON.stringify a}"

        if a.type == "TriangleActor"
          handle = new TriangleActor a.lifetimeStart, a.base, a.height, a.x, a.y\
                                  , a.r, a.lifetimeEnd, true
        else if a.type == "RectangleActor"
          handle = new RectangleActor a.lifetimeStart, a.width, a.height, a.x, a.y\
                                   , a.r, a.lifetimeEnd, true
        else if a.type == "PolygonActor"
          handle = new PolygonActor  a.lifetimeStart, a.sides, a.radius, a.x, a.y\
                                  , a.r, a.lifetimeEnd, true
        else throw new Error "Invalid actor type, can't instantiate!"

        handle._propBuffer = a.propBuffer
        handle.setColor a.color.r, a.color.g, a.color.b

        # Set up animations
        for a, anim of a.animations
          handle._animations[a] = {}
          for p, prop of anim
            handle._animations[a][p] = {}

            if prop.components != undefined
              handle._animations[a][p].components = {}

              for c, comp of prop.components
                handle._animations[a][p].components[c] = \
                @_deserializeAnimation comp

            else handle._animations[a][p] = @_deserializeAnimation prop

        # Init, register, and update
        handle.postInit()
        Workspace.getMe().registerActor handle

      null

    # Saves us to the server
    save: ->
      data = @_serialize()

      $.post "/api/v1/editor/save?id=#{window.ad}&data=#{data}", (result) =>
        if result.error != undefined
          new Notification "Error saving: #{result.error}", "red"
        else
          new Notification "Saved", "green", 1000

    # Loads data from our backend, de-serializes it and applies state
    #
    # @param [String] id Server-recognizable ad id
    load: (id) ->
      param.required id

      $.post "/api/v1/editor/load?id=#{id}", (result) =>
        if result.error != undefined
          new Notification "Error loading: #{result.error}", "red"
          return

        @_deserialize result.ad

    # I really thought this would be sexier, expecting that we could simply
    # build a function that when executed recreates our ad, and stringify it.
    # Turns out we can't. Sadness. We can, we just can't easily set arguments.
    #
    # Sooooo, we literally build the resultant ad line-by-line. Not as bad as it
    # sounds.
    #
    # @return [String] export
    export: ->

      # Program text
      final = ""

      # Unique variable names
      __vname = "a"
      V = ->
        code = __vname.charCodeAt(__vname.length - 1)

        if code < 65 then code = 65
        else if code > 89 and code < 97 then code = 97
        else if code > 121 then code = 65
        else if code >= 97 or code >= 65 then code++

        if code == 65 then __vname += String.fromCharCode code
        else
          __vname = __vname.split ""
          __vname[__vname.length - 1] = "" + String.fromCharCode code
          __vname = __vname.join ""

        __vname

      ## Helpers
      # Assigns a value to a variable
      assign = (name, value) -> "var #{name} = #{value};"

      # Builds a function call, optional semicolon ending
      call = (name, args, _new, end) =>
        if _new == undefined then _new = false
        if args == undefined then args = []
        if end == undefined then end = false

        ret = ""
        if _new then ret += "new "
        ret += "#{name}("

        for a in args
          if typeof a == "string" then a = "\"#{a}\""
          else if typeof a == "object" then a = JSON.stringify a
          ret += "#{a}, "

        ret = ret.slice 0, -2
        if end then ret += ");" else ret += ")"

        ret

      # Start export with ARE init
      ex =  "AJS.init(function() {"

      # Set clear color
      # TODO: Enable clearColor animation
      clearC = @ui.workspace.getARE().getClearColor()

      _r = clearC.getR()
      _g = clearC.getG()
      _b = clearC.getB()

      ex += "AJS.setClearColor(#{_r}, #{_g}, #{_b});"

      # Grab phone dimensions to offset actors
      pWidth = @ui.workspace.getPhoneWidth()
      pHeight = @ui.workspace.getPhoneHeight()

      pOffX = (@ui.workspace.getCanvasWidth() - @ui.workspace.getPhoneWidth()) / 2
      pOffY = @ui.workspace.getCanvasHeight() - @ui.workspace.getPhoneHeight() - 35

      ##
      ## Actors
      ##
      for a in @ui.workspace.actorObjects

        type = ""
        actor = V()

        birthOpts = {}

        # We need to grab properties from birth, so grab the appropriate prop
        # buffer entry
        buff = a.getBufferEntry a.lifetimeStart

        pos = buff.position.components
        col = buff.color.components

        birthOpts.rotation = buff.rotation.value
        birthOpts.position = { x: pos.x.value - pOffX, y: pos.y.value - pOffY }
        birthOpts.color = { r: col.r.value, g: col.g.value, b: col.b.value }

        if a instanceof TriangleActor
          type = "AJSTriangle"
          birthOpts.base = buff.base.value
          birthOpts.height = buff.height.value

        else if a instanceof PolygonActor
          type = "AJSPolygon"
          birthOpts.radius = buff.radius.value
          birthOpts.segments = buff.sides.value

        else if a instanceof RectangleActor
          type = "AJSRectangle"
          birthOpts.w = buff.width.value
          birthOpts.h = buff.height.value

        # This shouldn't happen, but just in case, log, notify and skip
        if type.length == 0
          error = "Unrecognized actor, can't export: #{a._id}"
          AUtilLog.warn error
          new Notification error, "red"
        else

          # Build actor definition
          ex += assign actor, call(type, [birthOpts], true, false)

          # Now build animations
          anims = []
          props = []

          # Go through and build the args for our compile method
          for anim, anim_val of a._animations
            for prop, prop_val of anim_val
              if prop_val.components != undefined
                for c, c_val of prop_val.components

                  # Ensure actual value change
                  if c_val._end.y != c_val._start.y
                    anims.push c_val
                    props.push [prop, c]

              else
                # Ensure actual value change
                if prop_val._end.y != prop_val._start.y
                  anims.push prop_val
                  props.push prop

          ex += @_compileAnimationExport actor, a, anims, props

      # Finish init with width, and height
      ex += "}, #{pWidth}, #{pHeight});"

      # Send result to backend and receive a link
      $.post "/api/v1/editor/export?id=#{window.ad}&data=#{ex}", (result) ->
        if result.error != undefined
          new Notification "Error exporting: #{result.error}"
          return

        # Show a modal dialog offering to view, or download the export
        _html =  ""
        _html += "<a href=\"#{result.link}\" target=\"_blank\">View</a>"
        _html += " or "
        _html += "<a href=\"#{result.link}?download=yes\">Download</a>"
        new Modal title: "Exported", content: _html

    # @private
    # Note that we don't take start values into account. The initial state
    # is the only actual start value. After that, all animations start from
    # the current value.
    #
    # @param [String] actorName actor instance name
    # @param [Object] actorObj actor handle
    # @param [String] animations array of animation objects, one for each prop
    # @param [String] properties array of properties, single or composite
    #
    # @return [String] export AJS.animate() statement
    _compileAnimationExport: (actorName, actorObj, animations, properties) =>

      options = []

      pOffX = (@ui.workspace.getCanvasWidth() - @ui.workspace.getPhoneWidth()) / 2
      pOffY = @ui.workspace.getCanvasHeight() - @ui.workspace.getPhoneHeight() - 35

      # Build options
      for p, i in properties
        opts = {}
        anim = animations[i]

        # Extract property name
        if p instanceof Array then _pName = p[0] else _pName = p

        # Use the ARE animation iface map to figure out options
        animName = window.AdefyGLI.Animations().getAnimationName _pName

        opts.endVal = anim._end.y
        opts.controlPoints = anim._control
        opts.duration = anim._end.x - anim._start.x
        opts.property = p
        opts.start = anim._start.x

        if animName == "bezier"

          # If we are position, we need to offset ourselves to render from
          # the proper origin on phone screens
          if _pName == "position"
            if p[1] == "x" then opts.endVal -= pOffX
            else if p[1] == "y" then opts.endVal -= pOffY

          if opts.start == 0 then opts.start = -1

          # TODO: Take framerate into account
          # opts.fps = ...

        else if animName == "psyx"
          AUtilLog.warn "Psyx animation export not yet implemented"

        else if animName == "vert"
          AUtilLog.warn "Vert animation export not yet implemented"

        # Animation needs to be converted
        else if animName == false

          if p not instanceof Array then _p = [p] else _p = p
          opts = actorObj.genAnimationOpts _p[0], anim, opts, _p[1]

          if opts == null
            throw new Error "Property needs a genAnimationOpts method!"
            return

        options.push opts

      properties = JSON.stringify properties
      options = JSON.stringify options

      "AJS.animate(#{actorName}, #{properties}, #{options});"
