define (require) ->

  Asset = require "handles/asset"

  class Project

    constructor: ->

      @assets = new Asset @,
        name: "top",
        disabled: ["delete", "rename"],
        isDirectory: true

    dump: ->
      {
        assets: @assets.dump
      }