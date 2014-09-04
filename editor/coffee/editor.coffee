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
      payload = window.ADEFY_EDITOR_CREATIVE_PAYLOAD
      @project = new Project @ui, payload, (p) => p.loadNewestSnapshot()
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
