##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Main navigation bar widget
#
# @depend MenubarItem.coffee
class AWidgetMenubar extends AWidget

  # Set to true upon instantiation, prevents more than one instance
  @__exists: false

  # Creates a new menu bar if one does not already exist
  #
  # @param [String] parent parent element selector
  constructor: (parent) ->
    param.required parent

    # Items on the menu, accessors are used to manipulate the array
    # After updating, call @render() to re-draw the menu
    @_items = []

    if AWidgetMenubar.__exists == true
      AUtilLog.warn "A menubar already exists, refusing to continue!"
      return

    AWidgetMenubar.__exists = true

    super prefId("menubar"), parent, [ "menubar" ]

    @_regListeners()

  # @private
  _regListeners: ->
    # Register listeners
    $(document).ready ->

      # Mouseup listener to close menu when clicked outside
      $(document).mouseup (e) ->

        seco = $(".menu")
        deta = $(".menubar-detail")

        if seco
          seco_open = $(".bar .open")
          if !seco.is(e.target) && seco.has(e.target).length == 0
            seco.hide()
            seco_open.removeClass "open"
        if deta
          deta_open = $(".menu .open")
          if !deta.is(e.target) && deta.has(e.target).length == 0
            deta.hide()
            deta_open.removeClass "open"

      # Click listener to open/close menu items
      $(document).on "click", ".mb-primary-has-children", (e) ->
        _menu = $(".menu[data-owner=\"#{$(@).attr("id")}\"]")

        if $(@).hasClass "open"
          _menu.hide()
          $(@).removeClass "open"
        else
          _menu.show()
          $(@).addClass "open"

        e.preventDefault()
        false

      # Close menu on item click
      $(document).on "click", ".menu a", (e) ->
        $(@).parent().hide()
        $(".mb-primary-has-children").removeClass "open"

        e.preventDefault()
        false

      # Hover listener, opens menus with children when hovered (if another is
      # already open)
      $(document).on "mouseover", ".mb-primary-has-children", ->

        # Check if any primaries are open
        if $(".mb-primary-has-children.open").length > 0

          # Hide existing menus, remove class
          $(".menu").hide()
          $(".mb-primary-has-children.open").removeClass "open"

          # Show our submenu, attach clas
          $(".menu[data-owner=\"#{$(@).attr("id")}\"]").show()
          $(@).addClass "open"

    # Note that we don't render initially. This gives the engine the freedom
    # to set up initial items, and then render us appropriatly

  # Adds a menu item. Note that this function does not call render()!
  #
  # @param [String] label text that appears as the item
  # @param [String] link href content, defaults to #
  # @return [AWidgetMenubarItem] item created item
  addItem: (label, link) ->

    param.required label
    link = param.optional link, "#"

    _id = prefId "menubar-item"
    child = new AWidgetMenubarItem _id, "#", @, "primary", label, link
    @_items.push child

    child

  # Removes an item using an id, returns false if the item is not found
  #
  # @param [String,Number] id
  # @return [Boolean] success false if item is not found
  removeItem: (id) ->

    for i in [0...@_items.length]
      if @_items[i].getId == id
        @_items.splice i, 1
        return true

    false

  ###
  #
  # Renders the menu
  #
  ###
  render: ->

    _secondary = [] # Keeps track of which items have children
    _detail = [] # Like above, except this time one level lower

    # Render primary children first
    _html = @genElement "div", id: "menubar-decorater"
    _html += @genElement "ul", class: "bar", =>
      __html = ""
      for i in @_items
        if i._role != "primary"
          throw new Error "Invalid child at this level! #{i._role} (primary)"

        __html += i.render()
        _secondary.push i if i._children.length > 0
      __html

    $(@_sel).html _html

    # Now render secondary items, and append them to our selector
    # Note that this places them OUTSIDE the previous list!
    for i in _secondary
      _menuId = nextId()

      _attrs = {}
      _attrs["id"] = _menuId
      _attrs["data-owner"] = i.getId()
      _attrs["class"] = "menu"

      # Append
      $(@_sel).append @genElement "ul", _attrs, =>
        __html = ""
        for c in i._children
          if c._role != "secondary"
            throw new Error "Invalid child at this level! #{c._role} (secondary)"

          __html += c.render()
          _detail.push c if c._children.length > 0
        __html

      # Note that chrome requires 4px of extra padding, so we need to calc the
      # real offset depending on the browser
      _realOff = $("##{i.getId()}").offset().left

      # Position
      $("##{_menuId}").css
        left: _realOff

    # Finally, render detail items
    for i in _detail
      $(@_sel).append @genElement "ul", class: "menubar-detail", =>
        __html = ""
        for c in i._children
          if c._role != "detail"
            throw new Error "Invalid child at this level! #{c._role} (detail)"

          __html += c.render()
          if c._children.length > 0
            throw new Error "Detail item has children! Damn."
        __html

    # At this point, we've rendered three sets of items, completely seperately.
