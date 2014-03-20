class AWidgetStatusbar extends AWidget

  constructor: (parent) ->
    param.required parent

    @_items = []

    super prefId("astatusbar"), parent, [ "astatusbar" ]

  render: ->
    $(@_sel).append "Version #{AdefyEditor.version}" +
    @genElement "div", class: "save done", =>
      @genElement "i", class: "fa fa-fw fa-circle"