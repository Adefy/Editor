define (require) ->

  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"
  StatusBarTemplate = require "templates/statusbar"

  class StatusBar extends Widget

    constructor: ->
      @_items = []

      super
        id: ID.prefId("statusbar")
        parent: "footer"
        classes: [ "statusbar" ]

    render: ->

      # TODO: In order to properly render the version here, we have to remove
      #       the StatusBar dependency from the Editor class, so we can pull
      #       it in here without causing a circular dependency.
      $(@_sel).html StatusBarTemplate version: "FIX ME"
