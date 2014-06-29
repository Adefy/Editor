define (require) ->

  config = require "config"
  param = require "util/param"
  AUtilLog = require "util/log"
  ID = require "util/id"

  Widget = require "widgets/widget"
  TemplateContextMenu = require "templates/context_menu"

  # Context menu widget, created when a handle is right-clicked and
  # supports actions
  class ContextMenu extends Widget

    ###
    # Builds a context menu as a new div on the body. It is absolute
    # positioned, and as such requires a position at instantiation.
    #
    # Note that once the menu is clicked out of, it should be discarded!
    #
    # @param [Number] x x coordinate to spawn at
    # @param [Number] y y coordinate to spawn at
    # @param [Handle] properties context menu property definitions
    ###
    constructor: (@ui, options) ->
      x = param.required options.x
      y = param.required options.y
      @properties = param.required options.properties

      @_name = @properties.name
      @_items = @properties.functions

      # Silently drop out, empty ctx menu is allowed, we just do nothing
      return if $.isEmptyObject @_items

      # Give items unique IDs
      item.id = ID.prefID("ctx-item") for key, item of @_items

      super @ui,
        id: ID.prefID("context-menu")
        classes: [ "context-menu" ]
        listeners: [
          event: "click"
          sel: "a:not(.label)"
          prefixSelf: true
          cb: @onClick
        ,
          event: "mouseup"
          sel: "body"
          cb: @onMouseUp
        ]
        static: true
        html: TemplateContextMenu
          name: @_name
          items: @_items

      # We render ourselves immediately; refreshStub creates our outer container
      @refreshStub()
      @refresh()

      # Vertical offset depends on if we have a label
      if @properties.name
        verticalOffset = 25
      else
        verticalOffset = 12

      @getElement().css
        left: x - 30
        top: y - verticalOffset

    ###
    # Called when we a link of ours is clicked on. Removes and invalidates us!
    #
    # @param [Event] e
    ###
    onClick: (e) =>
      return unless id = $(e.target).parent().attr "data-id"

      for key, item of @_items
        if item.id == id
          item.cb()
          break

      @remove()

    ###
    # Called when the mouse us unclicked anywhere on the body. Removes and
    # invalidates us if the mouse is not directly over us.
    #
    # @param [Event] e
    ###
    onMouseUp: (e) =>
      self = @getElement()
      @remove() if !self.is(e.target) && self.has(e.target).length == 0
