define (require) ->

  ID = require "util/id"
  param = require "util/param"

  Renderable = require "mixin/renderable"

  # Menubar item class
  #
  # The item can be in one of three states
  #  - Primary    [On the mainbar itself]
  #  - Secondary  [Item in a mainbar dropdown]
  #  - Detail     [Item in a sub-menu to the dropdown]
  class MenubarItem extends Renderable

    ###
    # Creates item, does not render it!
    #
    # @param [String,Number] id unique id
    # @param [MenubarItem] parent parent, null if the item is primary
    # @param [MenuBar] menubar menubar object
    # @param [String] role role is either 'primary', or 'secondary'
    # @param [String] label text to appear as the item
    # @param [String] href url the item points to
    # @param [Boolean] sectionEnd if true, marks the end of a section
    ###
    constructor: (@_id, @_parent, @_menubar, @_role, label, href, sectionEnd) ->
      param.required @_id
      param.required @_parent
      param.required @_menubar
      param.required @_role, [ "primary", "secondary" ]

      @label = param.optional label, ""
      @href = param.optional href, "#"
      @sectionEnd = param.optional sectionEnd, false

      @_children = []

    ###
    # Render function, returns HTML representing the item.
    # For nested items, the parent item decides where this HTML is inserted
    #
    # @return [String] html rendered item
    ###
    render: ->
      opts = id: @_id, href: @href

      if @_role == "primary" and @_children.length > 0
        opts.class = "mb-primary-has-children"

      # The last secondary item in a section gets a special divider class
      else if @_role == "secondary" and @sectionEnd
        opts.class = "mb-section-end"

      ###
      # @todo This is REALLY hacky. We MUST refactor this beast, and make it
      # easier to add onclick listeners
      ###
      setTimeout =>
        $("##{@_id}")[0].onclick = @click if @click
      , 0

      @genElement "a", opts, =>
        @genElement "li", {}, => @label

    ###
    # Create a child item if possible. A unique id and correct tree-level is
    # ensured
    #
    # @param [Object] options
    #   @option [String] label text to appear as the item
    #   @option [String] href url the item points to
    #   @option [Method] click click handler, optional
    #   @option [Boolean] sectionEnd if true, child marks the end of a section
    # @return [MenubarItem] item null if the item could not be created
    ###
    createChild: (options) ->
      param.required options
      sectionEnd = param.optional options.sectionEnd, false
      label = param.optional options.label, ""
      click = param.optional options.click, null
      href = param.optional options.href, "javascript:void(0)", [], false

      role = "secondary"

      child = new MenubarItem ID.prefID("menubar-item"), @, @_menubar, role
      child.label = label
      child.href = href
      child.sectionEnd = sectionEnd
      child.click = click

      # Register it
      @_children.push child

      child

    ###
    # Delete child using id
    #
    # @param [String] id child id
    ###
    removeChild: (id) ->
      @_children = _.filter @_children, (i) -> i.getID() != id
      @

    ###
    # Fetch item id
    #
    # @return [Number] id
    ###
    getID: -> @_id
