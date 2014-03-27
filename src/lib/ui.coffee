define (requre) ->

  MenuBar = require "widgets/menubar/menubar"

  class UIManager

    constructor: ->
      @initializeMenu()

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

      @menu.render()
