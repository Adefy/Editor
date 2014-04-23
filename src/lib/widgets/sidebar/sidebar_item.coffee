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
    constructor: (@ui, options) ->
      param.required options.parent

      if not options.parent instanceof Sidebar
        throw new Error "SidebarItem needs a Sidebar as a parent!"

      options.id = ID.prefID("sidebar-item")

      super @ui, options

    ###
    # Returns the Sidebar object for this sidebar item
    # @return [Sidebar] parent
    ###
    getSidebar: -> @_parent
