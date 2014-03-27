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
    initializeToolbar: -> @toolbar = new Toolbar
    initializeStatusbar: -> @statusbar = new StatusBar
    initializeTimeline: -> @timeline = new Timeline
    initializeWorkspace: ->
      throw new Error "Timeline required for workspace" unless @timeline
      @workspace = new Workspace @timeline

    initializeSidebar: ->
      @sidebar = new Sidebar "Sidebar", "left", 310

      ###
      panel = new SidebarPanel sidebar
      panel.newTab "Assets", (tab) =>
        tabAssets = new TabAssets panel
        file1 =
          file:
            name: "Ad.jpg"

        file2 =
          file:
            name: "Some.txt"

        diEmpty =
          directory:
            name: "TestDirectory"
            assets: []
            unfolded: false

        diFil =
          directory:
            name: "TestDirectory"
            assets: [diEmpty, diEmpty, file1]
            unfolded: false

        tabAssets._assets.push
          directory:
            name: "Directory1"
            assets: []
            unfolded: false

        tabAssets._assets.push
          directory:
            name: "Directory2"
            assets: [file2]
            unfolded: true

        tabAssets._assets.push
          directory:
            name: "Directory3"
            assets: [diEmpty, diFil, diFil, diEmpty, file2]
            unfolded: true

        tabAssets._assets.push
          directory:
            name: "Directory4"
            assets: [diFil, diFil, file2]
            unfolded: false

        tabAssets

      panel.newTab "Tab2"
      panel.newTab "Tab3"
      ###

      # panel.selectTab 0

      panel2 = new SidebarPanel @sidebar
      panel2.newTab "Properties", (tab) =>
        new TabProperties panel2

      panel2.selectTab 0

      @sidebar

    initializeMenu: ->
      @menu = new MenuBar

      # Set up the @menu
      fileMenu = @menu.addItem "File"
      viewMenu = @menu.addItem "View"
      timelineMenu = @menu.addItem "Timeline"
      canvasMenu = @menu.addItem "Canvas"
      toolsMenu = @menu.addItem "Tools"
      helpMenu = @menu.addItem "Help"

      ed = "window.adefy_editor"

      # File menu options
      fileMenu.createChild "New Ad...", null, "#{ed}.newAd()"
      fileMenu.createChild "New From Template...", null, null, true

      fileMenu.createChild "Save", null, "#{ed}.save()"
      fileMenu.createChild "Save As..."
      fileMenu.createChild "Export...", null, "#{ed}.export()", true

      fileMenu.createChild "Quit"

      # View menu options
      viewMenu.createChild "Toggle Sidebar", null, \
        "window.sidebar.toggle()"

      viewMenu.createChild "Fullscreen"

      # Timeline menu options
      timelineMenu.createChild "Set preview framerate...", null, \
        "window.timeline.showSetPreviewRate()"

      # Canvas menu options
      canvasMenu.createChild "Set screen properties...", null, \
        "window.workspace.showSetScreenProperties()"

      canvasMenu.createChild "Set background color...", null, \
        "window.workspace.showSetBackgroundColor()"

      # Tools menu options
      toolsMenu.createChild "Preview..."
      toolsMenu.createChild "Calculate device support..."
      toolsMenu.createChild "Set export framerate..."
      toolsMenu.createChild "Upload textures...", null, \
        "window.workspace.showAddTextures()"

      # Help menu options
      helpMenu.createChild "About Editor"
      helpMenu.createChild "Changelog", null, null, true

      helpMenu.createChild "Take a Guided Tour"
      helpMenu.createChild "Quick Start"
      helpMenu.createChild "Tutorials"
      helpMenu.createChild "Documentation"

      @menu
