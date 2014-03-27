define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"
  MenuBarItem = require "widgets/menubar/menubar_item"

  # Main navigation bar widget
  class MenuBar extends Widget

    _items: []

    ###
    # Creates a new menu bar if one does not already exist
    #
    # @param [UIManager] ui
    ###
    constructor: (@ui) ->
      return unless @enforceSingleton()

      super
        id: ID.prefId("menubar")
        classes: ["menubar"]
        prepend: true
        parent: "header"

      # Note that we don't render initially. This gives the engine the freedom
      # to set up initial items, and then render us appropriately
      @_registerListeners()

    ###
    # Checks if a menu bar has already been created, and returns false if one
    # has. Otherwise, sets a flag preventing future calls from returning true
    ###
    enforceSingleton: ->
      if MenuBar.__exists
        AUtilLog.warn "A menubar already exists, refusing to initialize!"
        return false

      MenuBar.__exists = true

    ###
    # Register event listeners for menu objects
    ###
    _registerListeners: ->
      @_reg_globalMouseUp()
      @_reg_menuClick()
      @_reg_itemClick()
      @_reg_mouseOver()

    ###
    # Listener responsible for closing menu when user clicks outside
    ###
    _reg_globalMouseUp: ->
      $(document).mouseup (e) ->
        menus = $(".menu")

        if menus
          if !menus.is(e.target) && menus.has(e.target).length == 0
            menus.hide()
            $(".bar .open").removeClass "open"

    ###
    # Click listener to open/close menu items
    ###
    _reg_menuClick: ->
      $(document).on "click", ".mb-primary-has-children", (e) ->
        _menu = $(".menu[data-owner=\"#{$(@).attr("id")}\"]")

        if $(@).hasClass "open"
          _menu.hide()
        else
          _menu.show()

        $(@).toggleClass "open"

        e.preventDefault()
        false

    ###
    # Close menu on item click
    ###
    _reg_itemClick: ->
      $(document).on "click", ".menu a", (e) ->
        $(@).parent().hide()
        $(".mb-primary-has-children").removeClass "open"

        e.preventDefault()
        false

    ###
    # Hover listener, opens menus with children when hovered (if another is
    # already open)
    ###
    _reg_mouseOver: ->
      $(document).on "mouseover", ".mb-primary-has-children", ->

        # Check if any primaries are open
        if $(".mb-primary-has-children.open").length > 0

          # Hide existing menus, remove class
          $(".menu").hide()
          $(".mb-primary-has-children.open").removeClass "open"

          # Show our submenu, attach clas
          $(".menu[data-owner=\"#{$(@).attr("id")}\"]").show()
          $(@).addClass "open"

    # Adds a menu item. Note that this function does not call render()!
    #
    # @param [String] label text that appears as the item
    # @param [String] link href content, defaults to #
    # @return [MenuBarItem] item created item
    addItem: (label, link) ->
      param.required label
      link = param.optional link, "#"

      _id = ID.prefId "menubar-item"
      child = new MenuBarItem _id, "#", @, "primary", label, link
      @_items.push child

      child

    # Removes an item using an id
    #
    # @param [String] id
    removeItem: (id) ->
      @_items = _.filter @_items, (i) -> i.getId() != id
      @

    ###
    #
    # Renders the menu
    #
    ###
    render: ->
      $(@_sel).html ""

      # Render our decorator
      _html = @genElement "div", id: "menubar-decorater"

      # Menu items
      _html += @genElement "ul", class: "bar", =>
        primaries = _.filter @_items, (i) -> i._role == "primary"
        primaries.map((i) -> i.render()).join ""

      $(@_sel).html _html

      # Now render secondary items, and append them to our selector
      # Note that this places them OUTSIDE the previous list!
      for item in _.filter(@_items, (i) -> i._children.length > 0)
        secondaries = _.filter item._children, (c) -> c._role == "secondary"

        attrs =
          id: ID.nextId()
          class: "menu"
          "data-owner": item.getId()

        # Append all secondary children
        $(@_sel).append @genElement "ul", attrs, =>
          secondaries.map((c) -> c.render()).join ""

        # Position us on the same left edge as our parents
        $("##{attrs.id}").css
          left: $("##{item.getId()}").offset().left
