##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Workspace widget
class AWidgetWorkspace extends AWidget

  # Set to true upon instantiation, prevents more than one instance
  @__exists: false

  # We store a static reference to ourselves, since some objects need to notify
  # us of their demise (muahahahahaha)
  @__instance: null

  @_selectedActor: null

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

    timelineBottom = Number($(".atimeline").css("bottom").split("px")[0]) - 16
    timelineHeight = ($(".atimeline").height() + timelineBottom)

    # The canvas is fullscreen, minus the mainbar
    @_cWidth = $(@_sel).width()
    @_cHeight = $(window).height() - $(".amainbar").height() - 2

    # Starting phone size is 800x480
    @_pWidth = 800
    @_pHeight = 480
    @_pScale = 1
    @_pOrientation = "land"

    # Picking resources
    @_pickBuffer = null
    @_pickTexture = null

    # Inject our canvas container, along with its status bar
    # Although we currently don't add anything else to the container besides
    # the canvas itself, it might prove useful in the future.
    _html = ""
    _html += "<div id=\"aw-canvas-container\">"
    _html +=   "<div id=\"awcc-outline-text\"></div>"
    _html +=   "<div id=\"awcc-outline\"></div>"
    _html += "</div"

    $(@_sel).html _html

    AUtilLog.info "Starting AWGL instance..."
    new AWGLEngine null, 4, (@_awgl) =>
      @_engineInit()
      @_applyCanvasSizeUpdate()
    , "aw-canvas-container", @_cWidth, @_cHeight

  # Get AWGL instance
  #
  # @return [AWGLEngine] awgl
  getAWGL: -> @_awgl

  # Get phone width
  #
  # @return [Number] width
  getPhoneWidth: -> @_pWidth

  # Get phone height
  #
  # @return [Number] height
  getPhoneHeight: -> @_pHeight

  # Get phone scale
  #
  # @return [Number] scale
  getPhoneScale: -> @_pScale

  # Shows a modal allowing the user to set screen properties. Sizes are picked
  # from device templates, rotation and scale are also available
  showSetScreenProperties: ->

    curScale = prefId "_wspscale"
    cSize = prefId "_wspcsize"
    pSize = prefId "_wsppsize"
    pOrie = prefId "_wsporientation"

    curSize = "#{@_pWidth}x#{@_pHeight}"
    chL = ""
    chP = ""

    if @_pOrientation == "land" then chL = "checked=\"checked\""
    else chP = "checked=\"checked\""

    _html = """

      <div class="input_group">
        <label>Current size: </label>
        <input type="text" value="#{curSize}" disabled="disabled" />
      </div>
      <br />
      <div class="input_group">
        <label for="#{cSize}">Custom Size: </label>
        <input name="#{cSize}" type="text" value="#{curSize}"
          placeholder="WidthxHeight" />
      </div>

      <div class="input_group">
        <label for="#{pSize}">Preset Size: </label>
        <select name="#{pSize}">
          <optgroup label="Android 120 ldpi">
            <option value="240_320">240x320</option>
            <option value="240_400">240x400</option>
            <option value="240_432">240x432</option>
            <option value="480_800">480x800</option>
            <option value="480_854">480x854</option>
            <option value="1024_600">1024x600</option>
          </optgroup>

          <optgroup label="Android 160 mdpi">
            <option value="320_480">320x480</option>
            <option value="480_800">480x800</option>
            <option value="480_854">480x854</option>
            <option value="600_1024">600x1024</option>
            <option value="1280_800">1280x800</option>
            <option value="1024_768">1024x768</option>
            <option value="1280_768">1280x768</option>
          </optgroup>

          <optgroup label="Android 240 hdpi">
            <option value="480_640">480x640</option>
            <option value="480_800">480x800</option>
            <option value="480_854">480x854</option>
            <option value="600_1024">600x1024</option>
            <option value="1536_1152">1536x1152</option>
            <option value="1920_1152">1920x1152</option>
            <option value="1920_1200">1920x1200</option>
          </optgroup>

          <optgroup label="Android 320 xhdpi">
            <option value="640_960">640x960</option>
            <option value="2048_1536">2048x1536</option>
            <option value="2560_1536">2560x1536</option>
            <option value="2560_1600">2560x1600</option>
          </optgroup>

          <optgroup label="iOS iPad & iPad Mini">
            <option value="1024_768">1024x768</option>
            <option value="2048_1536">2048x1536</option>
          </optgroup>

          <optgroup label="iPhone 5, 5s, 4, 4s">
            <option value="1136_640">1136x640</option>
            <option value="960_640">960x640</option>
            <option value="480_320">480x320</option>
          </optgroup>
        </select>
      </div>

      <div class="input_group">
        <label for="#{pOrie}">Orientation: </label>
        <div class="radio">
          <input type="radio" name="#{pOrie}" value="land" #{chL} /> Landscape
          <input type="radio" name="#{pOrie}" value="port" #{chP} /> Portrait
        </div>
      </div>

      <div class="input_group">
        <label for="#{curScale}">Scale: </label>
        <input class="wsmall" type="number" name="#{curScale}"
          value="#{@_pScale}" />
      </div>
    """

    new AWidgetModal "Set Screen Properties", _html, false, (data) =>

      # Submission
      size = data[cSize].split "x"

      @_pHeight = Number size[1]
      @_pWidth = Number size[0]
      @_pScale = Number data[curScale]
      @_pOrientation = data[pOrie]
      @updateOutline()

    , (data) =>

      # Validation
      size = data[cSize].split "x"

      if size.length != 2 then return "Size is of the format WidthxHeight"
      else if isNaN(size[0]) or isNaN(size[1])
        return "Dimensions must be numbers"
      else if isNaN(data[curScale]) then return "Scale must be a number"

      true
    , (deltaName, deltaVal, data) =>

      if deltaName == pSize
        $("input[name=\"#{cSize}\"]").val deltaVal.split("_").join "x"

  # Shows a modal allowing the user to set the background color
  showSetBackgroundColor: ->

    col = @_awgl.getClearColor()

    _colR = col.getR()
    _colG = col.getG()
    _colB = col.getB()

    valHex = _colB | (_colG << 8) | (_colR << 16)
    valHex = (0x1000000 | valHex).toString(16).substring 1

    preview = prefId "_wbgPreview"
    hex = prefId "_wbgHex"
    r = prefId "_wbgR"
    g = prefId "_wbgG"
    b = prefId "_wbgB"

    pInitial = "background-color: rgb(#{_colR}, #{_colG}, #{_colB});"

    _html = """
      <div class="input_group">
        <label for="#{hex}">Hex: </label>
        <input name="#{hex}" type="text" value="##{valHex}"></input>
      <div>

      <br />
      <p class="tcenter">Or...</p>
      <br />

      <div class="input_group">
        <label for="#{r}">R: </label>
        <input name="#{r}" type="text" value="#{_colR}"></input>
      <div>

      <div class="input_group">
        <label for="#{g}">G: </label>
        <input name="#{g}" type="text" value="#{_colG}"></input>
      <div>

      <div class="input_group">
        <label for="#{b}">B: </label>
        <input name="#{b}" type="text" value="#{_colB}"></input>
      <div>

      <div id="#{preview}" class="_wbgPreview" style="#{pInitial}"></div>
    """

    new AWidgetModal "Set Background Color", _html, false, (data) =>

      # Submission
      @_awgl.setClearColor data[r], data[g], data[b]

    , (data) =>

      # Validation
      vR = data[r]
      vG = data[g]
      vB = data[b]

      if isNaN(vR) or isNaN(vG) or isNaN(vB)
        return "Components must be numbers"
      else if vR < 0 or vG < 0 or vB < 0 or vR > 255 or vG > 255 or vB > 255
        return "Components must be between 0 and 255"

      true
    , (deltaName, deltaVal, data) =>

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

        delta[r] = parseInt _r, 16
        delta[g] = parseInt _g, 16
        delta[b] = parseInt _b, 16

      else

        # Build hex from rgba
        newHex = cB | (cG << 8) | (cR << 16)
        newHex = (0x1000000 | newHex).toString(16).substring 1

        delta[hex] = "##{newHex}"

      # Apply bg color to preview
      rgbCol = "rgb(#{data[r]}, #{data[g]}, #{data[b]})"
      $("##{preview}").css "background-color", rgbCol

      # Return updates
      delta

  showAddTextures: ->

    textName = ""
    textPath = ""
    textname = prefId "_wtexture"
    textpath = prefId "_wtextpath"
    _html = """
      <div class="input_group">
        <label for="#{textname}">Texture Name: </label>
        <input name="#{textname}" type="text" value="#{textName}"></input>
      <div>
      <div class="input_group">
        <label for="#{textpath}">Select Texture: </label>
        <input name="#{textpath}" type="file" value="#{textPath}" multiple>
        </input>
      <div>
    """
    new AWidgetModal "Add textures...", _html, false, (data) =>

      #Submission
      @_uploadTextures data[textname], data[textpath]

    , (data) =>
      if data[textname] == ""
        return "Texture must have a name"
      if data[textpath] == null or data[textpath] == ""
        return "You must select a texture"

      true

  # Upload the textures to the cloud for processing and usage
  # @private
  _uploadTextures: (name, path) ->

    AWGLLog.info "Upload textures request"
    AWGLLog.info name + "@" + path

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
  @getMe: -> AWidgetWorkspace.__instance

  # Resets us completely, triggering the timeline death handler of every
  # actor, and removing them from both us and the timeline
  reset: ->

    for o in @actorObjects
      AWidgetTimeline.getMe().removeActor o.getActorId()
      o.timelineDeath()
      o.delete()

    @actorObjects = []

  # Any objects that need to tell us about their death have to do so by calling
  # this method and passing themselves in.
  #
  # @param [Object] obj dying object
  notifyDemise: (obj) ->

    # We keep track of actors internally, splice them out of our array
    if obj instanceof AHBaseActor
      for o, i in @actorObjects
        if o.getId() == obj.getId()
          @actorObjects.splice i, 1

          # Remove actor from the timeline
          AWidgetTimeline.getMe().removeActor obj.getActorId()

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

  # Manually register an actor
  #
  # @param [AHBaseActor] handle
  registerActor: (handle) ->
    param.required handle

    if not handle instanceof AHBaseActor
      throw new Error "You can only register actors that derive from BaseActor"

    @actorObjects.push handle
    AWidgetTimeline.getMe().registerActor handle

  # Called by AWGLEngine as soon as it's up and running, we continue our own
  # init from here.
  _engineInit: ->

    AUtilLog.info "AWGL instance up, initializing workspace"

    # Start with an off-white clear color
    @_awgl.setClearColor 240, 240, 240

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

            # Register actor with ourselves
            me.actorObjects.push handle

            # Register actor with the timeline
            AWidgetTimeline.getMe().registerActor handle

      # Actor dragging, whoop
      __drag_start_x = 0      # Keeps track of the initial drag point, so
      __drag_start_y = 0      # we know when to start listening

      __drag_orig_x = 0       # Original object pos x so we can calculate dx
      __drag_orig_y = 0       # Original object pos y so we can calculate dy

      __drag_obj_index = -1   # Index of the object we are dragging
      __drag_tolerance = 5    # How far the mouse should move before we pick up

      __drag_update_props = false # Whether or not to update properties
      __drag_props = null         # Handle on the properties widget
      __drag_psyx = false         # Whether or not the object had a psyx body

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
          for o, i in me.actorObjects
            if o.getActorId() == _id
              __drag_obj_index = i
              break

          # If we are above an object, wait for mouse movement
          if __drag_obj_index != -1

            # Check if the actor is present in the sidebar. If so, store a
            # handle on the sidebar and enable property updating
            props = $("body").data "default-properties"
            if props instanceof AWidgetSidebarProperties
              if props.privvyIface("get_id") == _id
                __drag_update_props = true
                __drag_props = props

            # Save beginning drag point
            __drag_start_x = e.pageX
            __drag_start_y = e.pageY

            # Save initial actor position
            __drag_orig_x = me.actorObjects[__drag_obj_index].getPosition().x
            __drag_orig_y = me.actorObjects[__drag_obj_index].getPosition().y

            # Activate
            __drag_sys_active = true

      # Reset state after, dragging after 1ms, leaving time to prevent the
      # click handler from taking effect
      $(".aworkspace canvas").mouseup (e) ->

        if __drag_psyx
          me.actorObjects[__drag_obj_index].getActor().enablePsyx()

        __drag_sys_active = false
        __drag_obj_index = -1
        __drag_props = null
        __drag_update_props = false
        __drag_psyx = false

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

              # Update selected actor for use in AWidgetTimeline
              AWidgetWorkspace._selectedActor = o.getId()

              # Fill in property list!
              o.onClick()

        setTimeout ->
          __dragging = false
        , 1

      # Core of the dragging logic
      $(".aworkspace canvas").mousemove (e) ->

        # Means we also have a valid object id
        if __drag_sys_active

          # Perform an initial check, destroy the physics body if there is one
          if not __dragging

            if me.actorObjects[__drag_obj_index].getActor().hasPsyx()
              __drag_psyx = true
              me.actorObjects[__drag_obj_index].getActor().disablePsyx()

            __dragging = true

          if Math.abs(e.pageX - __drag_start_x) > __drag_tolerance \
          or Math.abs(e.pageY - __drag_start_y) > __drag_tolerance

            # Calc new coords (orig + offset)
            _newX = Number(__drag_orig_x + (e.pageX - __drag_start_x))

            # Note we need to invert the vertical offset
            _newY = Number(__drag_orig_y + ((e.pageY - __drag_start_y) * -1))

            # Update!
            me.actorObjects[__drag_obj_index].setPosition _newX, _newY

            # Update properties as well, if needed
            if __drag_update_props
              __drag_props.privvyIface "update_position", _newX, _newY

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

              # Update selected actor for use in AWidgetTimeline
              AWidgetWorkspace._selectedActor = o.getId()

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

  # Resizes the display outline
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

  # Takes other widgets into account, and sets the height accordingly. Also
  # centers the phone outline
  #
  # Note that this does NOT resize the canvas
  onResize: ->

    timelineBottom = Number($(".atimeline").css("bottom").split("px")[0]) - 16
    timelineHeight = ($(".atimeline").height() + timelineBottom)

    # Our height
    $(@_sel).height $(document).height() - $(".amainbar").height() + 2 - \
      timelineHeight

    # Center phone outline
    @updateOutline()

  @getSelectedActor: -> AWidgetWorkspace._selectedActor
