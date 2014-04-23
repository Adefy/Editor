define (require) ->

  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"

  PropertyBar = require "widgets/property_bar"
  MenuBar = require "widgets/menubar/menubar"
  StatusBar = require "widgets/statusbar/statusbar"
  Timeline = require "widgets/timeline/timeline"
  Workspace = require "widgets/workspace/workspace"

  Sidebar = require "widgets/sidebar/sidebar"
  SidebarPanel = require "widgets/sidebar/sidebar_panel"

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
      @widgets.push @initializePropertyBar()
      @widgets.push @initializeTimeline()
      @widgets.push @initializeWorkspace()
      @widgets.push @initializeStatusbar()
      @widgets.push @initializeSidebar()

      @modals = new ModalManager @

      @refreshHard()

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

      $("section.main").height $(window).height() - \
                               $("header").height() - \
                               $("footer").height()

      for widget in @widgets
        widget.onResize() if widget.onResize

    renderAll: -> widget.render() for widget in @widgets

    initializePropertyBar: -> @propertyBar = new PropertyBar @
    initializeStatusbar: -> @statusbar = new StatusBar @, parent: "footer"
    initializeTimeline: -> @timeline = new Timeline @

    initializeWorkspace: ->
      throw new Error "Timeline required for workspace" unless @timeline
      @workspace = new Workspace @

    initializeSidebar: ->
      @sidebar = new Sidebar @, 310

      panel = new SidebarPanel @, parent: @sidebar
      panel.newTab "Textures", (tab) => new TexturesTab @, panel
      panel.selectTab 0

      @sidebar

    initializeMenu: ->

      @menu = new MenuBar @

      # Set up the @menu
      fileMenu = @menu.addItem "File"
      editMenu = @menu.addItem "Edit"
      viewMenu = @menu.addItem "View"
      canvasMenu = @menu.addItem "Canvas"
      toolsMenu = @menu.addItem "Tools"
      helpMenu = @menu.addItem "Help"

      ###
      #
      # File menu options
      #
      ###
      fileMenu.createChild
        label: "New Creative..."
        click: => @editor.fileNewAd()

      fileMenu.createChild
        label: "Open..."
        click: => @editor.fileOpen()
        sectionEnd: true

      fileMenu.createChild
        label: "Save"
        click: => @editor.fileSave()

      fileMenu.createChild
        label: "Save As..."
        click: => @editor.fileSaveAs()

      fileMenu.createChild
        label: "Export..."
        click: => @editor.fileExport()
        sectionEnd: true

      fileMenu.createChild
        label: "Preferences"
        click: => @modals.showPrefSettings()
        sectionEnd: true

      fileMenu.createChild
        label: "Quit"
        click: =>
          window.location.pathname = "/creatives/#{@editor.getProject().getId()}"

      ###
      #
      # Edit menu options
      #
      ###
      editMenu.createChild label: "Undo"
      editMenu.createChild label: "Redo"

      editMenu.createChild
        label: "History ..."
        sectionEnd: true
        click: => @modals.showEditHistory()

      editMenu.createChild label: "Copy"
      editMenu.createChild label: "Cut"
      editMenu.createChild label: "Paste", sectionEnd: true

      ###
      #
      # View menu options
      #
      ###
      viewMenu.createChild
        label: "Toggle Sidebar"
        click: => @sidebar.toggle()

      viewMenu.createChild
        label: "Toggle Timeline"
        click: => @timeline.toggle()
        sectionEnd: true

      viewMenu.createChild
        label: "Fullscreen"
        click: => @toggleFullScreen()
        sectionEnd: true

      viewMenu.createChild
        label: "Refresh"
        click: =>
          @refresh()
          @onResize()
        sectionEnd: true

      ###
      #
      # Canvas menu options
      #
      ###
      canvasMenu.createChild
        label: "Set Screen Properties ..."
        click: => @modals.showSetScreenProperties()

      canvasMenu.createChild
        label: "Set Background Color ..."
        click: => @modals.showSetBackgroundColor()

      ###
      #
      # Tools menu options
      #
      ###
      toolsMenu.createChild label: "Preview ..."
      toolsMenu.createChild label: "Calculate device support ..."

      toolsMenu.createChild
        label: "Set Export Framerate ..."
        click: => @modals.showSetExportRate()

      toolsMenu.createChild
        label: "Upload textures ..."
        click: => @modals.showUploadTextures()

      ###
      #
      # Help menu options
      #
      ###
      helpMenu.createChild
        label: "About Editor"
        click: => @modals.showHelpAbout()

      helpMenu.createChild
        label: "Changelog"
        click: => @modals.showHelpChangeLog()
        sectionEnd: true

      helpMenu.createChild label: "Take a Guided Tour"
      helpMenu.createChild label: "Quick Start"
      helpMenu.createChild label: "Tutorials"
      helpMenu.createChild label: "Documentation"

      @menu

    ###
    # @return [self]
    ###
    refreshStub: ->
      AUtilLog.info "UI refreshStub"
      for widget in @widgets
        widget.refreshStub() if widget.refreshStub

      @

    ###
    # @return [self]
    ###
    refresh: ->
      AUtilLog.info "UI#refresh"
      for widget in @widgets
        widget.refresh() if widget.refresh

      @

    ###
    # @return [self]
    ###
    postInit: ->
      AUtilLog.info "UI#postInit"
      for widget in @widgets
        widget.postInit() if widget.postInit

      @

    ###
    # @return [self]
    ###
    postRefresh: ->
      AUtilLog.info "UI#postRefresh"
      for widget in @widgets
        widget.postRefresh() if widget.postRefresh

      @

    ###
    # @return [self]
    ###
    refreshHard: ->
      @refreshStub() # create widget stubs
      @refresh()     # render the widget content
      @postRefresh() # conduct all post refresh shebang
      @onResize()    # ensure that all widgets have the correct size
      @postInit()    # finish initializing the widgets
      @

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

