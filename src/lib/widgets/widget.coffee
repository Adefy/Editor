define (requre) ->

  config = require "config"
  param = require "util/param"
  Renderable = require "renderable"

  # Widgets are the building blocks of the editor's interface
  class Widget extends Renderable

    ###
    # Optionally appends a new div to the body to be used as the container for
    # the widget. The parent is either a string selector, or an object offering
    # a getSel() method.
    #
    # @param [String] id container id
    # @param [Object] parent container parent, defaults to "body"
    # @param [Array<String>] classes an array containing classes to be applied
    # @param [Boolean] prepend if true, we are prepended to the parent
    ###
    constructor: (@_id, parent, classes, prepend) ->

      ##
      ## New argument format, all useages need to be migrated to this, then we
      ## can get rid of the old constructor signature (TODO)
      ##
      if typeof @_id == "object"
        parent = @_id.parent
        classes = @_id.classes
        prepend = @_id.prepend
        @_id = @_id.id
      ##
      ##
      ##

      @_parent = param.optional parent, config.selector
      classes = param.optional classes, []
      prepend = param.optional prepend, false

      # container selector, defaults to no container
      @_sel = null

      if "#{@_id}".length > 0

        @_sel = "##{@_id}"

        _parent_sel = ""
        if typeof @_parent == "string"
          _parent_sel = @_parent
        else if @_parent.getSel != undefined and @_parent.getSel != null
          _parent_sel = @_parent.getSel()
        else
          throw new Error "Invalid parent specified!"

        elm = @genElement "div", id: @_id
        if prepend
          $(_parent_sel).prepend elm
        else
          $(_parent_sel).append elm

        # Ship classes
        $(@_sel).addClass c for c in classes

      # Bind a pointer to ourselves on the body, under a key matching our @_sel
      me = @
      $(document).ready -> $("body").data me._sel, me

    ###
    # Retrieve widget selector (typically the id)
    #
    # @return [String] sel
    ###
    getSel: -> @_sel

    ###
    # Retrieve widget's element using its own selector, optional a subSelector
    # can be provided to select an element inside the current.
    #
    # @param [String] subSelector
    #   @optional
    # @return [jQuery] element
    ###
    getElement: (subSelector) ->
      if subSelector
        $("#{@_sel} #{subSelector}")
      else
        $(@_sel)

    ###
    # Return widget id as a string
    #
    # @return [String] id
    ###
    getId: -> "#{@_id}"

    ###
    # Called when the item is dropped on a receiving droppable. Most often,
    # this is the "workspace"
    #
    # @param [String] target droppable identifier, usually "workspace"
    # @param [Number] x x coordinate of drop point
    # @param [Number] y y coordinate of drop point
    # @param [Handle] handle created handle
    ###
    dropped: (target, x, y) -> null
