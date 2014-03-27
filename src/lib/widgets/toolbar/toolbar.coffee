define (require) ->

  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"

  RectangleActor = require "handles/actors/rectangle"
  PolygonActor = require "handles/actors/polygon"
  TriangleActor = require "handles/actors/triangle"

  ###
  # Toolbar, breaks out objects that we can drag onto the workspace
  ###
  class Toolbar extends Widget

    constructor: (@ui) ->
      @items = [
        icon: "fa-square"
        spawn: (x, y) =>
          new RectangleActor @ui.timeline.getCursorTime(), 100, 100, x, y
      ,
        icon: "fa-circle"
        spawn: (x, y) =>
          new PolygonActor @ui.timeline.getCursorTime(), 5, 100, x, y
      ,
        icon: "fa-gavel"
        spawn: (x, y) =>
          new TriangleActor @ui.timeline.getCursorTime(), 20, 30, x, y
      ]

      # Give items unique IDs
      item.id = ID.nextId() for item in @items

      super
        id: ID.prefId("toolbar")
        classes: ["toolbar"]
        parent: "header"

    render: ->
      for item in @items
        attributes =
          class: "button workspace-drag"
          "data-id": item.id

        $(@_sel).append @genElement "a", attributes, =>
          @genElement "i", class: "fa fa-fw #{item.icon}"

      @setupDraggables()

    getItemById: (id) ->
      _.find @items, (i) -> i.id == id

    setupDraggables: ->
      $("#{@_sel} .workspace-drag").draggable
        addClasses: false
        helper: "clone"
        revert: "invalid"
        cursor: "pointer"
