define [
  "util/id"
  "util/param"
  "widgets/widget"
  "widgets/sidebar/sidebar"
], (ID, param, Widget, Sidebar) ->

  # Generic sidebar item meant to be extended
  class SidebarItem extends Widget

    # Creates a new base sidebar item.
    #
    # @param [Sidebar] parent sidebar parent
    # @param [Array<String>] classes optional array of classes
    constructor: (parent, classes) ->
      param.required parent

      if not parent instanceof Sidebar
        throw new Error "Sidebar items need a AWidgetSidebar as a parent!"

      # Build the containing div
      super ID.prefId("sidebar-item"), parent, classes
