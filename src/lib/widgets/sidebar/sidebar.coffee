define (require) ->

  config = require "config"
  param = require "util/param"

  AUtilLog = require "util/log"
  ID = require "util/id"
  Widget = require "widgets/widget"
  Storage = require "storage"

  # Generic sidebar, needs to be specialized to be useful
  #
  # @depend SidebarItem.coffee
  class Sidebar extends Widget

    ###
    # Set to true upon the first sidebar instantiation, signals that our
    # event listeners are bound
    # @type [Boolean]
    # @private
    ###
    @__staticInitialized: false

    ###
    # Creates a new sidebar with a given origin. The element's id is randomized
    # to sbar + Math.floor(Math.random() * 1000)
    #
    # @param [UIManager] ui
    # @param [Number] width
    ###
    constructor: (@ui, width) ->

      # Sidebar items of class SidebarItem (or implementations)
      @_items = []

      @_width = param.optional width, 300

      super
        id: ID.prefID("sidebar")
        parent: "section.main"
        classes: ["sidebar"]

      @_hiddenX = 0
      @_visibleX = 0
      @_visible = Storage.get("sidebar.visible") == true

      @setWidth @_width
      @onResize()           # Calculate X offsets
      @_bindToggle()        # Bind an event listener for sidebar toggles.

      if @_visible
        @show()
      else
        @hide()

    ###
    # @private
    ###
    _bindToggle: ->
      if not Sidebar.__staticInitialized
        Sidebar.__staticInitialized = true

        $(document).on "click", ".sidebar .button.toggle", ->

          # Find the affected sidebar
          selector = @attributes["data-sidebarid"].value
          sidebar = $("body").data "##{selector}"

          sidebar.toggle()

    ###
    # Add an item to the sidebar and re-render. An item is any object with a
    # render function that returns HTML. Note that the function should not
    # inject it as it will be injected into the sidebar on render!
    #
    # @param [Object] item item with render() and getID() methods
    ###
    addItem: (item) ->
      param.required item

      if item.render == undefined or item.render == null
        throw new Error "Item must have a render function!"

      if item.getID == undefined or item.getID == null
        throw new Error "Item must supply a getID() function!"

      # Test out the render function, ensure it returns a string
      test = item.render()
      if typeof test != "string"
        throw new Error "Item render function must return a string!"

      @_items.push item
      @render()

    ###
    # Remove item using id. Note that the id can be anything, since we don't
    # specify what it should be when adding the item. Also re-renders the sidebar
    #
    # @param [Object] id
    # @return [Boolean] success false if item is not found
    ###
    removeItem: (id) ->
      param.required id

      for i in [0...@_items.length]
        if @_items[i].getID() == i
          if typeof @_items[i].getID() == typeof i # Probably overkill
            @_items.splice i, 1
            @render()
            return true

      false

    ###
    # Render! Fill the sidebar with html from the items rendered in order.
    ###
    render: ->
      @getElement().html @_items.map((i) -> i.render()).join ""
      @refreshVisible()
      @postRender()

    ###
    # postRender! Calls all the child postRender
    ###
    postRender: ->
      for item in @_items
        item.postRender() if item.postRender

    ###
    # Render the HTML content and replace it
    ###
    refresh: ->
      @render()

    ###
    # Take the navbar into account, and always position ourselves below it
    ###
    onResize: ->
      height = window.innerHeight - $("footer").height() - $("header").height()
      @getElement().height height

      i.onResize() for i in @_items

    ###
    # Set sidebar width, sets internal offset values
    #
    # @param [Number] width
    ###
    setWidth: (width) ->
      @getElement().width width
      @_width = @getElement().width()
      @_hiddenX = -(@_width - 40)
      @_visibleX = 0

    ###
    # Refreshes the state of the timeline toggle icons and storage
    ###
    refreshVisible: ->
      Storage.set "sidebar.visible", @_visible
      @getElement(".button.toggle i").toggleClass config.icon.toggle_left, @_visible
      @getElement(".button.toggle i").toggleClass config.icon.toggle_right, !@_visible

    ###
    # Toggle visibility of the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to false
    ###
    toggle: (cb, animate) ->
      animate = param.optional animate, true

      if @_visible
        @hide cb, animate
      else
        @show cb, animate

    ###
    # Show the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to true
    ###
    show: (cb, animate) ->
      animate = param.optional animate, true

      if @_visible
        cb() if cb
        return

      AUtilLog.info "Showing Sidebar"

      if animate
        @getElement().animate left: @_visibleX, 300
      else
        @getElement().css left: @_visibleX

      @_visible = true
      @refreshVisible()

    ###
    # Hide the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to true
    ###
    hide: (cb, animate) ->
      animate = param.optional animate, true

      unless @_visible
        cb() if cb
        return

      AUtilLog.info "Hiding Sidebar"

      if animate
        @getElement().animate left: @_hiddenX , 300
      else
        @getElement().css left: @_hiddenX

      @_visible = false
      @refreshVisible()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      if (type == "timeline.show") || (type == "timeline.hide")
        @onResize()

      for item in @_items
        item.respondToEvent(type, params) if item.respondToEvent
