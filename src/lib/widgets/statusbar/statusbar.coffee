define (require) ->

  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"
  StatusBarTemplate = require "templates/statusbar"
  Version = require "version"

  ###
  # That StatusBar!
  ###
  class StatusBar extends Widget

    ###
    # Make that StatusBar!
    ###
    constructor: ->
      @_items = []

      super
        id: ID.prefId("statusbar")
        parent: "footer"
        classes: [ "statusbar" ]

    ###
    # Render that StatusBar! (now with a fancy smancy version number!)
    ###
    render: ->
      @getElement().html StatusBarTemplate version: Version.STRING

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
