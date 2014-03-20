class AWidgetStatusbar extends AWidget

  constructor: (parent) ->
    param.required parent

    @_items = []

    super prefId("statusbar"), parent, [ "statusbar" ]

  render: ->
    $(@_sel).html ATemplate.statusbar version: AdefyEditor.version
