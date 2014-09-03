define (require) ->

  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"
  TemplateStatusBar = require "templates/statusbar"
  Version = require "version"

  ###
  # That StatusBar!
  ###
  class StatusBar extends Widget

    ###
    # Make that StatusBar!
    ###
    constructor: (@ui, options) ->
      options = param.optional options, {}
      options.id = ID.prefID("statusbar")
      options.classes = param.optional options.classes, []
      options.classes.push "statusbar"

      @_items = []

      super @ui, options

    ###
    # Render that StatusBar! (now with a fancy smancy version number!)
    ###
    render: ->
      super() +
      TemplateStatusBar version: Version.STRING

    ###
    # Update the state of the statusbar
    ###
    update: ->
      ##
      # TODO replace this later with a proper save check
      ##
      needSaving = false
      #@getElement(".version").text Version.STRING # if we ever need to update it
      @getElement(".save").toggleClass "done", !needSaving
