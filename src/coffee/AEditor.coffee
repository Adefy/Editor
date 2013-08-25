# The main class, AdefyEditor instantiates everything else and gets things
# rolling.
#
# Dependencies are JQuery and JQuery UI
#
# @depend util/AUtilLog.coffee
# @depend util/AUtilParam.coffee
# @depend widgets/AWidgetWorkspace.coffee
# @depend widgets/AWidgetSidebar.coffee
# @depend widgets/AWidgetMainbar.coffee
class AdefyEditor

  # Editor execution starts here. We spawn all other objects ourselves. If a
  # selector is not supplied, we go with #aeditor
  #
  # @param [String] sel container selector, created if non-existent
  constructor: (sel) ->

    # Array of widgets to be managed internally
    @widgets = []

    # Dep check
    if window.jQuery == undefined or window.jQuery == null
      throw new Error "JQuery not found!"

    # CSS selector pointing to our DOM element
    @sel = param.optional sel, "#aeditor"
    log = AUtilLog

    if $(@sel).length == 0
      log.warn "#{@sel} not found, creating it and continuing"
      $("body").prepend "<div id=\"#{@sel.replace('#', '')}\"></div>"

    # Create widgets
    menubar = new AWidgetMainbar @sel
    workspace = new AWidgetWorkspace @sel
    leftSidebar = new AWidgetSidebar @sel, "left", 200
    rightSidebar = new AWidgetSidebar @sel, "right", 300

    # Set up the menubar
    fileMenu = menubar.addItem "File"
    menubar.addItem "Edit"
    menubar.addItem "View"
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

    # Push widgets
    @widgets.push menubar
    @widgets.push workspace
    @widgets.push leftSidebar
    @widgets.push rightSidebar

    # Register resize handler
    me = @
    @onResize()
    $(window).resize -> me.onResize()

    log.info "Adefy editor created on #{@sel}"

  # This function gets called immediately upon creation, and whenever
  # our parent element is resized. Other elements register listeners are to be
  # called within it
  onResize: ->
    for w in @widgets
      if w.onResize != undefined then w.onResize()

$(document).ready ->

  # Instantiate
  window.adefy_editor = new AdefyEditor
