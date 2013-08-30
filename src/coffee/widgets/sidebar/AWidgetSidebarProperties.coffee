# Properties widget, dynamically refreshable
#
# @depend AWidgetSidebarItem.coffee
class AWidgetSidebarProperties extends AWidgetSidebarItem

  # Instantiates, but does not set data!
  #
  # @param [AWidgetSidebar] parent sidebar parent
  constructor: (parent) ->
    param.required parent
    super parent, [ "as-properties" ]

    # Automatically register self as the default properties widget if none yet
    # exists
    $("body").data "default-properties", @

  # Refresh widget data using a manipulatable
  #
  # @param [AManipulatable] obj
  refresh: (obj) ->
    param.required obj

    properties = obj.getProperties()

    # Generate html to inject
    _html = "<ul>"

    for p of properties
      _html += "<li>#{@_generateControl(p)}</li>"

    _html += "</ul>"

    # Inject
    $(@getSel()).html _html

  # Generates a mini HTML control widget for the property in question
  #
  # @param [Object] property
  # @return [String] html rendered widget
  _generateControl: (property) ->
    "a"
