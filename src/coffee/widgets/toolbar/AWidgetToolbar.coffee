class AWidgetToolbar extends AWidget

  constructor: (parent) ->
    param.required parent

    @_items = []

    super prefId("atoolbar"), parent, [ "atoolbar" ]

  render: ->
    $(@_sel).append @genElement "a", class: "button active", =>
      @genElement "i", class: "fa fa-fw fa-square"

    $(@_sel).append @genElement "a", class: "button", =>
      @genElement "i", class: "fa fa-fw fa-circle"

    $(@_sel).append @genElement "a", class: "button", =>
      @genElement "i", class: "fa fa-fw fa-square"
