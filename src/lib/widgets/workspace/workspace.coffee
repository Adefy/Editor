define (require) ->

  ID = require "util/id"
  AUtilLog = require "util/log"
  param = require "util/param"

  Widget = require "widgets/widget"
  ContextMenu = require "widgets/context_menu"
  TemplateWorkspaceCanvasContainer = require "templates/workspace/canvas_container"

  Dragger = require "util/dragger"

  # Workspace widget
  class Workspace extends Widget

    ###
    # @type [BaseActor]
    ###
    @_selectedActor: null

    ###
    # Retrieves the currently selected actor, if any
    # @return [Id] actorId
    ###
    @getSelectedActor: -> @_selectedActor

    ###
    # Creates a new workspace if one does not already exist
    #
    # @param [UIManager] ui
    ###
    constructor: (@ui) ->
      return unless @enforceSingleton()
      param.required @ui

      super
        id: ID.prefId("workspace")
        parent: "section#main"
        classes: ["workspace"]
        prepend: true

      # Keep track of spawned handle actor objects
      @actorObjects = []

      # The canvas is fullscreen, minus the mainbar
      @_canvasWidth = @getElement().width()
      @_canvasHeight = $(window).height() - $(".menubar").height()

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

      # Inject our canvas container, along with its status bar
      # Although we currently don't add anything else to the container besides
      # the canvas itself, it might prove useful in the future.
      @getElement().html TemplateWorkspaceCanvasContainer()

      # Create an ARE instance on ourselves
      AUtilLog.info "Initializing AJS..."
      AJS.init =>

        @_are = window.AdefyRE.Engine()._engine

        # window.AdefyRE.Engine().setLogLevel 4

        @_engineInit()
        @_applyCanvasSizeUpdate()

      , @_canvasWidth, @_canvasHeight, "aw-canvas-container"

    ###
    # Internal list of workspace actor objects (Handles)
    #
    # @return [Array<Handle>] actors
    ###
    getActors: -> @actorObjects

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
    # Adds an actor to the workspace
    ###
    addActor: (actor) ->
      @actorObjects.push actor
      @ui.pushEvent "workspace.add.actor", actor: actor

    ###
    # Returns the currently selected actor's id
    # @return [Id] actorId
    ###
    getSelectedActor: -> Workspace._selectedActor

    ###
    # Sets the selectedActor instance
    # @param [Id] actorId
    ###
    setSelectedActor: (actor) ->
      Workspace._selectedActor = actor.getID()

    ###
    # Loads textures into ARE
    # @param [Array<Texture>] textures
    ###
    loadTextures: (textures) ->
      @loadTexture texture for texture in textures

    ###
    # @param [Texture] texture
    ###
    loadTexture: (texture) ->
      return AUtilLog.error "ARE not loaded, cannot load texture" unless @_are

      AdefyRE.Engine().loadTexture texture.getUID(), texture.getURL(), false, ->
        AUtilLog.info "Texture(uid: #{texture.getUID()}) loaded"

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
        "New Actor +": =>
            new ContextMenu x, y, @getNewActorCtxMenu x, y

      if AdefyEditor.clipboard && AdefyEditor.clipboard.type == "actor"
        functions["Paste"] = =>

          pos = @domToGL(x, y)
          pos.x += ARERenderer.camPos.x
          pos.y += ARERenderer.camPos.y

          newActor = AdefyEditor.clipboard.data.duplicate()
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
          "Rectangle Actor": =>
            @addActor new RectangleActor @ui, time, 100, 100, pos.x, pos.y
          "Polygon Actor": =>
            @addActor new PolygonActor @ui, time, 5, 60, pos.x, pos.y
          "Triangle Actor": =>
            @addActor new TriangleActor @ui, time, 100, 100, pos.x, pos.y
      }

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
                new ContextMenu x, y, actor.getContextProperties()
          else
            new ContextMenu x, y, @getWorkspaceCtxMenu x, y

        e.preventDefault()
        false

    ###
    # Register listeners
    ###
    _regListeners: ->
      @_bindContextClick()

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
        if e.shiftKey && !@_workspaceDrag
          @_workspaceDrag =
            x: e.pageX
            y: e.pageY

      # Setup texture drops
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
    # Initializes dragging settings and attaches listeners
    ###
    setupActorDragging: ->
      @dragger = new Dragger ".workspace canvas"

      @dragger.setOnDragStart (d) =>
        @performPick @domToGL(d.getStart().x, d.getStart().y), (r, g, b) =>
          return d.forceDragEnd() unless @isValidPick r, g, b

          handle = @getActorFromPick r, g, b
          return d.forceDragEnd() unless handle

          d.setTarget handle
          d.setUserData
            updateProperties: true
            original: handle.getPosition()

          if handle.getActor().hasPsyx()
            handle.getActor().disablePsyx()
            d.setUserDataValue "hasPhysics", true
          else
            d.setUserDataValue "hasPhysics", false

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

        @performPick @domToGL(e.pageX, e.pageY), (r, g, b) =>
          unless @isValidPick r, g, b
            data = $("body").data("default-properties")
            data.clear() if data
            return

          actor = @getActorFromPick r, g, b
          if actor
            oldActor = @getSelectedActor()
            @setSelectedActor actor
            @ui.pushEvent "workspace.selected.actor",
              actorId: @_selectedActor
              actor: actor

    ###
    # @private
    # Called by AREEngine as soon as it's up and running, we continue our own
    # init from here.
    ###
    _engineInit: ->
      AUtilLog.info "ARE instance up, initializing workspace"

      @_are.setClearColor 240, 240, 240

      @_regListeners()

      @setupActorDragging()

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
      $("#aw-canvas-container").css
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
    # Manually register an actor
    #
    # @param [BaseActor] handle
    ###
    registerActor: (handle) ->
      param.required handle

      if not handle.constructor.name.indexOf("Actor") != -1
        throw new Error "You can only register actors that derive from BaseActor"

      @actorObjects.push handle
      @ui.timeline.registerActor handle

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
      @getElement().height $("section#main").height()

      #elm.offset
      #  top: toolb.position().top + toolb.height()
      #  left: sideb.position().left + sideb.width()

      #timelineBottom = Number($(".timeline").css("bottom").split("px")[0]) - 16
      #timelineHeight = ($(".timeline").height() + timelineBottom)
      ## Our height
      #@getElement().height $(document).height() - $(".menubar").height() + 2 - \
      #  timelineHeight

      # Center phone outline
      # @updateOutline()

    ###
    # Dumps the current workspace state
    # @return [Object] data
    ###
    dump: ->
      _.extend super(),
        version: "1.2.0"
        camPos:
          x: ARERenderer.camPos.x
          y: ARERenderer.camPos.y
        actors: _.map @getActors(), (actor) -> actor.dump()

    ###
    # Loads the a workspace data state
    # @param [Object] data
    ###
    load: (data) ->
      super data
      if data.version >= "1.2.0"
        ARERenderer.camPos.x = data.camPos.x
        ARERenderer.camPos.y = data.camPos.y

      #data.version == "1.1.0"
      for actor in data.actors
        newActor = window[actor.type].load @ui, actor
        @addActor newActor

      @ui.timeline.updateAllActorsInTime()

