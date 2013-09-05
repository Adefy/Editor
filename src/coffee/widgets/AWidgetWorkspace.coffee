# Workspace widget
class AWidgetWorkspace extends AWidget

  # Set to true upon instantiation, prevents more than one instance
  @__exists: false

  # We store a static reference to ourselves, since some objects need to notify
  # us of their demise (muahahahahaha)
  @__instance: null

  # Creates a new workspace if one does not already exist
  #
  # @param [String] parent parent element selector
  constructor: (parent) ->

    if AWidgetWorkspace.__exists == true
      AUtilLog.warn "A workspace already exists, refusing to continue!"
      return

    param.required parent

    AWidgetWorkspace.__exists = true
    AWidgetWorkspace.__instance = @

    super prefId("aworkspace"), parent, [ "aworkspace" ]

    # Keep track of spawned handle actor objects
    @actorObjects = []

    # Create an AWGL instance on ourselves
    me = @
    if window.ajax == undefined then window.ajax = microAjax

    # NOTE: We start by default with a 720x1280 canvas size
    @_cWidth = 720
    @_cHeight = 1280

    # Picking resources
    @_pickBuffer = null
    @_pickTexture = null

    # Inject our canvas container, along with its status bar
    # Although we currently don't add anything else to the container besides
    # the canvas itself, it might prove useful in the future.
    _html = ""
    _html += "<div id=\"aw-canvas-container\">"
    _html += "</div"

    $(@_sel).html _html

    AUtilLog.info "Starting AWGL instance..."
    new AWGLEngine null, 4, (@_awgl) =>
      @_engineInit()
      @_applyCanvasSizeUpdate()
    , "aw-canvas-container", @_cWidth, @_cHeight

  # Retrieve canvas width
  #
  # @return [Number] width canvas width
  getCanvasWidth: -> @_cWidth

  # Retrieve canvas height
  #
  # @return [Number] height canvas height
  getCanvasHeight: -> @_cHeight

  # Update the canvas status, and alter the width of the canvas container
  # This should be called either after instantiation, or after a canvas
  # resize
  _applyCanvasSizeUpdate: ->

    # Resize canvas container
    $("#aw-canvas-container").css
      height: "#{@_cHeight}px"
      width: "#{@_cWidth}px"

    # Rebuild our picking resources
    @_buildPickBuffer()

  # Fetch our static instance
  #
  # @return [AWidgetWorkspace] me
  @getMe: -> @__instance

  # Any objects that need to tell us about their death have to do so by calling
  # this method and passing themselves in.
  #
  # @param [Object] obj dying object
  notifyDemise: (obj) ->

    # We keep track of actors internally, splice them out of our array
    if obj instanceof AMBaseActor
      for o, i in @actorObjects
        if o.getId() == obj.getId()
          @actorObjects.splice i, 1
          return

  # Builds the framebuffer and texture needed to preform picking, deleting
  # them if they already exist. This needs to be called whenever AWGLs' canvas
  # is resized
  #
  # http://learningwebgl.com/blog/?p=1786
  _buildPickBuffer: ->

    gl = @_awgl.getGL()

    # Delete them if they already exist
    if @_pickTexture != null then gl.deleteTexture @_pickTexture
    if @_pickBuffer != null then gl.deleteFramebuffer @_pickBuffer

    # Gogo
    @_pickBuffer = gl.createFramebuffer()
    @_pickTexture = gl.createTexture()

    _w = @_awgl.getWidth()
    _h = @_awgl.getHeight()

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


  # Called by AWGLEngine as soon as it's up and running, we continue our own
  # init from here.
  _engineInit: ->

    AUtilLog.info "AWGL instance up, initializing workspace"

    # Bind manipulatable handlers
    me = @
    $(document).ready ->

      # Set up draggable objects
      $(".aworkspace-drag").draggable
        addClasses: false
        helper: "clone"
        revert: "invalid"
        cursor: "pointer"

      # Set up our own capture of draggable objects
      $(".aworkspace canvas").droppable
        accept: ".aworkspace-drag"
        drop: (event, ui) =>
          # $.ui.ddmanager.current.cancelHelperRemoval = true

          # Get the associated widget object
          _sel = $(ui.draggable).children("div").attr("id")
          _obj = $("body").data _sel

          # Calculate workspace coordinates
          _truePos = me.domToGL ui.position.left, ui.position.top

          # TODO: Consider cleaning this up to just pass the domToGL result
          handle = _obj.dropped "workspace", _truePos.x, _truePos.y

          # TODO: Provide some flexibility here, take different actions if
          #       something besides an actor is dropped. For the time being,
          #       that can't happen. Yay.
          if handle instanceof AHBaseActor

            me.actorObjects.push handle

      # Actor dragging, whoop
      __drag_start_x = 0      # Keeps track of the initial drag point, so
      __drag_start_y = 0      # we know when to start listening

      __drag_orig_x = 0       # Original object pos x so we can calculate dx
      __drag_orig_y = 0       # Original object pos y so we can calculate dy

      __drag_obj_id = -1      # Id of the object we are dragging
      __drag_tolerance = 5    # How far the mouse should move before we pick up

      # When true, enables logic in mousemove()
      __drag_sys_active = false

      # When true, disables the normal click listener. This is reset a moment
      # after dragging actually stops
      __dragging = false

      # On mousedown, we need to setup pre-dragging state, perform a pick,
      # and wait for movement
      $(".aworkspace canvas").mousedown (e) ->

        # Calculate workspace coordinates
        _truePos = me.domToGL e.pageX, e.pageY

        # Note this can be slightly inefficient, since two picks are performed
        # on any click. Not when dragging, but when clicking both this and
        # the click() event above fire.
        #
        # TODO: Optimise. Consider performing the pick here, and saving the
        #       outcome for the click listener.
        me._performPick _truePos.x, _truePos.y, (r, g, b) ->

          # Not over an object, just return
          if b != 248 then return

          # Id is stored as a sector and an offset. Recover proper object id
          _id = r + (g * 255)

          # Find the actor in question
          for o in me.actorObjects
            if o.getActorId() == _id
              __drag_obj_id = _id
              break

          # If we are above an object, wait for mouse movement
          if __drag_obj_id != -1

            # Save beginning drag point
            __drag_start_x = e.pageX
            __drag_start_y = e.pageY

            # Save initial actor position
            __drag_orig_x = me.actorObjects[__drag_obj_id].getPosition().x
            __drag_orig_y = me.actorObjects[__drag_obj_id].getPosition().y

            # Activate
            __drag_sys_active = true

      # Reset state after, dragging after 1ms, leaving time to prevent the
      # click handler from taking effect
      $(".aworkspace canvas").mouseup (e) ->

        __drag_sys_active = false
        __drag_obj_id = -1

        setTimeout ->
          __dragging = false
        , 1

      # Core of the dragging logic
      $(".aworkspace canvas").mousemove (e) ->
        if __drag_sys_active

          __dragging = true

          if Math.abs(e.pageX - __drag_start_x) > __drag_tolerance \
          or Math.abs(e.pageY - __drag_start_y) > __drag_tolerance

            # Calc new coords (orig + offset)
            _newX = Number(__drag_orig_x + (e.pageX - __drag_start_x))

            # Note we need to invert the vertical offset
            _newY = Number(__drag_orig_y + ((e.pageY - __drag_start_y) * -1))

            # Update!
            me.actorObjects[__drag_obj_id].setPosition _newX, _newY

      # Actor picking!
      # NOTE: This should only be allowed when the scene is not being animated!
      $(".aworkspace canvas").click (e) ->

        # If we are dragging, gtfo
        if __dragging then return

        # Calculate workspace coordinates
        _truePos = me.domToGL e.pageX, e.pageY

        me._performPick _truePos.x, _truePos.y, (r, g, b) ->

          # Objects have a blue component of 248. If this is not an object,
          # perform the necessary clearing and continue
          if b != 248
            $("body").data("default-properties").clear()
            return

          # Id is stored as a sector and an offset. Recover proper object id
          _id = r + (g * 255)

          # Find the actor in question
          for o in me.actorObjects
            if o.getActorId() == _id

              # Fill in property list!
              o.onClick()

      # Bind a contextmenu listener
      $(document).on "contextmenu", ".aworkspace canvas", (e) ->
        e.preventDefault()

        # We right clicked on the canvas, pick the object at our click position
        # and get its associated handle
        _truePos = me.domToGL e.pageX, e.pageY

        # Pick
        me._performPick _truePos.x, _truePos.y, (r, g, b) ->

          # Extract id if valid
          if b != 248 then return
          _id = r + (g * 255)

          # Find the actor in question
          for o in me.actorObjects
            if o.getActorId() == _id

              # We clicked on a handle, check for context functions
              if not $.isEmptyObject o.getContextFunctions()

                # Instantiate a new context menu, it handles the rest
                new AWidgetContextMenu e.pageX, e.pageY, o

              return

        false

    # Start rendering
    @_awgl.startRendering()

  # Helper function to perform a pick at the specified canvas coordinates
  #
  # @param [Number] x x coordinate
  # @param [Number] y y coordinate
  # @param [Method] cb callback to call afterwards, passing r/g/b
  _performPick: (x, y, cb) ->
    # Request a pick render from AWGL, continue once we get it
    @_awgl.requestPickingRender @_pickBuffer, =>

      pick = new Uint8Array 4

      gl = @_awgl.getGL()
      gl.bindFramebuffer gl.FRAMEBUFFER, @_pickBuffer
      gl.readPixels x, y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pick
      gl.bindFramebuffer gl.FRAMEBUFFER, null

      cb pick[0], pick[1], pick[2]

  # Converts document-relative coordinates to AWGL coordinates
  # NOTE: This does not currently take into account any camera transformation!
  #
  # @param [Number] x x coordinate
  # @param [Number] y y coordinate
  domToGL: (x, y) ->

    # Bail
    if @_awgl == undefined
      AUtilLog.warn "Can't convert coords, awgl not up!"
      return null

    canvasTop = $("#{@getSel()} canvas").offset().top
    canvasLeft = $("#{@getSel()} canvas").offset().left

    # TODO: Take into account camera coords

    ret =
      x: x - canvasLeft
      y: @_awgl.getHeight() - (y - canvasTop)

  # Simply takes the navbar into account, and sets the height accordingly
  # Note that this does NOT resize the canvas
  onResize: ->
    $(@_sel).height $(document).height() - $(".amainbar").height()
