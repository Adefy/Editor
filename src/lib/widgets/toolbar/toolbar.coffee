define (require) ->

  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"
  ToolbarTemplate = require "templates/toolbar"

  ###
  # Toolbar, breaks out settings and high-level editor controls
  ###
  class Toolbar extends Widget

    ###
    # @param [UI] ui
    ###
    constructor: (@ui) ->
      super
        id: ID.prefId("toolbar")
        classes: ["toolbar"]
        parent: "header"

    ###
    # Render
    ###
    render: ->
      @getElement().html ToolbarTemplate()
