# Generic sidebar item meant to be extended
class AWidgetSidebarItem extends AWidget

  # Creates a new base sidebar item.
  #
  # @param [AWidgetSidebar] parent sidebar parent
  # @param [Array<String>] classes optional array of classes
  constructor: (parent, classes) ->

    param.required parent

    if not parent instanceof AWidgetSidebar
      throw new Error "Sidebar items need a AWidgetSidebar as a parent!"

    # Build the containing div
    super prefId("asitem"), parent, classes
