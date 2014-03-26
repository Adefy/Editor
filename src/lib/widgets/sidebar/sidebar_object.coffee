define ["util/param", "widgets/sidebar/sidebar_item"], (param, SidebarItem) ->

  # Sidebar object, meant to be contained inside of a SidebarObjectGroup
  class SidebarObject extends SidebarItem

    # The object consists of a name, but will be expanded to include an icon
    # and tooltip in the future (TODO) The parent must be an existing object
    # group.
    #
    # @param [String] name
    # @param [SidebarObjectGroup] parent parent object group instance
    # @param [String] icon optional path to an icon to display
    constructor: (name, parent, icon) ->
      @_name = param.required name
      @_parent = param.required parent
      @icon = param.optional icon, ""

      super @_parent.getParent(), [ "sidebar-obj" ]

      @_parent.render()

    # Render item HTML and return it. Note that this does NOT inject it anywhere!
    #
    # @return [String] html
    render: ->
      caret = "<i class=\"icon-caret-down\"></i>"

      img = ""
      if @icon.length > 0
        img = "<img height=\"16\" src=\"#{@icon}\" class=\"awso-i\">"

      "<div id=\"#{@_sel}\" class=\"aso-name\">#{img}#{@_name}#{caret}</div>"

    # Set item name
    #
    # @param [String] name
    setName: (name) ->
      @_name = param.required name
      @_parent.render()

    # Called when the item is dropped on a receiving droppable. Most often,
    # this is the "workspace".
    #
    # @param [String] target droppable identifier, usually "workspace"
    # @param [Number] x x coordinate of drop point
    # @param [Number] y y coordinate of drop point
    # @param [Handle] obj created manipulatable
    dropped: (target, x, y) ->
      param.required target
      param.required x
      param.required y

      # Default sidebar object, return null. This used to return a base object,
      # but it doesn't make sense since the BaseActor doesn't register itself
      # properly.
      null
