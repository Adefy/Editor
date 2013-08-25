# The main class, AdefyEditor instantiates everything else and gets things
# rolling.
#
# Dependencies are Zepto and Handlebars
#
# @depend util/AUtilLog.coffee
# @depend util/AUtilParam.coffee
# @depend widgets/AWidgetWorkspace.coffee
# @depend widgets/AWidgetSidebar.coffee
# @depend widgets/AWidgetMainbar.coffee
class AdefyEditor

  # @property [String] CSS selector pointing to our DOM element
  sel: null

  # @property [Array<AWidget>] array of widgets to be managed internally
  widgets: []

  # Editor execution starts here. We spawn all other objects ourselves. If a
  # selector is not supplied, we go with #aeditor
  #
  # @param [String] sel container selector, created if non-existent
  constructor: (sel) ->

    # Dep check
    if window.Zepto == undefined or window.Zepto == null
      throw new Error "Zepto not found!"
    if window.Handlebars == undefined or window.Handlebars == null
      throw new Error "Handlebars not found!"

    @sel = param.optional sel, "#aeditor"
    log = AUtilLog

    if $(@sel).length == 0
      log.warn "#{@sel} not found, creating it and continuing"
      $("body").prepend "<div id=\"#{@sel.replace('#', '')}\"></div>"

    # Create widgets
    menubar = new AWidgetMainbar @sel
    workspace = new AWidgetWorkspace @sel

    # Set up the menubar
    fileMenu = menubar.addItem "File"
    menubar.addItem "Edit"
    menubar.addItem "View"
    menubar.addItem "Tools"
    menubar.addItem "Help"

    save = fileMenu.createChild "Save"

    menubar.render()

    # Push widgets
    @widgets.push menubar
    @widgets.push workspace

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
