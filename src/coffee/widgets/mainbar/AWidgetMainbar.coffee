# Main navigation bar widget
#
# @depend AWidgetMainbarItem.coffee
class AWidgetMainbar extends AWidget

  # Set to true upon instantiation, prevents more than one instance
  @__exists: false

  # Creates a new menu bar if one does not already exist
  #
  # @param [String] parent parent element selector
  constructor: (parent) ->

    # Items on the menu, accessors are used to manipulate the array
    # After updating, call @render() to re-draw the menu
    @_items = []

    if AWidgetMainbar.__exists == true
      AUtilLog.warn "A mainbar already exists, refusing to continue!"
      return

    AWidgetMainbar.__exists = true

    param.required parent
    super prefId("amainbar"), parent, [ "amainbar" ]

    # Register listeners
    $(document).ready ->

      # Mouseup listener to close menu when clicked outside
      $(document).mouseup (e) ->

        seco = $(".amainbar-secondary")
        deta = $(".amainbar-detail")

        if seco
          seco_open = $(".amainbar-primary .open")
          if !seco.is(e.target) && seco.has(e.target).length == 0
            seco.hide()
            seco_open.removeClass "open"
        if deta
          deta_open = $(".amainbar-secondary .open")
          if !deta.is(e.target) && deta.has(e.target).length == 0
            deta.hide()
            deta_open.removeClass "open"

      # Click listener to open/close menu items
      $(document).on "click", ".amb-primary-has-children", ->
        _menu = $(".amainbar-secondary[data-owner=\"#{$(@).attr("id")}\"]")

        if $(@).hasClass "open"
          _menu.hide()
          $(@).removeClass "open"
        else
          _menu.show()
          $(@).addClass "open"

    # Note that we don't render initially. This gives the engine the freedom
    # to set up initial items, and then render us appropriatly

  # Adds a menu item. Note that this function does not call render()!
  #
  # @param [String] label text that appears as the item
  # @param [String] link href content, defaults to #
  # @return [AWidgetMainbarItem] item created item
  addItem: (label, link) ->

    param.required label
    link = param.optional link, "#"

    _id = prefId "amb-item"
    child = new AWidgetMainbarItem _id, null, @, "primary", label, link
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

  # Renders the menu
  render: ->

    _secondary = [] # Keeps track of which items have children
    _detail = [] # Like above, except this time one level lower

    # Render primary children first
    _html = "<div id=\"ambdecorater\"></div>"     # That nice green line
    _html += "<span class=\"logo\">Adefy</span>"  # Adefy logo
    _html += "<ul class=\"amainbar-primary\">"    # Our actual primary list

    for i in @_items
      if i._role != "primary"
        throw new Error "Invalid child at this level! #{i._role} (primary)"

      _html += i.render()
      if i._children.length > 0 then _secondary.push i

    _html += "</ul>"
    $(@_sel).html _html

    # Now render secondary items, and append them to our selector
    # Note that this places them OUTSIDE the previous list!
    for i in _secondary
      _menuId = nextId()

      _owner = "data-owner=\"#{i.getId()}\""
      _id = "id=\"#{_menuId}\""
      _classes = "class=\"amainbar-secondary\""

      _html = "<ul #{_owner} #{_id} #{_classes}>"

      for c in i._children
        if c._role != "secondary"
          throw new Error "Invalid child at this level! #{c._role} (secondary)"

        _html += c.render()
        if c._children.length > 0 then _detail.push c

      # Append
      _html += "</ul>"
      $(@_sel).append _html

      # Note that chrome requires 4px of extra padding, so we need to calc the
      # real offset depending on the browser
      _realOff = $("##{i.getId()}").offset().left
      if navigator.userAgent.search("Chrome") != -1 then _realOff += 4

      # Position
      $("##{_menuId}").css
        left: _realOff

    # Finally, render detail items
    for i in _detail
      _html = "<ul class=\"amainbar-detail\">"

      for c in i._children
        if c._role != "detail"
          throw new Error "Invalid child at this level! #{c._role} (detail)"

        _html += c.render()
        if c._children.length > 0
          throw new Error "Detail item has children! Damn."

      _html += "</ul>"

      # Append
      $(@_sel).append _html

    # At this point, we've rendered three sets of items, completely seperately.
