define (require) ->

  config = require "config"
  param = require "util/param"

  ID = require "util/id"
  AUtilLog = require "util/log"

  Storage = require "storage"

  ParticleSystem = require "handles/particle_system"

  Widget = require "widgets/widget"
  ContextMenu = require "widgets/context_menu"
  TemplateWorkspaceCanvasContainer = require "templates/workspace/canvas_container"

  Dragger = require "util/dragger"

  # Workspace widget
  class Workspace extends Widget

    ###
    # @type [BaseActor]
    ###
    @_selectedActorID: null

    ###
    # Retrieves the currently selected actor, if any
    # @return [Id] actorId
    ###
    @getSelectedActorID: -> @_selectedActorID

    ###
    # Creates a new workspace if one does not already exist
    #
    # @param [UIManager] ui
    ###
    constructor: (@ui, options) ->
      return unless @enforceSingleton()
      param.required @ui

      super @ui,
        id: ID.prefID("workspace")
        parent: "section.main"
        classes: ["workspace"]
        prepend: true

      ###
      # Keep track of spawned handle actor objects
      # @type [Array<Handle>]
      ###
      @actorObjects = []

      ###
      # @type [Array<ParticleSystem>]
      ###
      @_particleSystems = []

      # Starting phone size is 800x480
      @_pWidth = 800
      @_pHeight = 480
      @_pScale = 1
      @_pOrientation = "land"

      # Picking resources
      @_pickBuffer = null
      @_pickTexture = null
      @_pickInProgress = false
      @_pickQueue = []

    postInit: ->
      ## AJS overrides setting the renderer mode...
      #mode = Storage.get("are.renderer.mode")
      #mode = ARERenderer.rendererMode if mode == null
      #ARERenderer.rendererMode = Number(mode)

      # The canvas is fullscreen, minus the mainbar
      sectionElement = $("section.main")
      @_canvasWidth  = sectionElement.width()
      @_canvasHeight = sectionElement.height()

      # Create an ARE instance on ourselves
      AUtilLog.info "Initializing AJS..."
      AJS.init =>

        @_are = AdefyRE.Engine()._engine

        # AdefyRE.Engine().setLogLevel 4

        @_engineInit()
        @_applyCanvasSizeUpdate()

      , @_canvasWidth, @_canvasHeight, config.id.are_canvas

    ###
    # Checks if a workspace has already been created, and returns false if one
    # has. Otherwise, sets a flag preventing future calls from returning true
    ###
    enforceSingleton: ->
      if Workspace.__exists
        AUtilLog.warn "A workspace already exists, refusing to initialize!"
        return false

      Workspace.__exists = true

    ###
    # Internal list of workspace actor objects (Handles)
    #
    # @return [Array<Handle>] actors
    ###
    getActors: -> @actorObjects

    ###
    # @return [Array<ParticleSystem>] particle_systems
    ###
    getParticleSystems: -> @_particleSystems

    ###
    # Get ARE instance
    #
    # @return [AREEngine] are
    ###
    getARE: -> @_are

    ###
    # Retrieve canvas width
    #
    # @return [Number] width canvas width
    ###
    getCanvasWidth: -> @_canvasWidth

    ###
    # Retrieve canvas height
    #
    # @return [Number] height canvas height
    ###
    getCanvasHeight: -> @_canvasHeight

    ###
    # Get phone width
    #
    # @return [Number] width
    ###
    getPhoneWidth: -> @_pWidth

    ###
    # Get phone height
    #
    # @return [Number] height
    ###
    getPhoneHeight: -> @_pHeight

    ###
    # Get phone scale
    #
    # @return [Number] scale
    ###
    getPhoneScale: -> @_pScale

    ###
    # Returns the currently selected actor's id
    # @return [Id] actorId
    ###
    getSelectedActorID: -> Workspace.getSelectedActorID()

    ###
    # Sets the selectedActor instance
    # @param [Id] actorId
    # @return [self]
    ###
    setSelectedActor: (actor) ->
      Workspace._selectedActorID = actor.getID()

    ###
    # Loads textures into ARE
    # @param [Array<Texture>] textures
    # @return [self]
    ###
    loadTextures: (textures) ->
      @loadTexture texture for texture in textures
      @

    ###
    # @param [Texture] texture
    # @return [self]
    ###
    loadTexture: (texture) ->
      return AUtilLog.error "ARE not loaded, cannot load texture" unless @_are

      AdefyRE.Engine().loadTexture texture.getUID(), texture.getURL(), false, =>
        AUtilLog.info "Texture(uid: #{texture.getUID()}) loaded"

        @ui.pushEvent "load.texture", texture: texture

        # Refresh any actors that already have the texture assigned
        for actor in @actorObjects
          if actor.getTextureUID() == texture.getUID()
            actor.setTexture texture

      @

    ###
    # Manually register an actor
    #
    # @param [BaseActor] handle
    ###
    addActor: (handle) ->
      param.required handle

      @actorObjects.push handle
      @ui.pushEvent "workspace.add.actor", actor: handle
      @

    #removeActor: (handle) ->

    ###
    # Add a new Particle System to the list
    # @return [self]
    ###
    addParticleSystem: (ps) ->
      @_particleSystems.push ps
      @ui.pushEvent "workspace.add.particle_system", ps: ps
      # ParticleSystems are still a kind of actor.
      @addActor ps
      @

    ###
    # Converts document-relative coordinates to ARE coordinates
    # NOTE: This does not currently take into account any camera transformation!
    #
    # @param [Number] x x coordinate
    # @param [Number] y y coordinate
    ###
    domToGL: (x, y) ->

      # Bail
      if @_are == undefined
        AUtilLog.warn "Can't convert coords, are not up!"
        return null

      canvasTop = $("#{@getSel()} canvas").offset().top
      canvasLeft = $("#{@getSel()} canvas").offset().left

      # TODO: Take into account camera coords

      {
        x: x - canvasLeft
        y: y - canvasTop
      }

    ###
    # Generate workspace right-click ctx data object
    #
    # @param [Number] x x coordinate of click
    # @param [Number] y y coordinate of click
    # @return [Object] options
    ###
    getWorkspaceCtxMenu: (x, y) ->
      functions =
        newActor:
          name: "New Actor +"
          cb: =>
            new ContextMenu @ui,
              x: x, y: y, properties: @getNewActorCtxMenu(x, y)

      if config.use.particle_system
        functions.newParticleSystem =
          name: "New Particle Sys."
          cb: =>
            ps = new ParticleSystem @ui

            pos = @domToGL x, y
            pos.x += ARERenderer.camPos.x
            pos.y += ARERenderer.camPos.y
            ps.setPosition pos.x, pos.y

            @addParticleSystem ps

      if @ui.editor.clipboard && @ui.editor.clipboard.type == "actor"
        functions.paste =
          name: "Paste"
          cb: =>

            pos = @domToGL(x, y)
            pos.x += ARERenderer.camPos.x
            pos.y += ARERenderer.camPos.y

            newActor = @ui.editor.clipboard.data.duplicate()
            newActor.setPosition pos.x, pos.y
            newActor.setName(newActor.getName() + " copy")

            @addActor newActor

      {
        name: "Workspace"
        functions: functions
      }

    ###
    # Generate the new actor menu options object, opened through the workspace
    # context menu.
    #
    # @param [Number] x x coordinate of click
    # @param [Number] y y coordinate of click
    # @return [Object] options
    ###
    getNewActorCtxMenu: (x, y) ->
      time = @ui.timeline.getCursorTime()
      pos = @domToGL(x, y)
      pos.x += ARERenderer.camPos.x
      pos.y += ARERenderer.camPos.y

      {
        name: "New Actor"
        functions:
          rectActor:
            name: "Rectangle Actor"
            cb: => @addActor new RectangleActor @ui, time, 100, 100, pos.x, pos.y
          polyActor:
            name: "Polygon Actor"
            cb: => @addActor new PolygonActor @ui, time, 5, 60, pos.x, pos.y
          trinActor:
            name: "Triangle Actor"
            cb: => @addActor new TriangleActor @ui, time, 100, 100, pos.x, pos.y
      }


    ###
    # Translate the pick values into an ID and fetch the associated actor
    #
    # @param [Number] r
    # @param [Number] g
    # @param [Number] b optional
    # @return [Handle] actor
    ###
    getActorFromPick: (r, g, b) ->
      if b
        return unless @isValidPick r, g, b

      id = r + (g * 255)
      _.find @actorObjects, (h) -> h.getActorId() == id

    ###
    # Checks if we've hit an actor object
    ###
    isValidPick: (r, g, b) ->
      b == 248

    ###
    # Helper to pick an actor at the specified coordinates. The callback is
    # only called if an actor is found.
    #
    # @param [Number] x
    # @param [Number] y
    # @param [Method] callback
    # @param [Method] noActorCallback
    ###
    pickActor: (x, y, cb, noActorCb) ->
      noActorCb = param.optional noActorCb, ->

      @performPick @domToGL(x, y), (r, g, b) =>
        return noActorCb() unless @isValidPick r, g, b

        handle = @getActorFromPick r, g, b

        if handle
          cb handle
        else
          noActorCb()

    ###
    # Bind a contextmenu listener
    ###
    _bindContextClick: ->
      $(document).on "contextmenu", ".workspace canvas", (e) =>
        return if @dragger.isDragging()

        x = e.pageX
        y = e.pageY

        @performPick @domToGL(x, y), (r, g, b) =>
          gotActor = @isValidPick r, g, b

          if gotActor
            actor = @getActorFromPick r, g, b
            if actor
              unless _.isEmpty actor.getContextProperties()
                @dragger.forceDragEnd()
                new ContextMenu @ui,
                  x: x , y: y, properties: actor.getContextProperties()
          else
            new ContextMenu @ui,
              x: x , y: y, properties: @getWorkspaceCtxMenu(x, y)

        e.preventDefault()
        false

    ###
    # Register listeners
    ###
    _regListeners: ->

      @_bindContextClick()

      $(document).on "mousemove", ".workspace canvas", (e) =>
        pos = @domToGL(e.originalEvent.pageX, e.originalEvent.pageY)

        pos.x += ARERenderer.camPos.x
        pos.y += ARERenderer.camPos.y

        $(".workspace .cursor-position").text "x: #{pos.x}, y: #{pos.y}"

      ###
      # Workspace drag
      ###
      $(document).mousemove (e) =>
        return unless @_workspaceDrag

        x = @_workspaceDrag.x
        y = @_workspaceDrag.y
        ARERenderer.camPos.x += x - e.pageX
        ARERenderer.camPos.y += y - e.pageY

        @_workspaceDrag =
          x: e.pageX
          y: e.pageY

      $(document).mouseup (e) =>
        return unless @_workspaceDrag

        @_workspaceDrag = null

      $(document).on "mousedown", ".workspace canvas", (e) =>
        if e.shiftKey && !e.ctrlKey && !@_workspaceDrag
          @_workspaceDrag =
            x: e.pageX
            y: e.pageY

      ###
      # Setup texture drops
      ###
      $(@_sel).on "dragover", (e) ->
        if _.contains e.originalEvent.dataTransfer.types, "image/texture"
          e.preventDefault()
          false

      $(@_sel).on "drop", (e) =>
        texID = e.originalEvent.dataTransfer.getData "image/texture"
        texture = _.find @ui.editor.project.textures, (t) -> t.getID() == texID

        @pickActor e.originalEvent.pageX, e.originalEvent.pageY, (actor) ->
          actor.setTexture texture
        , =>
          time = @ui.timeline.getCursorTime()
          pos = @domToGL(e.originalEvent.pageX, e.originalEvent.pageY)

          pos.x += ARERenderer.camPos.x
          pos.y += ARERenderer.camPos.y

          texSize = ARERenderer.getTextureSize texture.getUID()
          w = texSize.w
          h = texSize.h

          actor = new RectangleActor @ui, time, w, h, pos.x, pos.y
          actor.setTexture texture
          @addActor actor

        e.preventDefault()
        false

    ###
    # Initializes dragging settings and attaches listeners
    ###
    _setupActorDragging: ->

      toggleActorPhysics = (d, handle) ->

        if handle.getActor().hasPsyx()
          handle.getActor().disablePsyx()
          d.setUserDataValue "hasPhysics", true
        else
          d.setUserDataValue "hasPhysics", false

      ###
      # Rotate Actor
      ###
      @draggerRotate = new Dragger ".workspace canvas"

      @draggerRotate.setCheckDrag (e) =>
        !e.shiftKey && e.ctrlKey

      @draggerRotate.setOnDragStart (d) =>
        @performPick @domToGL(d.getStart().x, d.getStart().y), (r, g, b) =>
          return d.forceDragEnd() unless @isValidPick r, g, b

          handle = @getActorFromPick r, g, b
          return d.forceDragEnd() unless handle

          d.setTarget handle
          d.setUserData
            updateProperties: true
            original: handle.getRotation()

          toggleActorPhysics d, handle

          document.body.style.cursor = "pointer"

      @draggerRotate.setOnDragEnd (d) =>
        document.body.style.cursor = "auto"

        if d.getUserData()
          handle = d.getTarget()
          handle.getActor().enablePsyx() if d.getUserData().hasPhysics

      @draggerRotate.setOnDrag (d, deltaX, deltaY) =>

        # Delay the drag untill we finish our pick
        if d.getUserData() and d.getUserData().original != null
          org = d.getUserData().original
          n = (org + deltaX + deltaY) % 360
          n = 360+n if n < 0

          d.getTarget().setRotation n

          @ui.pushEvent "selected.actor.update", actor: d.getTarget()

      ###
      # Move actor
      ###
      @dragger = new Dragger ".workspace canvas"

      @dragger.setCheckDrag (e) =>
        !e.shiftKey && !e.ctrlKey

      @dragger.setOnDragStart (d) =>
        @performPick @domToGL(d.getStart().x, d.getStart().y), (r, g, b) =>
          return d.forceDragEnd() unless @isValidPick r, g, b

          handle = @getActorFromPick r, g, b
          return d.forceDragEnd() unless handle

          d.setTarget handle
          d.setUserData
            updateProperties: true
            original: handle.getPosition()

          toggleActorPhysics d, handle

          document.body.style.cursor = "pointer"

      @dragger.setOnDragEnd (d) =>
        document.body.style.cursor = "auto"

        if d.getUserData()
          handle = d.getTarget()
          handle.getActor().enablePsyx() if d.getUserData().hasPhysics

      @dragger.setOnDrag (d, deltaX, deltaY) =>

        # Delay the drag untill we finish our pick
        if d.getUserData() and d.getUserData().original
          newX = d.getUserData().original.x + deltaX
          newY = d.getUserData().original.y + deltaY

          d.getTarget().setPosition newX, newY
          @ui.pushEvent "selected.actor.update", actor: d.getTarget()

      # Actor picking!
      # NOTE: This should only be allowed when the scene is not being animated!
      $(".workspace canvas").click (e) =>
        return if @dragger.isDragging()
        return if e.shiftKey

        @performPick @domToGL(e.pageX, e.pageY), (r, g, b) =>

          unless @isValidPick r, g, b
            data = $("body").data("default-properties")
            data.clear() if data
            return

          actor = @getActorFromPick r, g, b
          if actor
            @setSelectedActor actor
            @ui.pushEvent "workspace.selected.actor", actor: actor

    ###
    # @private
    # Called by AREEngine as soon as it's up and running, we continue our own
    # init from here.
    ###
    _engineInit: ->
      AUtilLog.info "ARE instance up, initializing workspace"

      @_are.setClearColor 240, 240, 240

      @_regListeners()

      @_setupActorDragging()

      # Start rendering
      @_are.startRendering()

    ###
    # @private
    # Update the canvas status, and alter the width of the canvas container
    # This should be called either after instantiation, or after a canvas
    # resize
    ###
    _applyCanvasSizeUpdate: ->

      # Resize canvas container
      $("##{config.id.are_canvas}").css
        height: "#{@_canvasHeight}px"
        width: "#{@_canvasWidth}px"

      # Rebuild our picking resources
      @_buildPickBuffer()

    ###
    # Resets us completely, triggering the timeline death handler of every
    # actor, and removing them from both us and the timeline
    ###
    reset: ->

      for o in @actorObjects
        @ui.pushEvent "workspace.remove.actor", actor: o
        o.timelineDeath()
        o.delete()

      @actorObjects.length = 0

      AUtilLog.info "Workspace(id: #{@_id}) reset"

      @

    ###
    # Any objects that need to tell us about their death have to do so by calling
    # this method and passing themselves in.
    #
    # @param [Object] obj dying object
    ###
    notifyDemise: (obj) ->

      # We keep track of actors internally, splice them out of our array
      if obj.constructor.name.indexOf("Actor") != -1
        for o, i in @actorObjects
          if o.getID() == obj.getID()
            @ui.pushEvent "workspace.remove.actor", actor: o
            @actorObjects.splice i, 1
            return

    ###
    # @param [String]
    ###
    renderStub: ->
      # Inject our canvas container, along with its status bar
      # Although we currently don't add anything else to the container besides
      # the canvas itself, it might prove useful in the future.
      super content: TemplateWorkspaceCanvasContainer
        id: config.id.are_canvas

    ###
    # @return [self]
    ###
    refresh: ->
      @

    ###
    # @private
    # Builds the framebuffer and texture needed to preform picking, deleting
    # them if they already exist. This needs to be called whenever AREs' canvas
    # is resized
    #
    # http://learningwebgl.com/blog/?p=1786
    ###
    _buildPickBuffer: ->
      unless @_are.getActiveRendererMode() == ARERenderer.RENDERER_MODE_WGL
        return false

      gl = @_are.getGL()

      # Delete them if they already exist
      if @_pickTexture != null then gl.deleteTexture @_pickTexture
      if @_pickBuffer != null then gl.deleteFramebuffer @_pickBuffer

      # Gogo
      @_pickBuffer = gl.createFramebuffer()
      @_pickTexture = gl.createTexture()

      _w = @_are.getWidth()
      _h = @_are.getHeight()

      gl.bindFramebuffer gl.FRAMEBUFFER, @_pickBuffer
      gl.bindTexture gl.TEXTURE_2D, @_pickTexture

      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER \
        , gl.LINEAR_MIPMAP_NEAREST

      # Framebuffer is 512x512
      gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, _w, _h, 0, gl.RGBA \
        , gl.UNSIGNED_BYTE, null

      # Set up a depth buffer, bind it and whatnot
      _renderBuff = gl.createRenderbuffer()
      gl.bindRenderbuffer gl.RENDERBUFFER, _renderBuff
      gl.renderbufferStorage gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, _w, _h

      gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 \
        , gl.TEXTURE_2D, @_pickTexture, _renderBuff

      gl.framebufferRenderbuffer gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT \
        , gl.RENDERBUFFER, _renderBuff

      # Cleanup
      gl.bindTexture gl.TEXTURE_2D, null
      gl.bindRenderbuffer gl.RENDERBUFFER, null
      gl.bindFramebuffer gl.FRAMEBUFFER, null

    ###
    # @private
    # Helper function to perform a pick at the specified canvas coordinates
    #
    # @param [Object] position hash with x, y values
    # @param [Method] cb callback to call afterwards, passing r/g/b
    ###
    performPick: (pos, cb) ->

      # We can only perform one pick at a time, so queue 'er up if needed
      if @_pickInProgress
        return @_pickQueue.push pos: pos, cb: cb

      @_pickInProgress = true

      # Request a pick render from ARE, continue once we get it
      switch @_are.getActiveRendererMode()
        when ARERenderer.RENDERER_MODE_NULL
          AUtilLog.warn "You can't perform a pick with a null renderer"
        when ARERenderer.RENDERER_MODE_CANVAS
          @_are.requestPickingRenderCanvas
            x: pos.x
            y: pos.y
            width: 1
            height: 1
          , (imageBuffer) =>
            pixels = imageBuffer.data
            color = pixels

            cb color[0], color[1], color[2]

            @_pickInProgress = false

        when ARERenderer.RENDERER_MODE_WGL
          @_are.requestPickingRenderWGL @_pickBuffer, =>

            pick = new Uint8Array 4

            pos.y = @_are.getHeight() - pos.y

            gl = @_are.getGL()
            gl.bindFramebuffer gl.FRAMEBUFFER, @_pickBuffer
            gl.readPixels pos.x, pos.y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pick
            gl.bindFramebuffer gl.FRAMEBUFFER, null

            cb pick[0], pick[1], pick[2]

            @_pickInProgress = false

      # Start the next pick if one is queued (after a timeout)
      if @_pickQueue.length > 0
        setTimeout =>
          obj = @_pickQueue[0]
          @_pickQueue.splice 0, 1
          @performPick obj.pos, obj.cb if obj
        , 0

    ###
    # Resizes the display outline
    ###
    updateOutline: ->

      if @_pOrientation == "port"
        height = @_pWidth
        width = @_pHeight
      else
        height = @_pHeight
        width = @_pWidth

      # Center
      _t = 35
      _l = (($(document).width() / 2) - 2) - (width / 2)

      $("#awcc-outline").css
        top: _t
        left: _l
        width: width
        height: height

      # Update text
      $("#awcc-outline-text").css
        top: _t - 16
        left: _l

      $("#awcc-outline-text").text "#{width}x#{height}"

    ###
    # Takes other widgets into account, and sets the height accordingly. Also
    # centers the phone outline
    #
    # Note that this does NOT resize the canvas
    ###
    onResize: ->
      # workspace now inherits its height from the section.main

    ###
    # Dumps the current workspace state
    # @return [Object] data
    ###
    dump: ->
      particleSystems = _.map @getParticleSystems(), (ps) -> ps.dump()
      actors = _.map @getActors(), (actor) -> actor.dump()
      actors = _.without actors, (actor) ->
        actor.handleType == "ParticleSystem"

      _.extend super(),
        workspaceVersion: "1.3.0"
        camPos:                                                        # v1.2.0
          x: ARERenderer.camPos.x
          y: ARERenderer.camPos.y
        actors: actors                                                 # v1.1.0
        particleSystems: particleSystems                               # v1.3.0

    ###
    # Loads the a workspace data state
    # @param [Object] data
    ###
    load: (data) ->
      super data

      if (data.workspaceVersion >= "1.2.0") || \
       ((data.dumpVersion == "1.0.0") && (data.version >= "1.2.0"))
        ARERenderer.camPos.x = data.camPos.x
        ARERenderer.camPos.y = data.camPos.y

      if data.workspaceVersion >= "1.3.0"
        for psData in data.particleSystems
          @addParticleSystem ParticleSystem.load @ui, psData

      # data.workspaceVersion >= "1.1.0"
      for actor in data.actors
        continue if actor.handleType == "ParticleSystem"
        handleKlass = window[actor.type]
        if handleKlass
          newActor = handleKlass.load @ui, actor
          @addActor newActor
        else
          AUtilLog.warn "No such handle class #{actor.type}"

      @ui.timeline.updateAllActorsInTime()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      switch type
        when "timeline.selected.actor"
          @setSelectedActor params.actor
