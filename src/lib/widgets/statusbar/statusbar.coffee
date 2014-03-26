define [
  "util/id"
  "util/param"
  "widgets/widget"
  "templates/statusbar"
], (ID, param, Widget, StatusBarTemplate) ->

  class StatusBar extends Widget

    constructor: (parent) ->
      param.required parent

      @_items = []

      super ID.prefId("statusbar"), parent, [ "statusbar" ]

    render: ->

      # TODO: In order to properly render the version here, we have to remove
      #       the StatusBar dependency from the Editor class, so we can pull
      #       it in here without causing a circular dependency.
      $(@_sel).html StatusBarTemplate version: "FIX ME"
