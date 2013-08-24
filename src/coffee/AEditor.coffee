# The main class, AdefyEditor instantiates everything else and gets things
# rolling. The only dependency at this point is Zepto.
#
# @depend util/AUtilLog.coffee
class AdefyEditor

  # @property [String] CSS selector pointing to our DOM element
  sel: null

  # Editor execution starts here. We spawn all other objects ourselves
  constructor: (@sel) ->

    log = AUtilLog

    # We expect the selector to exist. If it doesn't, we ship a warning and
    # create our own anyways (brutality ftw)
    if @sel == undefined or @sel == null
      log.warn "No selector providing, continuing with #aeditor"
      @sel = "#aeditor"

    if $(@sel).length == 0
      log.warn "#{@sel} not found, creating it and continuing"
      $("body").prepend "<div id=\"#{sel}\"></div>"

    # Dep check
    if window.Zepto == undefined or window.Zepto == null
      throw new Error "Zepto not found!"

    # Register resize handler
    AdefyEditor.onResize()

    log.info "Adefy editor created on #{@sel}"

  # This function gets called immediately upon creation, and whenever
  # our parent element is resized. Other elements register listeners to be
  # called within it, hence it being static.
  @onResize: ->

# Instantiate
window.adefy_editor = new AdefyEditor
