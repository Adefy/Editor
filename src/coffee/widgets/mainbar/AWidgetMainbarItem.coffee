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
        _html += "<a id=\"#{@_id}\" href=\"#{@href}\"><li>#{@label}</li></a>"

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

    child = new AWidgetMainbarItem nextId(), @, @_menubar, role
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

  # Fetch item id
  #
  # @return [Number] id
  getId: -> @_id
