class AWidgetStatusbar extends AWidget

  constructor: (parent) ->
    param.required parent

    @_items = []

    super prefId("astatusbar"), parent, [ "astatusbar" ]

  render: ->
    $(@_sel).html ATemplate.statusbar version: AdefyEditor.version
