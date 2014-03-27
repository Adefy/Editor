define (require) ->

  param = require "util/param"
  SidebarObject = require "widgets/sidebar/sidebar_object"
  SidebarItem = require "widgets/sidebar/sidebar_item"

  # Contains a group of sidebar objects, which can be dragged
  # onto the workspace
  class SidebarObjectGroup extends SidebarItem

    ###
    # Sets things up, NOTE we add ourselves to the parent's item collection, do
    # NOT do so manually!
    #
    # @param [String] name group name
    # @param [Sidebar] parent sidebar parent
    ###
    constructor: (name, parent) ->

      # SidebarItem ensures the parent is valid, so rely on super to check
      super parent, [ "sidebar-objgroup" ]

      # The items we contain, all of type SidebarObject
      @_items = []

      # At this point, we've been injected into the DOM.
      # Set the group name and re-render our parent sidebar
      @setName name

      @_parent.addItem @
      @_parent.render()

    ###
    # Renders the category, returning the resulting html
    #
    # @return [String] html html representation of the category
    ###
    render: ->

      _html =  "<div class=\"as-objgroup\">"
      _html += "<span class=\"asog-catname\">#{@_name}</span>"
      _html += "<ul>"

      for i in @_items
        _html += "<li class=\"aworkspace-drag\">#{i.render()}</li>"

      _html += "</ul></div>"

    ###
    # Sets a new category name, and re-renders the group
    #
    # @param [String] name
    ###
    setName: (name) ->
      @_name = param.required name
      @_parent.render()

    ###
    # Fetch category name
    #
    # @return [String] name
    ###
    getName: -> @_name

    ###
    # Add an existing item to the group
    #
    # @param [SidebarObject] item
    ###
    addItem: (item) ->
      param.required item

      if not item instanceof SidebarObject
        throw new Error "Items have to be instances of SidebarObject!"

      @_items.push item   # Ship itttt
      @_parent.render()   # Re-render

    ###
    # Create a new object, automatically adding it to the group
    #
    # @param [String] name text to appear as object
    # @return [SidebarObject] item
    ###
    createItem: (name) ->
      param.required name
      i = new SidebarObject name, @
      @_items.push i
      @_parent.render()
      i

    ###
    # Remove item by id
    #
    # @param [String,Number] id id of the item to remove
    # @return [Boolean] success false if item is not found
    ###
    removeItem: (id) ->
      param.required id

      for i in [0...@_items.length]
        if @_items[i].getId == id
          @_items.splice i, 1
          @_parent.render()   # Update!
          return true

      false

    ###
    # Get the parent sidebar
    #
    # @return [Sidebar] parent
    ###
    getParent: -> @_parent
