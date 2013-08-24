# Workspace widget
#
# @depend AWidget.coffee
class AWidgetWorkspace extends AWidget

  # Set to true upon instantiation, prevents more than one instance
  @__exists: false

  # Creates a new workspace if one does not already exist
  #
  # @param [String] parent parent element selector
  constructor: (parent) ->

    if AWidgetWorkspace.__exists == true
      AUtilLog.warn "A workspace already exists, refusing to continue!"
      return

    AWidgetWorkspace.__exists = true

    param.required parent
    super "aworkspace", parent

  # Simply takes the navbar into account, and sets the height accordingly
  onResize: ->
    $(@sel).height $(window).height() - $("#amainbar").height()
