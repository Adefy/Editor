##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# @depend ../AHTMLRenderable.coffee

# Widgets are the building blocks of the editor's interface
class AWidget extends AHTMLRenderable

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
    @_parent = param.optional parent, "body"
    prepend = param.optional prepend, false

    # container selector, defaults to no container
    @_sel = null

    if "#{@_id}".length > 0

      @_sel = "##{@_id}"

      _parent_sel = ""
      if typeof parent == "string"
        _parent_sel = parent
      else if parent.getSel != undefined and parent.getSel != null
        _parent_sel = parent.getSel()
      else
        throw new Error "Invalid parent specified!"

      elm = @genElement "div", id: @_id
      if prepend
        $(_parent_sel).prepend elm
      else
        $(_parent_sel).append elm

      # Ship classes
      if classes instanceof Array
        for c in classes
          $(@_sel).addClass c

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
  # @param [AHandle] handle created handle
  ###
  dropped: (target, x, y) -> null