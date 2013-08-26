# Sidebar object, meant to be contained inside of a SidebarObjectGroup
#
# @depend AWidgetSidebarItem.coffee
class AWidgetSidebarObject extends AWidgetSidebarItem

  # The object consists of a name, but will be expanded to include an icon
  # and tooltip in the future (TODO) The parent must be an existing object
  # group.
  #
  # @param [String] name
  # @param [AWidgetSidebarObjectGroup] parent parent object group instance
  constructor: (name, parent) ->
    @_name = param.required name
    @_parent = param.required parent

    super @_parent.getParent(), [ "as-obj" ]

    @_parent.render()

  # Render item HTML and return it. Note that this does NOT inject it anywhere!
  #
  # @return [String] html
  render: -> "<div class=\"aso-name\">#{@_name}</div>"

  # Set item name
  #
  # @param [String] name
  setName: (name) ->
    @_name = param.required name
    @_parent.render()
