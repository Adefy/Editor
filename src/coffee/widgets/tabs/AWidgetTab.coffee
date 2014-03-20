class AWidgetTab extends AHTMLRenderable

  constructor: (parent) ->
    @_parent = parent
    @addedParentClass = ""

  render: ->
    #