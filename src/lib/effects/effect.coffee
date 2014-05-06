define (require) ->

  config = require "config"
  param = require "util/param"

  SettingsWidget = require "widgets/floating/settings"

  class Effect

    @title: "Effect"

    @types:
      number: Number
      string: String
      object: Object

    @properties: {}

    @getSettings: ->
      settings = []
      for key, info of @properties
        def = null
        if info.def
          def = info.def()

        settings.push
          label: info.label
          type: @types[info.type]
          value: def
          id: key

      settings

    @execute: ->
      #

    @dialog: (ui, cb) ->
      new SettingsWidget ui,
        title: @title
        settings: @getSettings()
        cb: cb