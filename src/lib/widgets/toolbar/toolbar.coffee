define (require) ->

  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"

  class Toolbar extends Widget

    constructor: ->
      @_items = []

      super
        id: ID.prefId("toolbar")
        classes: ["toolbar"]
        parent: "header"

    render: ->
      $(@_sel).append @genElement "a", class: "button active", =>
        @genElement "i", class: "fa fa-fw fa-square"

      $(@_sel).append @genElement "a", class: "button", =>
        @genElement "i", class: "fa fa-fw fa-circle"

      $(@_sel).append @genElement "a", class: "button", =>
        @genElement "i", class: "fa fa-fw fa-square"
