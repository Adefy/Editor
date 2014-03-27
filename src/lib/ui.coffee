define (requre) ->

  Toolbar = require "widgets/toolbar/toolbar"
  MenuBar = require "widgets/menubar/menubar"
  StatusBar = require "widgets/statusbar/statusbar"
  Timeline = require "widgets/timeline/timeline"
  Workspace = require "widgets/workspace/workspace"

  Sidebar = require "widgets/sidebar/sidebar"
  SidebarObjectGroup = require "widgets/sidebar/sidebar_object_group"
  SidebarPanel = require "widgets/sidebar/sidebar_panel"

  TabProperties = require "widgets/tabs/tab_properties"
  TabAssets = require "widgets/tabs/tab_assets"

  class UIManager

    constructor: ->
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
      @workspace = new Workspace @, @timeline

    initializeSidebar: ->
      @sidebar = new Sidebar @, 310

      propertiesPanel = new SidebarPanel @sidebar
      propertiesPanel.newTab "Properties", (tab) =>
        new TabProperties propertiesPanel

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

      ed = "window.editor"
      edUI = "window.editor.ui"

      # File menu options
      fileMenu.createChild "New Ad...", null, "#{ed}.newAd()"
      fileMenu.createChild "New From Template...", null, null, true

      fileMenu.createChild "Save", null, "#{ed}.save()"
      fileMenu.createChild "Save As..."
      fileMenu.createChild "Export...", null, "#{ed}.export()", true

      fileMenu.createChild "Quit"

      # View menu options
      viewMenu.createChild "Toggle Sidebar", null, \
        "#{edUI}.sidebar.toggle()"

      viewMenu.createChild "Fullscreen"

      # Timeline menu options
      timelineMenu.createChild "Set preview framerate...", null, \
        "#{edUI}.timeline.showSetPreviewRate()"

      # Canvas menu options
      canvasMenu.createChild "Set screen properties...", null, \
        "#{edUI}.workspace.showSetScreenProperties()"

      canvasMenu.createChild "Set background color...", null, \
        "#{edUI}.workspace.showSetBackgroundColor()"

      # Tools menu options
      toolsMenu.createChild "Preview..."
      toolsMenu.createChild "Calculate device support..."
      toolsMenu.createChild "Set export framerate..."
      toolsMenu.createChild "Upload textures...", null, \
        "#{edUI}.workspace.showAddTextures()"

      # Help menu options
      helpMenu.createChild "About Editor"
      helpMenu.createChild "Changelog", null, null, true

      helpMenu.createChild "Take a Guided Tour"
      helpMenu.createChild "Quick Start"
      helpMenu.createChild "Tutorials"
      helpMenu.createChild "Documentation"

      @menu
