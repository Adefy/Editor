##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

class AWidgetToolbar extends AWidget

  constructor: (parent) ->
    param.required parent

    @_items = []

    super prefId("toolbar"), parent, [ "toolbar" ]

  render: ->
    $(@_sel).append @genElement "a", class: "button active", =>
      @genElement "i", class: "fa fa-fw fa-square"

    $(@_sel).append @genElement "a", class: "button", =>
      @genElement "i", class: "fa fa-fw fa-circle"

    $(@_sel).append @genElement "a", class: "button", =>
      @genElement "i", class: "fa fa-fw fa-square"
