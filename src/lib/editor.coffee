define (require) ->

  config = require "config"
  param = require "util/param"
  AUtilLog = require "util/log"

  Storage = require "storage"
  UIManager = require "ui"
  Project = require "project"

  PolygonActor = require "handles/actors/polygon"
  RectangleActor = require "handles/actors/rectangle"
  Bezier = require "handles/bezier"

  class Editor

    ###
    # Last active instance of the Editor
    # @type [Editor] current
    ###
    @current: null

    ###
    # Editor execution starts here. We spawn all other objects ourselves. If a
    # selector is not supplied, we go with #editor
    #
    # @param [String] sel container selector, created if non-existent
    ###
    constructor: (sel) ->
      Editor.current = @

      return if @checkForOpera()
      return unless @checkForLocalStorage()
      return unless @checkForCreativePayload()

      @widgets = []
      @ui = new UIManager @

      ###
      # @type [Object] clipboard
      #   @property [String] type what is in the clipboard
      #   @property [String] reason why is this content in the clipboard
      #   @property [Object] data contents of the clipboard
      ###
      @clipboard = null

      ###
      # @type [Object] settings
      ###
      @settings = {}
      @refreshSettings()

      AUtilLog.debug "Adefy Editor created"

    ###
    # Call after creating the editor, this ensures the top level is set
    # @return [self]
    ###
    init: ->
      @project = new Project @ui, window.ADEFY_EDITOR_CREATIVE_PAYLOAD, (p) =>
        p.loadNewestSnapshot()

      @startAutosaveTask()

      @

    ###
    # Get currently loaded project
    #
    # @return [Project] project
    ###
    getProject: -> @project

    ###
    # We can't run properly in Opera, as it does not let us override the
    # right-click context menu. Notify the user
    #
    # @return [Boolean] isOpera
    ###
    checkForOpera: ->
      agent = navigator.userAgent

      if agent.search("Opera") != -1 or agent.search("OPR") != -1
        alert "Opera is not supported at this time, you may experience problems"
        true
      else
        false

    ###
    # Ensure that a creative payload is attached to the window
    #
    # @return [Boolean] havePayload
    ###
    checkForCreativePayload: ->
      unless !!window.ADEFY_EDITOR_CREATIVE_PAYLOAD
        alert "Something went wrong, no creative loaded ;("
        false
      else
        true

    ###
    # Check that the browser supports HTML local storage
    # @return [Boolean]
    ###
    checkForLocalStorage: ->
      unless window.localStorage
        alert """
          Your browser does not support HMTL5 local storage ;(
          Please use a modern, evergreen browser like Chrome or Firefox
        """
        return false

      true

    ###
    # @return [Void]
    ###
    refreshSettings: ->
      @settings.autosave =
        # How often should we autosave? (milliseconds)
        frequency: Number(Storage.get("editor.autosave.frequency") || 50000)
        # How many saves should we keep at a time?
        maxcount: Number(Storage.get("editor.autosave.maxcount") || 10)

    ###
    # @return [self]
    ###
    applySettings: (options) ->
      restartAutosave = false

      if autosaveData
        freq = autosaveData.frequency or @settings.autosave.frequency

        if freq
          @settings.autosave.frequency = freq
          restartAutosave = true

        maxcount = autosaveData.maxcount or @settings.autosave.maxcount
        @settings.autosave.maxcount = maxcount

      @startAutosaveTask() if restartAutosave

      @saveSettings()
      @

    ###
    # Saves the settings to Local Storage
    # @return [Void]
    ###
    saveSettings: ->
      Storage.set("editor.autosave.frequency", @settings.autosave.frequency)
      Storage.set("editor.autosave.maxcount", @settings.autosave.maxcount)
      #Storage.set("are.renderer.mode", @settings.are.rendererMode)

      AUtilLog.debug "Saved editor.settings"

      @

    ###
    # Update state snapshot and save it in storage
    ###
    save: ->
      @project.save()
      @

    ###
    ###
    autosave: ->
      AUtilLog.debug "[Editor] autosaving current project"
      AUtilLog.debug "[Editor] autosave is disabled"
      #@project.autosave()
      #@project.snapshot()
      @

    ###
    # Clears the workspace, creating a new ad
    ###
    newAd: ->
      # replace current project
      @project = new Project @ui
      ##
      # Trigger a workspace reset
      @ui.workspace.reset()
      @

    ###
    # I really thought this would be sexier, expecting that we could simply
    # build a function that when executed recreates our ad, and stringify it.
    # Turns out we can't. Sadness. We can, we just can't easily set arguments.
    #
    # Sooooo, we literally build the resultant ad line-by-line. Not as bad as it
    # sounds.
    #
    # @return [String] export
    ###
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
        buff = a.getBufferEntry a.getBirthTime()

        pos = buff.position.components
        col = buff.color.components

        birthOpts.rotation = buff.rotation.value
        birthOpts.position = { x: pos.x.value - pOffX, y: pos.y.value - pOffY }
        birthOpts.color = { r: col.r.value, g: col.g.value, b: col.b.value }

        if a instanceof PolygonActor
          type = "AJSPolygon"
          birthOpts.radius = buff.radius.value
          birthOpts.segments = buff.sides.value

        else if a instanceof RectangleActor
          type = "AJSRectangle"
          birthOpts.w = buff.width.value
          birthOpts.h = buff.height.value

        # This shouldn't happen, but just in case, log, notify and skip
        if type.length == 0
          AUtilLog.warn "Unrecognized actor, can't export: #{a._id}"
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
        return if result.error

        # Show a modal dialog offering to view, or download the export
        _html =  ""
        _html += "<a href=\"#{result.link}\" target=\"_blank\">View</a>"
        _html += " or "
        _html += "<a href=\"#{result.link}?download=yes\">Download</a>"

        # new Modal title: "Exported", content: _html

    ###
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
    ###
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
        animName = window.AdefyRE.Animations().getAnimationName _pName

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

        else if animName == "physics"
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


    ## File Menu Commands

    ###
    # Create a new Ad
    # @return [self]
    ###
    fileNewAd: ->
      @newAd()
      @

    ###
    # Create a new Ad from Template
    # @return [self]
    ###
    fileNewFromTemplate: ->
      #
      @

    ###
    # Open an existing ad
    # @return [self]
    ###
    fileOpen: ->
      @ui.modals.showOpenProject()
      @

    ###
    # Save current ad
    # @return [self]
    ###
    fileSave: ->
      @save()
      @

    ###
    # Save current ad, with new name
    # @return [self]
    ###
    fileSaveAs: ->
      @

    ###
    # Export the current ad
    # @return [self]
    ###
    fileExport: ->
      @export()
      @

    ###
    # @return [self]
    ###
    startAutosaveTask: ->
      AUtilLog.debug "Starting autosave task"

      clearInterval @autosaveTaskID if @autosaveTaskID

      @autosaveTaskID = setInterval =>
        @autosave()
        @ui.pushEvent "autosave"
      , @settings.autosave.frequency

      @
