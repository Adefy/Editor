define (require) ->

  config = require "config"
  AUtilLog = require "util/log"
  param = require "util/param"

  Storage = require "storage"

  PolygonActor = require "handles/actors/polygon"
  TriangleActor = require "handles/actors/triangle"
  RectangleActor = require "handles/actors/rectangle"

  UIManager = require "ui"

  Notification = require "widgets/notification"

  Bezier = require "widgets/timeline/bezier"
  Project = require "project"

  class Editor

    ###
    # Editor execution starts here. We spawn all other objects ourselves. If a
    # selector is not supplied, we go with #editor
    #
    # @param [String] sel container selector, created if non-existent
    ###
    constructor: (sel) ->

      @checkForOpera()
      @checkForLocalStorage()

      @widgets = []

      @ui = new UIManager @

      AUtilLog.info "Adefy Editor created id(#{config.selector})"

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

      Project.ui = @ui
      if Project.quicksaveExists()
        @project = Project.quickload()
      else
        @project = new Project @ui

    ###
    # We can't run properly in Opera, as it does not let us override the
    # right-click context menu. Notify the user
    #
    # @return [Boolean]
    ###
    checkForOpera: ->
      agent = navigator.userAgent

      if agent.search("Opera") != -1 or agent.search("OPR") != -1
        alert "Opera is not supported at this time, you may experience problems"
        return true

      false

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
        # How often should we autosave?
        frequency: Number(Storage.get("editor.autosave.frequency")) || 50000
        # How many saves should we keep at a time?
        maxcount: Number(Storage.get("editor.autosave.maxcount")) || 10

    ###
    # Saves the settings to Local Storage
    # @return [Void]
    ###
    saveSettings: ->
      Storage.set("editor.autosave.frequency", @settings.frequency)
      Storage.set("editor.autosave.maxcount", @settings.maxcount)

    ###
    # Update state snapshot and save it in storage
    ###
    save: ->
      @project.save()
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
        buff = a.getBufferEntry a.lifetimeStart_ms

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
    ###
    fileNewAd: ->
      @newAd()
      @

    ###
    # Create a new Ad from Template
    ###
    fileNewFromTemplate: ->
      #
      @

    ###
    # Open an existing ad
    ###
    fileOpen: ->
      #
      @

    ###
    # Save current ad
    ###
    fileSave: ->
      @save()
      @

    ###
    # Save current ad, with new name
    ###
    fileSaveAs: ->
      @

    ###
    # Export the current ad
    ###
    fileExport: ->
      @export()
      @
