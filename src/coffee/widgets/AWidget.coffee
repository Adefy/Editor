# Widgets are the building blocks of the editor's interface
class AWidget

  # Optionally appends a new div to the body to be used as the container for
  # the widget
  #
  # @param [String] id container id
  # @param [String] parent container parent, defaults to body
  # @param [Array<String>] classes an array containing classes to be applied
  constructor: (id, parent, classes) ->

    # container selector, defaults to no container
    @sel = null

    @parent = param.optional @parent, "body"

    if typeof id == "string" and id.length > 0
      @sel = "##{id}"

      $(@parent).append "<div id=\"#{id}\"></div>"

      # Ship classes
      if classes instanceof Array
        for c in classes
          $(@sel).addClass c
