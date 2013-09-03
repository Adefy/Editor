# The main class, AdefyEditor instantiates everything else and gets things
# rolling.
#
# Dependencies are JQuery and JQuery UI
#
# @depend util/AUtilId.coffee
# @depend util/AUtilLog.coffee
# @depend util/AUtilParam.coffee
#
# Manipulatables! Whoop!
# @depend manipulatable/AManipulatable.coffee
# @depend manipulatable/actors/AMBaseActor.coffee
# @depend manipulatable/actors/AMTriangle.coffee
# @depend manipulatable/actors/AMRectangle.coffee
# @depend manipulatable/actors/AMNGon.coffee
#
# Widgets!
# @depend widgets/AWidget.coffee
# @depend widgets/AWidgetWorkspace.coffee
# @depend widgets/AWidgetContextMenu.coffee
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
      menubar.addItem "File"
      menubar.addItem "Edit"
      fileMenu = menubar.addItem "View"
      menubar.addItem "Tools"
      menubar.addItem "Help"

      fileMenu.createChild "Test item 1"
      fileMenu.createChild "Test item 2"
      fileMenu.createChild "Test item 3"
      fileMenu.createChild "Test item 4"
      fileMenu.createChild "Test item 5"
      fileMenu.createChild "Test item 6"
      fileMenu.createChild "Test item 7"
      fileMenu.createChild "Test item 8"

      menubar.render()

      # Create workspace and sidebars
      workspace = new AWidgetWorkspace me.sel
      leftSidebar = new AWidgetSidebar me.sel, "Objects", "left", 256
      rightSidebar = new AWidgetSidebar me.sel, "Properties", "right", 300

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

        new AMRectangle 100, 100, x, y

      ngonPrimitive.dropped = (target, x, y) ->
        param.required target
        param.required x
        param.required y

        if target != "workspace" then return null

        new AMNGon 5, 100, x, y

      triPrimitive.dropped = (target, x, y) ->
        param.required target
        param.required x
        param.required y

        if target != "workspace" then return null

        new AMTriangle 20, 30, x, y

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
