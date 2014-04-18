define (require) ->

  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"
  Sidebar = require "widgets/sidebar/sidebar"

  # Generic sidebar item meant to be extended
  class SidebarItem extends Widget

    ###
    # Creates a new base sidebar item.
    #
    # @param [Sidebar] parent sidebar parent
    # @param [Array<String>] classes optional array of classes
    ###
    constructor: (parent, classes) ->
      param.required parent

      if not parent instanceof Sidebar
        throw new Error "Sidebar items need a AWidgetSidebar as a parent!"

      # Build the containing div
      super ID.prefID("sidebar-item"), parent, classes

    ###
    # Returns the Sidebar object for this sidebar item
    # @return [Sidebar] parent
    ###
    getSidebar: -> @_parent
