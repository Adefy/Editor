define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"

  # Context menu widget, created when a handle is right-clicked and
  # supports actions
  class ContextMenu extends Widget

    ###
    # Set to true after initial instantiation, prevents redundant listeners
    ###
    @_registeredMouseup: false

    ###
    # @property [Boolean] animate enables/disables animation, true by default
    ###
    @animate: true

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
    # @param [Handle] handle object to create menu for
    ###
    constructor: (x, y, handle) ->
      param.required x
      param.required y
      param.required handle

      # Sanity check
      if handle.getContextFunctions == undefined
        AUtilLog.warn "Object has no getContextFunctions, can't create context-menu"
        return

      @functions = handle.getContextFunctions() # Grab functions
      @alive = true # Set to false upon removal

      # Silently drop out, empty ctx menu is allowed, we just do nothing
      if $.isEmptyObject(@functions) then return

      # Create object
      super
        id: ID.prefId("context-menu")
        classes: [ "context-menu" ]

      # Add a handle to our instance on the body
      $("body").data @getId(), @

      # Position and inject ourselves
      $(@_sel).css
        left: x
        top: y
      $(@_sel).html @_buildHTML()

      if ContextMenu.animate
        $(@_sel).slideDown ContextMenu.animateSpeed
      else
        $(@_sel).show()

    ###
    # Builds the html for the rendered menu, called in the constructor. Useful
    # to break it out here for testing and whatnot.
    #
    # @return [String] html ready for injection
    # @private
    ###
    _buildHTML: ->
      @genElement "ul", {}, =>

        __bindListener = (f) =>
          # Insane in da membrane
          if typeof @functions[f] != "function"
            AUtilLog.error "Only methods can be bound to context menu items"
            return

          $(document).on "click", "[data-id=\"#{@functions[f]._ident}\"]", =>
            @remove()
            @functions[f]()

        __html = ""
        for f of @functions

          # If f already has an identifier set, unbind any existing listeners
          if @functions[f]._ident != undefined
            @_unbindListener @functions[f]._ident

          # We set a unique identifier for the element to use, and bind listeners
          @functions[f]._ident = @_convertToIdent(f) + ID.nextId()

          _attrs = {}
          _attrs["data-id"] = @functions[f]._ident

          __html += @genElement "li", _attrs, => f

          # Bind listener
          __bindListener f

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
                    ins.remove()
                else
                  ins.remove()

          ContextMenu._registeredMouseup = true

        __html

    ###
    # Shorthand, used in @_buildHTML and @remove
    #
    # @param [String] ident
    # @private
    ###
    _unbindListener: (ident) -> $(document).off "click", "[data-id=\"#{ident}\"]"

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

        # Unbind listeners
        for f of @functions
          if @functions[f]._ident != undefined
            @_unbindListener @functions[f]._ident
            @functions[f]._ident = undefined

        # Remove ourselves
        $(@getSel()).remove()

        $("body").removeData @getId()

        @alive = false
