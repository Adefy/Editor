# Workspace widget
class AWidgetWorkspace extends AWidget

  # Set to true upon instantiation, prevents more than one instance
  @__exists: false

  # Creates a new workspace if one does not already exist
  #
  # @param [String] parent parent element selector
  constructor: (parent) ->

    if AWidgetWorkspace.__exists == true
      AUtilLog.warn "A workspace already exists, refusing to continue!"
      return

    AWidgetWorkspace.__exists = true

    param.required parent
    super prefId("aworkspace"), parent, [ "aworkspace" ]

    # Keep track of objects in the workspace. TODO: Decide in what format to
    # do so; for the time being, this is a flat array of AJS objects
    @objects = []

    # Create an AWGL instance on ourselves
    me = @
    if window.ajax == undefined then window.ajax = microAjax

    AUtilLog.info "Starting AWGL instance..."
    new AWGLEngine null, 4, (@_awgl) =>
      @_engineInit()
    , @_id

    # The following is obselete, we are moving forward with a canvas
    # workspace, with the help of AWGL. Picking just got 100x more complex
    ###
    # Set up our dragging functionality
    $(document).ready ->

      # Set up draggable objects
      $(".aworkspace-drag").draggable
        addClasses: false
        helper: "clone"
        revert: "invalid"
        cursor: "pointer"

      # Set up our own capture of draggable objects
      $(".aworkspace").droppable
        accept: ".aworkspace-drag"
        drop: (event, ui) ->
          # $.ui.ddmanager.current.cancelHelperRemoval = true

          # Get the associated widget object
          _sel = $(ui.draggable).children("div").attr("id")
          _obj = $("body").data _sel

          # Calculate workspace coordinates
          _x = ui.position.left - $(@).position().left
          _y = ui.position.top - $(@).position().top

          $(@).append _obj.dropped "workspace", _x, _y

      # Bind a contextmenu listener
      $(document).on "contextmenu", ".amanipulatable", (e) ->

        # We right clicked on a manipulatable, check for context functions on
        # the manipulatable after grabbing it from the body's data
        _obj = $("body").data $(e.target).parent().attr("id")

        if not $.isEmptyObject _obj.getContextFunctions()

          # Prevent the default handler from taking effect
          e.preventDefault()

          # Instantiate a new context menu, it handles the rest
          new AWidgetContextMenu e.pageX, e.pageY, _obj

          # Whoop
          return false
    ###

  # Called by AWGLEngine as soon as it's up and running, we continue our own
  # init from here.
  _engineInit: ->

    AUtilLog.info "AWGL instance up, initializing workspace"

    # Create our picking framebuffer
    # http://learningwebgl.com/blog/?p=1786
    gl = @_awgl.getGL()
    @_pickBuffer = gl.createFramebuffer()
    @_pickTexture = gl.createTexture()

    gl.bindFramebuffer gl.FRAMEBUFFER, @_pickBuffer
    gl.bindTexture gl.TEXTURE_2D, @_pickTexture

    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER \
      , gl.LINEAR_MIPMAP_NEAREST

    # Framebuffer is 512x512
    gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, 512, 512, 0, gl.RGBA \
      , gl.UNSIGNED_BYTE, null

    gl.generateMipmap gl.TEXTURE_2D

    # Set up a depth buffer, bind it and whatnot
    _renderBuff = gl.createRenderbuffer()
    gl.bindRenderbuffer gl.RENDERBUFFER, _renderBuff
    gl.renderbufferStorage gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, 512, 512

    gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 \
      , gl.TEXTURE_2D, @_pickTexture, _renderBuff

    gl.framebufferRenderbuffer gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT \
      , gl.RENDERBUFFER, _renderBuff

    # Cleanup
    gl.bindTexture gl.TEXTURE_2D, null
    gl.bindRenderbuffer gl.RENDERBUFFER, null
    gl.bindFramebuffer gl.FRAMEBUFFER, null

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
          manipulatable = _obj.dropped "workspace", _truePos.x, _truePos.y

          # TODO: Provide some flexibility here, take different actions if
          #       something besides an actor is dropped. For the time being,
          #       that can't happen. Yay.
          if manipulatable instanceof AMBaseActor

            new AJSRectangle
              psyx: false
              mass: 0
              friction: 0.3
              elasticity: 0.4
              w: 100
              h: 100
              position: new AJSVector2 _truePos.x, _truePos.y
              color: new AJSColor3 255, 0, 0

      # Actor picking!
      # NOTE: This should only be allowed when the scene is not being animated!
      $(".aworkspace canvas").click (e) ->

        # Calculate workspace coordinates
        _truePos = me.domToGL e.pageX, e.pageY

        # Request a pick render from AWGL, continue once we get it
        me._awgl.requestPickingRender me._pickBuffer, ->

          pick = new Uint8Array 4

          gl.bindFramebuffer gl.FRAMEBUFFER, me._pickBuffer
          gl.readPixels _truePos.x, _truePos.y, 1, 1, gl.RGBA \
            , gl.UNSIGNED_BYTE, pick
          gl.bindFramebuffer gl.FRAMEBUFFER, null

          console.log "#{pick[0]}, #{pick[1]}, #{pick[2]}, #{pick[3]}"

    # Start rendering
    @_awgl.startRendering()

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
  onResize: -> $(@_sel).height $(window).height() - $(".amainbar").height()
