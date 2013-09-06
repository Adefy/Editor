# The main class, AdefyEditor instantiates everything else and gets things
# rolling.
#
# Dependencies are JQuery and JQuery UI
#
# @depend util/AUtilId.coffee
# @depend util/AUtilLog.coffee
# @depend util/AUtilParam.coffee
#
# Handles! Whoop!
# @depend handles/AHandle.coffee
# @depend handles/actors/AHBaseActor.coffee
# @depend handles/actors/AHTriangle.coffee
# @depend handles/actors/AHRectangle.coffee
# @depend handles/actors/AHNGon.coffee
#
# Widgets!
# @depend widgets/AWidget.coffee
# @depend widgets/AWidgetContextMenu.coffee
#
# @depend widgets/workspace/AWidgetWorkspace.coffee
#
# @depend widgets/controlbar/AWidgetControlBar.coffee
# @depend widgets/controlbar/AWidgetControlBarControl.coffee
# @depend widgets/controlbar/AWidgetControlCanvas.coffee
# @depend widgets/controlbar/AWidgetControlPhysics.coffee
# @depend widgets/controlbar/AWidgetControlRender.coffee
#
# @depend widgets/sidebar/AWidgetSidebar.coffee
# @depend widgets/sidebar/AWidgetSidebarObject.coffee
# @depend widgets/sidebar/AWidgetSidebarObjectGroup.coffee
# @depend widgets/sidebar/AWidgetSidebarProperties.coffee
#
# @depend widgets/mainbar/AWidgetMainbar.coffee
class AdefyEditor

  # Editor execution starts here. We spawn all other objects ourselves. If a
  # selector is not supplied, we go with #aeditor
  #
  # @param [String] sel container selector, created if non-existent
  constructor: (sel) ->

    # We can't run properly in Opera, as it does not let us override the
    # right-click context menu. Notify the user
    _agent = navigator.userAgent
    if _agent.search("Opera") != -1 || _agent.search("OPR") != -1
      alert "Opera does not fully support our editor, please use Chrome or FF!"

    # Dep check
    if window.jQuery == undefined or window.jQuery == null
      throw new Error "JQuery not found!"
    if $.ui == undefined or $.ui == null
      throw new Error "JQuery UI not found!"

    # CSS selector pointing to our DOM element
    @sel = param.optional sel, "#aeditor"
    log = AUtilLog

    # Array of widgets to be managed internally
    @widgets = []

    if $(@sel).length == 0
      log.warn "#{@sel} not found, creating it and continuing"
      $("body").prepend "<div id=\"#{@sel.replace('#', '')}\"></div>"

    me = @
    $(document).ready ->

      # Create mainbar first
      menubar = new AWidgetMainbar me.sel

      # Set up the menubar
      fileMenu = menubar.addItem "File"
      viewMenu = menubar.addItem "View"
      toolsMenu = menubar.addItem "Tools"
      helpMenu = menubar.addItem "Help"

      # File menu options
      fileMenu.createChild "New Ad..."
      fileMenu.createChild "New From Template...", null, true

      fileMenu.createChild "Save"
      fileMenu.createChild "Save As..."
      fileMenu.createChild "Export...", null, true

      fileMenu.createChild "Quit"

      # View menu options
      viewMenu.createChild "Toggle Objects Sidebar"
      viewMenu.createChild "Toggle Properties Sidebar"
      viewMenu.createChild "Toggle Controlbar", null, true

      viewMenu.createChild "Fullscreen"

      # Tools menu options
      toolsMenu.createChild "Preview..."
      toolsMenu.createChild "Calculate device support..."
      toolsMenu.createChild "Change canvas size..."

      # Help menu options
      helpMenu.createChild "About AdefyEditor"
      helpMenu.createChild "Changelog", null, true

      helpMenu.createChild "Take a Guided Tour"
      helpMenu.createChild "Quick Start"
      helpMenu.createChild "Tutorials"
      helpMenu.createChild "Documentation"

      menubar.render()

      # Create workspace and sidebars
      workspace = new AWidgetWorkspace me.sel
      leftSidebar = new AWidgetSidebar me.sel, "Objects", "left", 256
      rightSidebar = new AWidgetSidebar me.sel, "Properties", "right", 300
      controlBar = new AWidgetControlBar workspace

      # Add some items to the left sidebar
      testGroup = new AWidgetSidebarObjectGroup "Primitives", leftSidebar
      rectPrimitive = testGroup.createItem "Rectangle"
      ngonPrimitive = testGroup.createItem "N-Sided Polgyon"
      triPrimitive = testGroup.createItem "Triangle"

      rectPrimitive.dropped = (target, x, y) ->
        param.required target
        param.required x
        param.required y

        if target != "workspace" then return null

        new AHRectangle 100, 100, x, y

      ngonPrimitive.dropped = (target, x, y) ->
        param.required target
        param.required x
        param.required y

        if target != "workspace" then return null

        new AHNGon 5, 100, x, y

      triPrimitive.dropped = (target, x, y) ->
        param.required target
        param.required x
        param.required y

        if target != "workspace" then return null

        new AHTriangle 20, 30, x, y

      # Create a property widget on the right sidebar
      new AWidgetSidebarProperties rightSidebar

      # Set up workspace padding to take sidebars into account
      # NOTE: This needs to change in the future, to allow for sliding sidebars
      $(workspace.getSel()).css
        "padding-left": 256
        "padding-right": 300

      # Push widgets
      me.widgets.push menubar
      me.widgets.push workspace
      me.widgets.push leftSidebar
      me.widgets.push rightSidebar

      # Register resize handler
      me.onResize()
      $(window).resize -> me.onResize()

      # For some reason, it has to be called a second time for things to settle
      # properly (I'm looking at you AWidgetSidebar), so call it again
      setTimeout ->
        me.onResize()
      , 10

      log.info "Adefy editor created on #{me.sel}"

  # This function gets called immediately upon creation, and whenever
  # our parent element is resized. Other elements register listeners are to be
  # called within it
  onResize: ->
    for w in @widgets
      if w.onResize != undefined then w.onResize()

$(document).ready ->

  # Instantiate
  window.adefy_editor = new AdefyEditor
