define (require) ->

  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"

  Toolbar = require "widgets/toolbar/toolbar"
  MenuBar = require "widgets/menubar/menubar"
  StatusBar = require "widgets/statusbar/statusbar"
  Timeline = require "widgets/timeline/timeline"
  Workspace = require "widgets/workspace/workspace"

  Sidebar = require "widgets/sidebar/sidebar"
  SidebarPanel = require "widgets/sidebar/sidebar_panel"

  PropertiesTab = require "widgets/tabs/tab_properties"
  AssetsTab = require "widgets/tabs/tab_assets"
  TexturesTab = require "widgets/tabs/tab_textures"

  ModalManager = require "modal_manager"

  class UIManager

    constructor: (@editor) ->

      if UIManager.instance
        throw new Error "UIManager already instantiated!"
      else
        UIManager.instance = @

      @widgets = []

      @widgets.push @initializeMenu()
      @widgets.push @initializeToolbar()
      @widgets.push @initializeTimeline()
      @widgets.push @initializeWorkspace()
      @widgets.push @initializeStatusbar()
      @widgets.push @initializeSidebar()

      @modals = new ModalManager @

      @renderAll()

      @onResize()
      window.onresize = @onResize

    ###
    # swiped from:
    # http://xparkmedia.com/blog/enter-fullscreen-mode-javascript/
    ###
    toggleFullScreen: ->

      if (document.fullScreenElement && document.fullScreenElement != null) || \
       (!document.mozFullScreen && !document.webkitIsFullScreen)
        if document.documentElement.requestFullScreen
          document.documentElement.requestFullScreen()
        else if document.documentElement.mozRequestFullScreen
          document.documentElement.mozRequestFullScreen()
        else if document.documentElement.webkitRequestFullScreen
          document.documentElement.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT)
      else
        if document.cancelFullScreen
          document.cancelFullScreen()
        else if document.mozCancelFullScreen
          document.mozCancelFullScreen()
        else if document.webkitCancelFullScreen
          document.webkitCancelFullScreen()

    onResize: =>

      for widget in @widgets
        widget.onResize() if widget.onResize

    renderAll: -> widget.render() for widget in @widgets

    initializeToolbar: -> @toolbar = new Toolbar @

    initializeStatusbar: -> @statusbar = new StatusBar @

    initializeTimeline: -> @timeline = new Timeline @

    initializeWorkspace: ->

      throw new Error "Timeline required for workspace" unless @timeline
      @workspace = new Workspace @

    initializeSidebar: ->

      @sidebar = new Sidebar @, 310

      propertiesPanel = new SidebarPanel @sidebar

      propertiesPanel.newTab "Properties", (tab) =>
        new PropertiesTab @, propertiesPanel

      #propertiesPanel.newTab "Assets", (tab) =>
      #  new AssetsTab @, propertiesPanel

      propertiesPanel.newTab "Textures", (tab) =>
        new TexturesTab @, propertiesPanel

      propertiesPanel.selectTab 0

      @sidebar

    initializeMenu: ->

      @menu = new MenuBar @

      # Set up the @menu
      fileMenu = @menu.addItem "File"
      editMenu = @menu.addItem "Edit"
      viewMenu = @menu.addItem "View"
      timelineMenu = @menu.addItem "Timeline"
      canvasMenu = @menu.addItem "Canvas"
      toolsMenu = @menu.addItem "Tools"
      prefMenu = @menu.addItem "Preferences"
      helpMenu = @menu.addItem "Help"

      editor = "window.AdefyEditor"
      editorUI = "#{editor}.ui"

      ###
      #
      # File menu options
      #
      ###
      fileMenu.createChild
        label: "New Ad ..."
        click: "#{editor}.fileNewAd()"

      fileMenu.createChild
        label: "New From Template ..."
        click: "#{editor}.fileNewFromTemplate()"
        sectionEnd: true

      fileMenu.createChild
        label: "Open"
        click: "#{editor}.fileOpen()"
        sectionEnd: true

      fileMenu.createChild
        label: "Save"
        click: "#{editor}.fileSave()"

      fileMenu.createChild
        label: "Save As..."
        click: "#{editor}.fileSaveAs()"
        sectionEnd: true

      fileMenu.createChild
        label: "Export..."
        click: "#{editor}.fileExport()"
        sectionEnd: true

      # and why would we even need this...
      #fileMenu.createChild
      #  label: "Quit"

      ###
      #
      # Edit menu options
      #
      ###
      editMenu.createChild
        label: "Undo"

      editMenu.createChild
        label: "Redo"

      editMenu.createChild
        label: "History ..."
        sectionEnd: true
        click: "#{editorUI}.modals.showEditHistory()"

      editMenu.createChild
        label: "Copy"

      editMenu.createChild
        label: "Cut"

      editMenu.createChild
        label: "Paste"
        sectionEnd: true

      editMenu.createChild
        label: "Project ..."
        sectionEnd: true

      ###
      #
      # View menu options
      #
      ###
      viewMenu.createChild
        label: "Toggle Sidebar"
        click: "#{editorUI}.sidebar.toggle()"

      viewMenu.createChild
        label: "Toggle Timeline"
        click: "#{editorUI}.timeline.toggle()"
        sectionEnd: true

      viewMenu.createChild
        label: "Fullscreen"
        click: "#{editorUI}.toggleFullScreen()"
        sectionEnd: true

      viewMenu.createChild
        label: "Refresh"
        click: "#{editorUI}.refresh()"
        sectionEnd: true

      ###
      #
      # Timeline menu options
      #
      ###
      timelineMenu.createChild
        label: "Set Preview Framerate ..."
        click: "#{editorUI}.modals.showSetPreviewRate()"

      ###
      #
      # Canvas menu options
      #
      ###
      canvasMenu.createChild
        label: "Set Screen Properties ..."
        click: "#{editorUI}.modals.showSetScreenProperties()"

      canvasMenu.createChild
        label: "Set Background Color ..."
        click: "#{editorUI}.modals.showSetBackgroundColor()"

      ###
      #
      # Tools menu options
      #
      ###
      toolsMenu.createChild
        label: "Preview ..."

      toolsMenu.createChild
        label: "Calculate device support ..."

      toolsMenu.createChild
        label: "Set Export Framerate ..."
        click: "#{editorUI}.modals.showSetExportRate()"

      toolsMenu.createChild
        label: "Upload textures ..."
        click: "#{editorUI}.modals.showUploadTextures()"

      ###
      #
      # Preferences menu options
      #
      ###
      prefMenu.createChild
        label: "Settings"
        click: "#{editorUI}.modals.showPrefSettings()"

      ###
      #
      # Help menu options
      #
      ###
      helpMenu.createChild
        label: "About Editor"
        click: "#{editorUI}.modals.showHelpAbout()"

      helpMenu.createChild
        label: "Changelog"
        click: "#{editorUI}.modals.showHelpChangeLog()"
        sectionEnd: true

      helpMenu.createChild
        label: "Take a Guided Tour"

      helpMenu.createChild
        label: "Quick Start"

      helpMenu.createChild
        label: "Tutorials"

      helpMenu.createChild
        label: "Documentation"

      @menu

    refresh: ->

      AUtilLog.info "UI refresh"

      for widget in @widgets
        widget.refresh() if widget.refresh

    ###
    ## UES - UI Event System
    ###

    ###
    # Adds a new event
    # @param [String] type
    # @param [Object] params
    ###
    pushEvent: (type, params) ->

      unless @_ignoreEventList == null || @_ignoreEventList == undefined
        if _.include @_ignoreEventList, type
          return AUtilEventLog.ignore "ui", type

      AUtilEventLog.epush "ui", type

      ## we should probably fine tune this later
      for widget in @widgets
        widget.respondToEvent type, params if widget.respondToEvent

      ##
      # more debugging stuff
      @_eventStats ||= {}
      if @_eventStats[type] == null || @_eventStats[type] == undefined
        @_eventStats[type] = 0
      @_eventStats[type]++

    ###
    # Allows incoming event of (type)
    # @param [String] type
    ###
    allowEvent: (type) ->

      if @_ignoreEventList == null || @_ignoreEventList == undefined
        return

      index = @_ignoreEventList.indexOf(type)
      @_ignoreEventList.splice index, 1

    ###
    # Blocks incoming event of (type)
    # @param [String] type
    ###
    ignoreEvent: (type) ->

      if @_ignoreEventList == null || @_ignoreEventList == undefined
        @_ignoreEventList = []

      @_ignoreEventList.push type
