define (require) ->

  config = require "config"
  param = require "util/param"

  ID = require "util/id"
  AUtilLog = require "util/log"

  Storage = require "storage"
  Spawner = require "handles/spawner"
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

      super @ui,
        id: ID.prefID("workspace")
        parent: config.selector.content
        classes: ["workspace"]
        prepend: true

      ###
      # Keep track of spawned handle actor objects
      # @type [Array<Handle>]
      ###
      @actorObjects = []

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

    ###
    # @return [Workspace] self
    ###
    postInit: ->

      # The canvas is fullscreen, minus the mainbar
      @_canvasWidth  = $(config.selector.content).width()
      @_canvasHeight = $(config.selector.content).height()

      # Create an ARE instance on ourselves
      AUtilLog.info "Initializing ARE..."

      ARE.config.deps.physics.chipmunk = "/editor/components/chipmunk/cp.js"
      ARE.config.deps.physics.physics_worker = "/editor/components/adefyre/build/lib/physics/worker.js"

      @_are = window.AdefyRE.Engine().initialize @_canvasWidth, @_canvasHeight, =>

        @_are.getRenderer()._alwaysClearScreen = true

        @_engineInit()
        @_applyCanvasSizeUpdate()

      , config.debug.are_log_level, config.id.are_canvas

      @

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
    # Get the ARE Clear Color
    #
    # @return [Color]
    ###
    getClearColor: ->
      @_are.getClearColor()

    ###
    # Set the ARE Clear Color
    #
    # @param [Number] r
    # @param [Number] g
    # @param [Number] b
    # @return [self]
    ###
    setClearColor: (r, g, b) ->
      AUtilLog.debug "Setting ClearColor #{r} #{g} #{b}"
      @_are.setClearColor r, g, b
      @

    ###
    # Set a new selector actor
    #
    # @param [BaseActor] actor
    ###
    setSelectedActor: (actor) ->

      currentActor = _.find @actorObjects, (a) ->
        a.getID() == Workspace._selectedActorID

      currentActor.hideBoundingBox() if currentActor
      actor.showBoundingBox()

      Workspace._selectedActorID = actor.getID()

    ###
    # Loads textures into ARE
    # @param [Array<Texture>] textures
    # @return [Workspace] self
    ###
    loadTextures: (textures) ->
      @loadTexture texture for texture in textures
      @

    ###
    # @param [Texture] texture
    # @return [Workspace] self
    ###
    loadTexture: (texture) ->
      return AUtilLog.error "ARE not loaded, cannot load texture" unless @_are

      AdefyRE.Engine().loadTexture
        name: texture.getUID()
        file: texture.getURL()
      , =>
        AUtilLog.info "Texture(uid: #{texture.getUID()}) loaded"

        @ui.pushEvent "load.texture", texture: texture

        # Refresh any actors that already have the texture assigned
        for handle in @actorObjects
          if handle.getTextureUID() == texture.getUID()
            handle.setTexture texture

      @

    ###
    # Manually register an actor
    #
    # @param [BaseActor] handle
    ###
    addActor: (handle) ->

      @actorObjects.push handle
      @setSelectedActor handle
      window.a = handle
      @ui.pushEvent "workspace.add.actor", actor: handle
      @

    ###
    # Converts document-relative coordinates to ARE coordinates
    # NOTE: This does not currently take into account any camera transformation!
    #
    # @param [Number] x x coordinate
    # @param [Number] y y coordinate
    ###
    domToGL: (x, y) ->
      return AUtilLog.warn "Can't convert coords, are not up!" unless @_are

      canvasTop = $("#{@getSel()} canvas").offset().top
      canvasLeft = $("#{@getSel()} canvas").offset().left

      # TODO: Take into account camera coords
      {
        x: x - canvasLeft
        y: y - canvasTop
      }

    glToDom: (x, y) ->
      return AUtilLog.warn "Can't convert coords, are not up!" unless @_are

      canvasTop = $("#{@getSel()} canvas").offset().top
      canvasLeft = $("#{@getSel()} canvas").offset().left

      {
        x: x + canvasLeft - @_are.getRenderer().getCameraPosition().x
        y: y + canvasTop - @_are.getRenderer().getCameraPosition().y
      }

    ###
    # Generate workspace right-click ctx data object
    #
    # @param [Number] x x coordinate of click
    # @param [Number] y y coordinate of click
    # @return [Object] options
    ###
    getWorkspaceCtxMenu: (x, y) ->
      time = @ui.timeline.getCursorTime()
      pos = @domToGL(x, y)

      pos.x += @_are.getRenderer().getCameraPosition().x
      pos.y += @_are.getRenderer().getCameraPosition().y

      functions =
        rectActor:
          name: config.strings.actor_rectangle
          cb: => @addActor new RectangleActor @ui, time, 100, 100, pos.x, pos.y
        polyActor:
          name: config.strings.actor_polygon
          cb: => @addActor new PolygonActor @ui, time, 5, 60, pos.x, pos.y
        circActor:
          name: config.strings.actor_circle
          cb: => @addActor new PolygonActor @ui, time, 32, 60, pos.x, pos.y

      if @ui.editor.clipboard && @ui.editor.clipboard.type == "actor"
        functions.paste =
          name: config.strings.paste
          cb: =>

            pos = @domToGL(x, y)
            pos.x += @_are.getRenderer().getCameraPosition().x
            pos.y += @_are.getRenderer().getCameraPosition().y

            newActor = @ui.editor.clipboard.data.duplicate()
            newActor.setPosition pos.x, pos.y
            newActor.setName(newActor.getName() + " copy")

            @addActor newActor

      {
        name: config.strings.create_actor
        functions: functions
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
      noActorCb ||= ->

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
      $(document).on "contextmenu", ".workspace .editor-canvas", (e) =>
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
                  x: x
                  y: y
                  properties: actor.getContextProperties()
          else
            new ContextMenu @ui,
              x: x
              y: y
              properties: @getWorkspaceCtxMenu(x, y)

        e.preventDefault()
        false

    _bindActorClickRotate: ->
      @draggerRotate = new Dragger ".workspace .editor-canvas"

      @draggerRotate.setCheckDrag (e) =>
        !e.shiftKey && e.ctrlKey

      @draggerRotate.setOnDragStart (d) =>
        @performPick @domToGL(d.getStart().x, d.getStart().y), (r, g, b) =>
          return d.forceDragEnd() unless @isValidPick r, g, b

          handle = @getActorFromPick r, g, b
          return d.forceDragEnd() unless handle

          d.setTarget handle
          d.setUserData original: handle.getRotation()

          if handle.getActor().hasPhysics()
            handle.getActor().destroyPhysicsBody()
            d.setUserDataValue "hasPhysics", true
          else
            d.setUserDataValue "hasPhysics", false

          document.body.style.cursor = "pointer"

      @draggerRotate.setOnDragEnd (d) =>
        document.body.style.cursor = "auto"

        if d.getUserData()
          handle = d.getTarget()
          handle.getActor().createPhysicsBody() if d.getUserData().hasPhysics

      @draggerRotate.setOnDrag (d, deltaX, deltaY) =>

        # Delay the drag untill we finish our pick
        if d.getUserData() and d.getUserData().original != null
          org = d.getUserData().original
          n = (org + deltaX + deltaY) % 360
          n = 360+n if n < 0

          d.getTarget().setRotation n

          @ui.pushEvent "selected.actor.update", actor: d.getTarget()

    _bindActorClickSelect: ->

      # Actor picking!
      # NOTE: This should only be allowed when the scene is not being animated!
      $(".workspace .editor-canvas").click (e) =>
        return if @dragger.isDragging()
        return if e.shiftKey

        @performPick @domToGL(e.pageX, e.pageY), (r, g, b) =>
          return unless @isValidPick r, g, b

          actor = @getActorFromPick r, g, b
          if actor
            @setSelectedActor actor
            @ui.pushEvent "workspace.selected.actor", actor: actor

    _bindActorClickMove: ->

      @dragger = new Dragger ".workspace .editor-canvas"
      @dragger.setCheckDrag (e) => !e.shiftKey && !e.ctrlKey
      @dragger.setOnDragStart (d) =>
        @performPick @domToGL(d.getStart().x, d.getStart().y), (r, g, b) =>
          return d.forceDragEnd() unless @isValidPick r, g, b

          handle = @getActorFromPick r, g, b
          return d.forceDragEnd() unless handle

          d.setTarget handle
          d.setUserData
            original:
              x: handle.getPosition().x
              y: handle.getPosition().y

          if handle.getActor().hasPhysics()
            handle.getActor().destroyPhysicsBody()
            d.setUserDataValue "hasPhysics", true
          else
            d.setUserDataValue "hasPhysics", false

          document.body.style.cursor = "pointer"

      @dragger.setOnDragEnd (d) =>
        document.body.style.cursor = "auto"

        if d.getUserData()
          handle = d.getTarget()
          handle.getActor().createPhysicsBody() if d.getUserData().hasPhysics

      @dragger.setOnDrag (d, deltaX, deltaY) =>
        userData = d.getUserData()
        target = d.getTarget()

        # Delay the drag untill we finish our pick
        return unless userData and userData.original

        newX = userData.original.x + deltaX
        newY = userData.original.y + deltaY

        target.setPosition newX, newY, true
        @ui.pushEvent "selected.actor.update", actor: target

    ###
    # Register listeners
    ###
    _bindListeners: ->

      @_bindActorClickSelect()
      @_bindActorClickMove()
      @_bindActorClickRotate()
      @_bindCameraControls()
      @_bindContextClick()
      @_bindTextureDrop()

    ###
    # Sets up camera panning and zooming, when dragging with SHIFT or CMD/CTRL
    # pressed.
    ###
    _bindCameraControls: ->

      # We store the previous cursor position in @_lastPos, to apply a delta
      $(document).mouseup (e) =>
        @_lastPos = @_startPos = @_startScale = null
        @_cameraAction = pan: false, zoom: false

      $(document).on "mousedown", ".workspace .editor-canvas", (e) =>
        return unless !@_startPos # Only reset if we aren't already dragging

        @_startPos = x: e.pageX, y: e.pageY
        @_lastPos = x: e.pageX, y: e.pageY
        @_startScale = _.clone @_are.getRenderer().getCameraScale()
        @_cameraAction =
          pan: e.shiftKey
          zoom: e.ctrlKey or e.metaKey

      $(document).mousemove (e) =>
        return unless @_startPos

        if @_cameraAction.pan
          camPos = @_are.getRenderer().getCameraPosition()
          camPos.x += @_lastPos.x - e.pageX
          camPos.y += @_lastPos.y - e.pageY

        if @_cameraAction.zoom
          camScale = @_are.getRenderer().getCameraScale()

          # We keep the camera scale the same across all axes
          delta = (@_startPos.x - e.pageX) / 500
          camScale.x = @_startScale.x + delta
          camScale.y = @_startScale.y + delta

        # Update actors with bounding boxes.
        for actor in @actorObjects
          actor.refreshBoundingBox() if actor.boundingBoxVisible()

        @_lastPos = x: e.pageX, y: e.pageY

    ###
    # When an image is dropped onto the workspace, a rectangle actor is spawned
    # with that image as its texture, and resized accordingly.
    ###
    _bindTextureDrop: ->
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

          pos.x += @_are.getRenderer().getCameraPosition().x
          pos.y += @_are.getRenderer().getCameraPosition().y

          texSize = @_are.getRenderer().getTextureSize texture.getUID()
          w = texSize.w
          h = texSize.h

          actor = new RectangleActor @ui, time, w, h, pos.x, pos.y
          actor.setTexture texture
          @addActor actor

        e.preventDefault()
        false

    ###
    # @private
    # Called by AREEngine as soon as it's up and running, we continue our own
    # init from here.
    ###
    _engineInit: ->
      AUtilLog.info "ARE instance up, initializing workspace"

      @_bindListeners()

      # Start rendering
      @_are.startRendering()

    ###
    # @private
    # Update the canvas status, and alter the width of the canvas container
    # This should be called either after instantiation, or after a canvas
    # resize
    ###
    _applyCanvasSizeUpdate: ->
      sel = "##{config.id.are_canvas}"

      # Resize canvas container
      $("#{sel}").height @_canvasHeight
      $("#{sel}").width @_canvasWidth

      ##
      ## TODO: Move and make these calculations generic
      ##

      # Resize and reposition overlays
      phoneWidth = 1200
      phoneHeight = 1920

      # Scale actual phone size so we get a comfortable level of padding
      padding = 32
      zoomFactor = Math.min 1, (@_canvasHeight - (padding * 2)) / phoneHeight

      phoneWidth = Math.floor(phoneWidth * zoomFactor)
      phoneHeight = Math.floor(phoneHeight * zoomFactor)

      overlayWidth = Math.floor((@_canvasWidth - phoneWidth) / 2)
      overlayHeight = Math.floor((@_canvasHeight - phoneHeight) / 2)

      $("#{sel}-overlay-left").height @_canvasHeight
      $("#{sel}-overlay-left").width overlayWidth
      $("#{sel}-overlay-right").height @_canvasHeight
      $("#{sel}-overlay-right").width overlayWidth
      $("#{sel}-overlay-right").css left: @_canvasWidth - overlayWidth

      $("#{sel}-overlay-top").width @_canvasWidth - (overlayWidth * 2)
      $("#{sel}-overlay-top").height overlayHeight
      $("#{sel}-overlay-top").css left: overlayWidth
      $("#{sel}-overlay-bottom").width @_canvasWidth - (overlayWidth * 2)
      $("#{sel}-overlay-bottom").height overlayHeight
      $("#{sel}-overlay-bottom").css
        top: @_canvasHeight - overlayHeight
        left: overlayWidth

      $("#{sel}-overlay-center").width @_canvasWidth - (overlayWidth * 2)
      $("#{sel}-overlay-center").height @_canvasHeight - (overlayHeight * 2)
      $("#{sel}-overlay-center").css
        top: overlayHeight
        left: overlayWidth

      # Rebuild our picking resources
      @_buildPickBuffer()

    ###
    # Resets us completely, triggering the timeline death handler of every
    # actor, and removing them from both us and the timeline
    ###
    reset: ->

      for o in @actorObjects
        @ui.pushEvent "workspace.remove.actor", actor: o
        o.death()
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

      ctorName = obj.constructor.name

      # We keep track of actors internally, splice them out of our array
      if ctorName.indexOf("Actor") != -1 or ctorName.indexOf("Spawner") != -1
        for o, i in @actorObjects
          if o.getID() == obj.getID()
            @ui.pushEvent "workspace.remove.actor", actor: o
            @actorObjects.splice i, 1
            break

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
    # @return [Workspace] self
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
      unless @_are.getRenderer().isWGLRendererActive()
        return false

      gl = @_are.getRenderer().getGL()

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
      switch @_are.getRenderer().getActiveRendererMode()
        when ARERenderer.RENDER_MODE_NULL
          AUtilLog.warn "You can't perform a pick with a null renderer"
        when ARERenderer.RENDER_MODE_CANVAS
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

        when ARERenderer.RENDER_MODE_WGL
          @_are.requestPickingRenderWGL @_pickBuffer, =>

            pick = new Uint8Array 4

            pos.y = @_are.getHeight() - pos.y

            gl = @_are.getRenderer().getGL()
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
    # Create a new spawner with a base object definition cloned from an actor,
    # then kill the actor.
    #
    # NOTE: This deletes the ARE actor, and signals it's death to the rest of
    #       the editor! Do NOT use an actor object after this method has been
    #       called on it.
    ###
    transformActorIntoSpawner: (actor) ->

      @addActor new Spawner @ui,
        position: actor.getProperty("position").getValue()
        templateHandle: actor

      actor.delete()

    ###
    # Takes other widgets into account, and sets the height accordingly. Also
    # centers the phone outline
    #
    # Note that this does NOT resize the canvas
    ###
    onResize: ->
      # workspace now inherits its height from the config.selector.content

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      switch type
        when "timeline.selected.actor"
          @setSelectedActor params.actor

    ###
    # Dumps the current workspace state
    # @return [Object] data
    ###
    dump: ->
      actors = _.map @getActors(), (actor) -> actor.dump()
      actors = _.without actors, (actor) -> actor.getHandleType() == "Spawner"

      c = @getClearColor()
      clearColor =
        r: c.getR()
        g: c.getG()
        b: c.getB()

      _.extend super(),
        workspaceVersion: "1.5.2"
        camPos:                                                        # v1.2.0
          x: @_are.getRenderer().getCameraPosition().x
          y: @_are.getRenderer().getCameraPosition().y
        camScale:                                                      # v1.5.2
          x: @_are.getRenderer().getCameraScale().x
          y: @_are.getRenderer().getCameraScale().y
        actors: actors                                                 # v1.1.0
        clearColor: clearColor                                         # v1.5.0

    ###
    # Loads the a workspace data state
    # @param [Object] data
    ###
    load: (data) ->
      super data

      if (data.workspaceVersion >= "1.2.0") || \
       ((data.dumpVersion == "1.0.0") && (data.version >= "1.2.0"))

        @_are.getRenderer().setCameraPosition data.camPos      

      if data.workspaceVersion >= "1.5.0"
        col = data.clearColor
        @setClearColor col.r, col.g, col.b

      if data.workspaceVersion >= "1.5.2"
        @_are.getRenderer().setCameraScale data.camScale

      # We merged actor and spawner collections after 1.4.0
      actors = data.actors
      if data.workspaceVersion == "1.4.0" and data.spawners.length > 0
        actors = _.union data.spawners, actors

      # data.workspaceVersion >= "1.1.0"
      for actor in actors
        actorClass = window[actor.handleType]

        if actorClass
          @addActor actorClass.load @ui, actor
        else
          AUtilLog.warn "No such handle class #{actor.type}, can't load"

      @ui.timeline.updateAllActorsInTime()
