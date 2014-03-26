define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"

  # Generic sidebar, needs to be specialized to be useful
  #
  # @depend SidebarItem.coffee
  class Sidebar extends Widget

    # Set to true upon the first sidebar instantiation, signals that our
    # event listeners are bound
    # @private
    @__staticInitialized: false

    # Creates a new sidebar with a given origin. The element's id is randomized
    # to sbar + Math.floor(Math.random() * 1000)
    #
    # @param [String] parent parent element selector
    # @param [String] name sidebar name
    # @param [String] origin 'left' or 'right', default is left
    # @param [Number] width
    constructor: (parent, name, origin, width) ->

      # Sidebar items of class SidebarItem (or implementations)
      @_items = []

      @_name = param.optional name, "Sidebar"
      @_origin = param.optional origin, "left", [ "left", "right" ]
      @_width = param.optional width, 300

      param.required parent
      super ID.prefId("sidebar"), parent, [ "sidebar" ]

      @_hiddenX = 0
      @_visibleX = 0

      @setWidth @_width
      @show null, false     # Set us up as initially visible
      @onResize()           # Calculate X offsets
      @_bindToggle()        # Bind an event listener for sidebar toggles.

    # @private
    _bindToggle: ->
      if not Sidebar.__staticInitialized
        Sidebar.__staticInitialized = true

        $(document).ready ->
          $(document).on "click", ".as-toggle", ->

            # Find the affected sidebar
            sidebar = $("body").data "##{$(@).parent().parent().attr("id")}"

            sidebar.toggle()

    # Set sidebar name, re-renders it
    #
    # @param [String] name
    setName: (name) ->
      @_name = param.required name
      @render()

    # Get sidebar name
    #
    # @return [String] name
    getName: -> @_name

    # Add an item to the sidebar and re-render. An item is any object with a
    # render function that returns HTML. Note that the function should not
    # inject it as it will be injected into the sidebar on render!
    #
    # @param [Object] item item with render() and getId() methods
    addItem: (item) ->
      param.required item

      if item.render == undefined or item.render == null
        throw new Error "Item must have a render function!"

      if item.getId == undefined or item.getId == null
        throw new Error "Item must supply a getId() function!"

      # Test out the render function, ensure it returns a string
      test = item.render()
      if typeof test != "string"
        throw new Error "Item render function must return a string!"

      @_items.push item
      @render()

    # Remove item using id. Note that the id can be anything, since we don't
    # specify what it should be when adding the item. Also re-renders the sidebar
    #
    # @param [Object] id
    # @return [Boolean] success false if item is not found
    removeItem: (id) ->
      param.required id

      for i in [0...@_items.length]
        if @_items[i].getId() == i
          if typeof @_items[i].getId() == typeof i # Probably overkill
            @_items.splice i, 1
            @render()
            return true

      false

    # Render! Fill the sidebar with html from the items rendered in order.
    render: ->
      _html = ""
      for i in @_items
        _html += i.render()

      $(@_sel).html _html

    postRender: ->
      for i in @_items
        i.postRender() if i.postRender != undefined

    # Take the navbar into account, and always position ourselves below it
    onResize: ->

      menubar = $(".menubar")
      toolbar = $(".toolbar")
      timeline = $(".timeline")
      statusbar = $(".statusbar")

      timelineBottom = 0
      timelineHeight = 0

      if timeline && timeline.length > 0
        timelineHeight = timeline.height()
        timelineBottom = timeline.position().top + timelineHeight

      # Re-size
      #$(@_sel).height $(document).height() -
      #toolbar.height() - menubar.height() - statusbar.height() - timelineHeight
      #$(@_sel).offset top: toolbar.position().top + toolbar.height(), left: 0

      # Re-position
      #if @_origin == "right"
      #  @_hiddenX = $(document).width() - 32
      #  @_visibleX = $(document).width() - @_width

      for i in @_items
        i.onResize()

    # Set sidebar width, sets internal offset values
    #
    # @param [Number] width
    setWidth: (width) ->
      param.required width
      @_width = width

      #if @_origin == "left"
      #  @_hiddenX = - @_width + 32
      #  @_visibleX = 0
      #else
      #  @_hiddenX = $(document).width() - 32
      #  @_visibleX = $(document).width() - @_width

      $(@_sel).width @_width

    # Toggle visibility of the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to true
    toggle: (cb, animate) ->
      return
      animate = param.optional animate, true

      # Keep in mind this can cause issues with code that depends on the
      # visibility state. I'm not sure if we should update it immediately,
      # or after the animation is finished. For the time being, we'll do so
      # immediately.

      # Cheese.
      if animate then AUtilLog.warn "Animation not yet supported"

      if @_visiblity
        @hide cb, animate
      else
        @show cb, animate

    # Show the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to true
    show: (cb, animate) ->
      return
      animate = param.optional animate, true

      if @_visiblity == true
        if cb then cb()
        return

      # And
      if animate
        $(@_sel).animate
          left: @_visibleX
        , 300
      else $(@_sel).css { left: @_visibleX }

      @_visiblity = true

    # Hide the sidebar with an optional animation
    #
    # @param [Method] cb callback
    # @param [Boolean] animate defaults to true
    hide: (cb, animate) ->
      return
      animate = param.optional animate, true

      if @_visiblity == false
        if cb then cb()
        return

      # Ham
      if animate
        $(@_sel).animate
          left: @_hiddenX
        , 300
      else $(@_sel).css { left: @_hiddenX }

      @_visiblity = false
