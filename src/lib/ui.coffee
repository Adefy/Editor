define (requre) ->

  Toolbar = require "widgets/toolbar/toolbar"
  MenuBar = require "widgets/menubar/menubar"
  StatusBar = require "widgets/statusbar/statusbar"
  Timeline = require "widgets/timeline/timeline"
  Workspace = require "widgets/workspace/workspace"

  Sidebar = require "widgets/sidebar/sidebar"
  SidebarPanel = require "widgets/sidebar/sidebar_panel"

  PropertiesTab = require "widgets/tabs/tab_properties"
  AssetsTab = require "widgets/tabs/tab_assets"

  class UIManager

    constructor: ->
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

      @renderAll()

      @onResize()
      window.onresize = @onResize

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

      propertiesPanel.newTab "Textures", (tab) =>
        new AssetsTab @, propertiesPanel

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

      # View menu options
      viewMenu.createChild
        label: "Toggle Sidebar"
        click: "#{edUI}.sidebar.toggle()"

      viewMenu.createChild
        label: "Fullscreen"

      # Timeline menu options
      timelineMenu.createChild
        label: "Set preview framerate..."
        click: "#{edUI}.timeline.showSetPreviewRate()"

      # Canvas menu options
      canvasMenu.createChild
        label: "Set screen properties..."
        click: "#{edUI}.workspace.showSetScreenProperties()"

      canvasMenu.createChild
        label: "Set background color..."
        click: "#{edUI}.workspace.showSetBackgroundColor()"

      # Tools menu options
      toolsMenu.createChild
        label: "Preview..."

      toolsMenu.createChild
        label: "Calculate device support..."

      toolsMenu.createChild
        label: "Set export framerate..."

      toolsMenu.createChild
        label: "Upload textures..."
        click: "#{edUI}.workspace.showAddTextures()"

      # Help menu options
      helpMenu.createChild
        label: "About Editor"
        click: "#{edUI}.modals.showAbout()"

      helpMenu.createChild
        label: "Changelog"
        click: "#{edUI}.modals.showChangeLog()"
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

    ## UES - UI Event System

    ###
    # Adds a new event
    # @param [String] type
    # @param [Object] params
    ###
    pushEvent: (type, params) ->
      unless @_ignoreEventList == null || @_ignoreEventList == undefined
        return if _.include @_ignoreEventList, type

      console.log "event: #{type}"
      ## we should probably fine tune this later
      for widget in @widgets
        widget.respondToEvent type, params if widget.respondToEvent

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