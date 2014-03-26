define ["util/id", "util/param", "widgets/widget"], (ID, param, Widget) ->

  class Toolbar extends Widget

    constructor: (parent) ->
      param.required parent

      @_items = []

      super ID.prefId("toolbar"), parent, [ "toolbar" ]

    render: ->
      $(@_sel).append @genElement "a", class: "button active", =>
        @genElement "i", class: "fa fa-fw fa-square"

      $(@_sel).append @genElement "a", class: "button", =>
        @genElement "i", class: "fa fa-fw fa-circle"

      $(@_sel).append @genElement "a", class: "button", =>
        @genElement "i", class: "fa fa-fw fa-square"
