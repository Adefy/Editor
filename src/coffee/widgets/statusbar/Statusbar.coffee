##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

class AWidgetStatusbar extends AWidget

  constructor: (parent) ->
    param.required parent

    @_items = []

    super prefId("statusbar"), parent, [ "statusbar" ]

  render: ->
    $(@_sel).html ATemplate.statusbar version: AdefyEditor.version
