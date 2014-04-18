define (require) ->

  Widget = require "widgets/widget"

  ###
  # Placed over the canvas, used for highlighting and other special workspace
  # effects.
  ###
  class Overlay extends Widget

    constructor: ->
