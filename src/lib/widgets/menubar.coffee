define (require) ->

  config = require "config"
  param = require "util/param"
  ID = require "util/id"

  AUtilLog = require "util/log"
  Widget = require "widgets/widget"

  TemplateMenuBar = require "templates/menubar"

  # Main navigation bar widget
  class MenuBar extends Widget

    ###
    # Creates a new menu bar if one does not already exist
    #
    # @param [UIManager] ui
    # @param [Array<Object>] definitions array of menu item definitions
    ###
    constructor: (@ui, definitions) ->
      @_items = @_assignDefinitionIDs definitions

      super @ui,
        id: ID.prefID("menubar")
        parent: config.selector.header
        classes: ["menubar"]
        prepend: true

      # Note that we don't render initially. This gives the engine the freedom
      # to set up initial items, and then render us appropriately
      @_registerListeners()

    ###
    # Go through and attach an ID on each item child so we can identify click
    # targets
    #
    # @param [Array<Object>] definitions
    ###
    _assignDefinitionIDs: (definitions) ->
      for item in definitions
        item.id = ID.prefID "mb-primary"

        if item.children
          for child in item.children
            child.id = ID.prefID "mb-secondary"

      definitions

    ###
    # Register event listeners for menu objects
    ###
    _registerListeners: ->
      @_regMouseUpMenuClose()
      @_regMenuClick()
      @_regMenuItemClick()
      @_regMenuMouseover()

    ###
    # Listener responsible for closing secondary menus when user clicks outside
    ###
    _regMouseUpMenuClose: ->
      $(document).mouseup (e) =>
        menus = $("#{@getSel()} .mb-secondary")

        if menus && !menus.is(e.target) && menus.has(e.target).length == 0
          menus.hide()
          $("#{@getSel()} .mb-primary .open").removeClass "open"

    ###
    # Click listener to open/close menu items
    ###
    _regMenuClick: ->
      $(document).on "click", "#{@getSel()} .mb-primary a", (e) =>

        if $(e.target).attr "data-id"
          link = e.target
        else
          link = $(e.target).closest "a"

        id = $(link).attr "data-id"
        item = _.where(@_items, id: id)[0]

        return unless item

        if item.children && item.children.length > 0
          menu = $(".mb-secondary[data-owner=\"#{id}\"]")

          if $(link).hasClass "open" then menu.hide()
          else menu.show()

          $(link).toggleClass "open"

        item.click(e) if item.click

        e.preventDefault()
        false

    ###
    # Close menu on item click
    ###
    _regMenuItemClick: ->
      $(document).on "click", "#{@getSel()} .mb-secondary a", (e) =>
        $(e.target).closest(".mb-secondary").hide()
        $("#{@getSel()} .mb-primary a").removeClass "open"

        parentId = $(e.target).closest(".mb-secondary").attr "data-owner"
        id = $(e.target).attr "data-id"

        parent = _.where(@_items, id: parentId)[0]
        child = _.where(parent.children, id: id)[0]

        child.click(e) if child

        e.preventDefault()
        false

    ###
    # Hover listener, opens menus with children when hovered (if another is
    # already open)
    ###
    _regMenuMouseover: ->
      $(document).on "mouseover", "#{@getSel()} .mb-primary a", ->

        openPrimaries = $(".mb-primary a.open")
        if openPrimaries.length > 0

          # Hide existing menus, remove class
          $(".mb-secondary").hide()
          openPrimaries.removeClass "open"

          # Show our submenu, attach clas
          $(".mb-secondary[data-owner=\"#{$(@).attr("data-id")}\"]").show()
          $(@).addClass "open"

    render: ->
      super() + TemplateMenuBar items: @_items

    postRefresh: ->
      _.filter(@_items, (i) -> i.children && i.children.length > 0).map (i) =>
        $("#{@getSel()} .mb-secondary[data-owner=#{i.id}]").css
          left: $("#{@getSel()} .mb-primary a[data-id=#{i.id}]").offset().left

      super()
