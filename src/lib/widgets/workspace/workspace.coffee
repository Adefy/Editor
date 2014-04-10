define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Project = require "project"
  Widget = require "widgets/widget"
  Modal = require "widgets/modal"
  ContextMenu = require "widgets/context_menu"
  TemplateModalAddTextures = require "templates/modal/add_textures"
  TemplateModalBackgroundColor = require "templates/modal/background_color"
  TemplateModalWorkspaceScreenSize = require "templates/modal/screen_size"
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

      @project = new Project()

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
      AUtilLog.info "Creating ARE instance..."
      new AREEngine @_canvasWidth, @_canvasHeight, (@_are) =>
        @_engineInit()
        @_applyCanvasSizeUpdate()
      , 4, "aw-canvas-container"

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
    # Sets the selectedActor instance
    # @param [Id] actorId
    ###
    setSelectedActor: (actor) ->
      Workspace._selectedActor = actor.getId()

    ###
    # Bind a contextmenu listener
    ###
    bindContextClick: ->
      $(document).on "contextmenu", ".workspace canvas", (e) =>
        return if @dragger.isDragging()

        @performPick @domToGL(e.pageX, e.pageY), (r, g, b) =>
          return unless @isValidPick r, g, b

          actor = @getActorFromPick r, g, b
          if actor
            unless _.isEmpty actor.getContextFunctions()
              @dragger.forceDragEnd()
              new ContextMenu e.pageX, e.pageY, actor

        e.preventDefault()
        false

    ###
    # Set up our own capture of draggable objects
    ###
    setupDroppableCanvas: ->
      $(".workspace canvas").droppable
        accept: ".workspace-drag"
        drop: (event, ui) =>

          # Calculate workspace coordinates
          position = @domToGL ui.position.left, ui.position.top

          object = @ui.toolbar.getItemById $(ui.draggable).attr "data-id"

          # TODO: Consider cleaning this up to just pass the domToGL result
          handle = object.spawn position.x, position.y

          # TODO: Provide some flexibility here, take different actions if
          #       something besides an actor is dropped. For the time being,
          #       that can't happen. Yay.
          @addActor handle if handle.constructor.name.indexOf("Actor") != -1

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
          @ui.pushEvent "selected.actor.changed"

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

      @bindContextClick()
      @setupDroppableCanvas()
      @setupActorDragging()

      # Start rendering
      @_are.startRendering()

    ###
    # Shows a modal allowing the user to set screen properties. Sizes are picked
    # from device templates, rotation and scale are also available
    ###
    showSetScreenProperties: ->

      curScale = ID.prefId "_wspscale"
      cSize = ID.prefId "_wspcsize"
      pSize = ID.prefId "_wsppsize"
      pOrie = ID.prefId "_wsporientation"

      curSize = "#{@_pWidth}x#{@_pHeight}"
      chL = ""
      chP = ""

      if @_pOrientation == "land" then chL = "checked=\"checked\""
      else chP = "checked=\"checked\""

      _html = TemplateModalWorkspaceScreenSize
        cSize: cSize
        pSize: pSize
        pOrie: pOrie
        chL: chL
        chP: chP
        curScale: curScale
        pScale: @_pScale
        currentSize: curSize

      new Modal
        title: "Set Screen Properties",
        content: _html,
        modal: false,
        cb: (data) =>
          # Submission
          size = data[cSize].split "x"

          @_pHeight = Number size[1]
          @_pWidth = Number size[0]
          @_pScale = Number data[curScale]
          @_pOrientation = data[pOrie]
          @updateOutline()

        validation: (data) =>
          # Validation
          size = data[cSize].split "x"

          if size.length != 2 then return "Size is of the format WidthxHeight"
          else if isNaN(size[0]) or isNaN(size[1])
            return "Dimensions must be numbers"
          else if isNaN(data[curScale]) then return "Scale must be a number"

          true
        change: (deltaName, deltaVal, data) =>

          if deltaName == pSize
            $("input[name=\"#{cSize}\"]").val deltaVal.split("_").join "x"

    ###
    # Creates and shows the "Set Background Color" modal
    # @return [Modal]
    ###
    showSetBackgroundColor: ->

      col = @_are.getClearColor()

      _colR = col.getR()
      _colG = col.getG()
      _colB = col.getB()

      valHex = _colB | (_colG << 8) | (_colR << 16)
      valHex = (0x1000000 | valHex).toString(16).substring 1

      preview = ID.prefId "_wbgPreview"
      hex = ID.prefId "_wbgHex"
      r = ID.prefId "_wbgR"
      g = ID.prefId "_wbgG"
      b = ID.prefId "_wbgB"

      pInitial = "background-color: rgb(#{_colR}, #{_colG}, #{_colB});"

      _html = TemplateModalBackgroundColor
        hex: hex
        hexstr: valHex
        r: r
        g: g
        b: b
        colorRed: _colR
        colorGreen: _colG
        colorBlue: _colB
        preview: preview
        pInitial: pInitial

      new Modal
        title: "Set Background Color",
        content: _html,
        modal: false,
        cb: (data) =>
          # Submission
          @_are.setClearColor data[r], data[g], data[b]

        validation: (data) =>
          # Validation
          vR = data[r]
          vG = data[g]
          vB = data[b]

          if isNaN(vR) or isNaN(vG) or isNaN(vB)
            return "Components must be numbers"
          else if vR < 0 or vG < 0 or vB < 0 or vR > 255 or vG > 255 or vB > 255
            return "Components must be between 0 and 255"

          true
        change: (deltaName, deltaVal, data) =>

          cH = data[hex]
          cR = data[r]
          cG = data[g]
          cB = data[b]

          delta = {}

          # On change
          if deltaName == hex

            # Recover rgb from hex
            cH = cH.substring 1
            _r = cH.substring 0, 2
            _g = cH.substring 2, 4
            _b = cH.substring 4, 6

            delta[hex] = cH
            delta[r] = parseInt _r, 16
            delta[g] = parseInt _g, 16
            delta[b] = parseInt _b, 16

          else

            # Build hex from rgba
            newHex = cB | (cG << 8) | (cR << 16)
            newHex = (0x1000000 | newHex).toString(16).substring 1

            delta[hex] = "##{newHex}"
            delta[r] = data[r]
            delta[g] = data[g]
            delta[b] = data[b]

          # Apply bg color to preview
          rgbCol = "rgb(#{delta[r]}, #{delta[g]}, #{delta[b]})"
          $("##{preview}").css "background-color", rgbCol

          # Return updates
          delta

    ###
    # Creates and shows the "Add Textures" modal
    # @return [Modal]
    ###
    showAddTextures: ->
      textnameID = ID.prefId "_wtexture"
      textpathID = ID.prefId "_wtext"

      _html = TemplateModalAddTexturesTemplate
        textnameID: textnameID
        textpathID: textpathID
        textname: ""
        textpath: ""

      new Modal
        title: "Add textures ..."
        content: _html
        modal: false
        cb: (data) =>
          #Submission
          @_uploadTextures data[textnameID], data[textpathID]

        validation: =>
          if data[textnameID] == ""
            return "Texture must have a name"

          if data[textpathID] == null or data[textpathID] == ""
            return "You must select a texture"

          true

    ###
    # Upload the textures to the cloud for processing and usage
    # @private
    ###
    _uploadTextures: (name, path) ->

      ARELog.info "Upload textures request"
      ARELog.info name + "@" + path

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

      @actorObjects = []

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
          if o.getId() == obj.getId()
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

      gl.generateMipmap gl.TEXTURE_2D

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
