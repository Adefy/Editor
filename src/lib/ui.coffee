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
      viewMenu = @menu.addItem "View"
      timelineMenu = @menu.addItem "Timeline"
      canvasMenu = @menu.addItem "Canvas"
      toolsMenu = @menu.addItem "Tools"
      helpMenu = @menu.addItem "Help"

      ed = "window.AdefyEditor"
      edUI = "#{ed}.ui"

      ##
      # File menu options
      fileMenu.createChild
        label: "New Ad..."
        click: "#{ed}.newAd()"

      fileMenu.createChild
        label: "New From Template..."
        sectionEnd: true

      fileMenu.createChild
        label: "Save"
        click: "#{ed}.save()"

      fileMenu.createChild
        label: "Save As..."

      fileMenu.createChild
        label: "Export..."
        click: "#{ed}.export()"
        sectionEnd: true

      fileMenu.createChild
        label: "Quit"

      ##
      # View menu options
      viewMenu.createChild
        label: "Toggle Sidebar"
        click: "#{edUI}.sidebar.toggle()"

      viewMenu.createChild
        label: "Toggle Timeline"
        click: "#{edUI}.timeline.toggle()"
        sectionEnd: true

      viewMenu.createChild
        label: "Fullscreen"
        click: "#{edUI}.toggleFullScreen()"
        sectionEnd: true

      viewMenu.createChild
        label: "Refresh"
        click: "#{edUI}.refresh()"
        sectionEnd: true

      ##
      # Timeline menu options
      timelineMenu.createChild
        label: "Set preview framerate..."
        click: "#{edUI}.modals.showSetPreviewRate()"

      ##
      # Canvas menu options
      canvasMenu.createChild
        label: "Set screen properties..."
        click: "#{edUI}.modals.showSetScreenProperties()"

      ##
      #
      canvasMenu.createChild
        label: "Set background color..."
        click: "#{edUI}.modals.showSetBackgroundColor()"

      ##
      # Tools menu options
      toolsMenu.createChild
        label: "Preview..."

      toolsMenu.createChild
        label: "Calculate device support..."

      toolsMenu.createChild
        label: "Set export framerate..."

      toolsMenu.createChild
        label: "Upload textures..."
        #click: "#{edUI}.modals.showAddTextures()"
        click: "#{edUI}.modals.showUploadTextures()"

      ##
      # Help menu options
      helpMenu.createChild
        label: "About Editor"
        click: "#{edUI}.modals.showHelpAbout()"

      helpMenu.createChild
        label: "Changelog"
        click: "#{edUI}.modals.showHelpChangeLog()"
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
