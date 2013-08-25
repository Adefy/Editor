# Main navigation bar widget
#
# @depend AWidget.coffee
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

    # Used to give items unique ids, incremented internally when used
    @_nextID = 0

    if AWidgetMainbar.__exists == true
      AUtilLog.warn "A mainbar already exists, refusing to continue!"
      return

    AWidgetMainbar.__exists = true

    param.required parent
    super "amainbar", parent, [ "awidgetmainbar" ]

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
        _menu = $(".amainbar-secondary[data-owner=\"#{$(@).attr("id")}\"")

        if $(@).hasClass "open"
          _menu.hide()
          $(@).removeClass "open"
        else
          _menu.show()
          $(@).addClass "open"

    # Note that we don't render initially. This gives the engine the freedom
    # to set up initial items, and then render us appropriatly

  # Adds a menu item, id is set using an internal counter if not otherwise
  # specified. Note that this function does not call render()!
  #
  # @param [String] label text that appears as the item
  # @param [String] link href content, defaults to #
  # @param [String,Number] id optional, set using an internal counter
  # @return [AWidgetMainbarItem] item created item
  addItem: (label, link, id) ->

    param.required label
    link = param.optional link, "#"
    id = param.optional @_nextID++

    # Ensure id is unique
    for i in @_items
      if i._id == id
        AUtilLog.warn "id in use, overriding supplied id"
        id = @_nextID++

    child = new AWidgetMainbarItem id, null, @, "primary", label, link
    @_items.push child

    child

  # Removes an item using an id, returns false if the item is not found
  #
  # @param [String,Number] id
  # @return [Boolean] success false if item is not found
  removeItem: (id) ->

    for i in [0...@_items.length]
      if @_items[i].id == id
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
    $(@sel).html _html

    # Now render secondary items, and append them to our selector
    # Note that this places them OUTSIDE the previous list!
    for i in _secondary
      _menuId = @_nextID++

      _owner = "data-owner=\"#{i._id}\""
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
      $(@sel).append _html

      # Position
      $("##{_menuId}").css
        left: $("##{i._id}").offset().left

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
      $(@sel).append _html

    # At this point, we've rendered three sets of items, completely seperately.

# Mainbar item class
#
# The item can be in one of three states
#  - Primary    [On the mainbar itself]
#  - Secondary  [Item in a mainbar dropdown]
#  - Detail     [Item in a sub-menu to the dropdown]
class AWidgetMainbarItem

  # Creates item, does not render it!
  #
  # @param [String,Number] id unique id
  # @param [AWidgetMainbarItem] parent parent, null if the item is primary
  # @param [AWidgetMainbar] menubar menubar object
  # @param [String] role role is either 'primary', 'secondary', or 'detail'
  # @param [String] label text to appear as the item
  # @param [String] href url the item points to
  constructor: (@_id, @_parent, @_menubar, @_role, label, href) ->

    # Child items, added/removed using accessor functions
    @_children = []

    param.required @_id
    param.required @_parent
    param.required @_menubar
    param.required @_role, [ "primary", "secondary", "detail" ]

    # Not sure how to add instanceof checks to the param utility
    if @_menubar !instanceof AWidgetMainbar
      throw new Error "You need to use an existing menubar to create an item!"

    @label = param.optional label, ""
    @href = param.optional href, "#"

    # Disallow children on detail items
    if @_role == "detail" then @_children = undefined

  # Render function, returns HTML representing the item.
  # For nested items, the parent item decides where this HTML is inserted
  #
  # @return [String] html rendered item
  render: ->

    _html = ""

    switch @_role

      when "primary"
        _classes = ""
        if @_children.length > 0 then _classes = "amb-primary-has-children"

        _html += "<a class=\"#{_classes}\" id=\"#{@_id}\" href=\"#{@href}\">"
        _html += "<li>#{@label}</li>"
        _html += "</a>"

      when "secondary"
        _html += "<a href=\"#{@href}\"><li>#{@label}</li></a>"

      when "detail"
        _html += ""

      else
        throw new Error "Tried to render invalid menubar item [#{@_role}]"

    _html

  # Create a child item if possible. A unique id and correct tree-level is
  # insured
  #
  # @param [String] label text to appear as the item
  # @param [String] href url the item points to
  # @return [AWidgetMainbarItem] item null if the item could not be created
  createChild: (label, href) ->

    # BAIL BAIL BAIL
    if @_role == "detail" then return null

    # Setup role
    role = "secondary"
    if @_role == "secondary" then role = "detail"

    child = new AWidgetMainbarItem @_menubar._nextID++, @, @_menubar, role
    child.label = param.optional label, ""
    child.href = param.optional href, "#"

    # Register it
    @_children.push child

    child

  # Delete child using id, returns false if the child was not found
  #
  # @param [String,Number] id child id
  removeChild: (id) ->

    for i in [0...@_children.length]
      if @_children[i].id == id
        @_children.splice i, 1
        return true

    false
