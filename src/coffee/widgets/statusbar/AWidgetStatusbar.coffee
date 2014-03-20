class AWidgetStatusbar extends AWidget

  constructor: (parent) ->
    param.required parent

    @_items = []

    super prefId("astatusbar"), parent, [ "astatusbar" ]

  render: ->
    ATemplate.statusbar(version: AdefyEditor.version)
