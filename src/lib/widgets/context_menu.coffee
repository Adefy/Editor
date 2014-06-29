define (require) ->

  config = require "config"
  param = require "util/param"

  AUtilLog = require "util/log"

  ID = require "util/id"

  Widget = require "widgets/widget"
  TemplateContextMenu = require "templates/context_menu"

  # Context menu widget, created when a handle is right-clicked and
  # supports actions
  class ContextMenu extends Widget

    ###
    # Set to true after initial instantiation, prevents redundant listeners
    ###
    @_registeredMouseup: false

    ###
    # @property [Boolean] animate enables/disables animation
    ###
    @animate: false

    ###
    # @property [Number] animateSpeed animation duration
    ###
    @animateSpeed: 80

    ###
    # Builds a context menu as a new div on the body. It is absolute
    # positioned, and as such requires a position at instantiation.
    #
    # Note that once the menu is clicked out of, it should be discarded!
    #
    # @param [Number] x x coordinate to spawn at
    # @param [Number] y y coordinate to spawn at
    # @param [Handle] properties context menu property definitions
    ###
    constructor: (@ui, options) ->
      x = param.required options.x
      y = param.required options.y
      @properties = param.required options.properties

      @name = @properties.name
      @functions = @properties.functions

      @alive = true # Set to false upon removal

      # Silently drop out, empty ctx menu is allowed, we just do nothing
      if $.isEmptyObject(@functions) then return

      # Create object
      super @ui,
        id: ID.prefID("context-menu")
        classes: [ "context-menu" ]

      # Add a handle to our instance on the body
      $("body").data @getID(), @

      # Position and inject ourselves
      @refreshStub() # widget auto refresh was removed
      @refresh()

      # Vertical offset depends on if we have a label
      if @properties.name
        verticalOffset = 25
      else
        verticalOffset = 12

      @getElement().css
        left: x - 30
        top: y - verticalOffset

      if ContextMenu.animate
        @getElement().slideDown ContextMenu.animateSpeed
      else
        @getElement().show()

    ###
    # Builds the html for the rendered menu, called in the constructor. Useful
    # to break it out here for testing and whatnot.
    #
    # @return [String] html ready for injection
    # @private
    ###
    _buildHTML: ->

      bindListener = (f) =>
        # Insane in da membrane
        if @functions[f].cb
          if typeof @functions[f].cb != "function"
            AUtilLog.error "Only methods can be bound to context menu items"
            return
        else
          AUtilLog.error "No callback function was given for #{f}"
          return


        $(document).on "click", "[data-id=\"#{@functions[f]._ident}\"]", =>
          @remove()
          @functions[f].cb()


      entries = []

      for f of @functions
        # If f already has an identifier set, unbind any existing listeners
        if @functions[f]._ident != undefined
          @_unbindListener @functions[f]._ident
        # We set a unique identifier for the element to use, and bind listeners
        @functions[f]._ident = @_convertToIdent(f) + ID.nextID()

        entries.push
          name: @functions[f].name || f
          dataId: @functions[f]._ident

      html = TemplateContextMenu name: @name, entries: entries

      # Bind listeners
      for f of @functions
        bindListener f

      if !ContextMenu._registeredMouseup

        # Mouseup listener to close menu when clicked outside
        $(document).mouseup (e) ->

          # Grab both the menu object, and our own instance from the body
          menu = $(".context-menu")
          ins = $("body").data $(menu).attr "id"

          if menu != undefined and ins != undefined
            if !menu.is(e.target) && menu.has(e.target).length == 0
              if ContextMenu.animate
                $(ins._sel).slideUp ContextMenu.animateSpeed, ->
                  $(ins._sel).remove()
              else
                $(ins._sel).remove()

        ContextMenu._registeredMouseup = true

      html

    render: ->
      super() + @_buildHTML()

    ###
    # Shorthand, used in @_buildHTML and @remove
    #
    # @param [String] ident
    # @private
    ###
    _unbindListener: (ident) ->
      $(document).off "click", "[data-id=\"#{ident}\"]"

    ###
    # Useful internal function, turns "Test 3" into test_3
    #
    # @param [String] name name to convert
    # @return [String] converted name in lowercase, underscored form
    # @private
    ###
    _convertToIdent: (name) -> name.toLowerCase().split(" ").join "_"

    ###
    # Removes us from the page, fails if we have already been killed
    # Note that after this call is made, the menu should be recycled!
    ###
    remove: ->
      if @alive

        ##
        # Unbind listeners
        for f of @functions
          if @functions[f]._ident != undefined
            @_unbindListener @functions[f]._ident
            @functions[f]._ident = undefined

        # Remove ourselves
        $(@getSel()).remove()

        $("body").removeData @getID()

        @alive = false

        return true

      false
