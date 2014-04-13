define (require) ->

  param = require "util/param"
  ID = require "util/id"

  EditorObject = require "editor_object"
  Dumpable = require "mixin/dumpable"

  class Texture extends EditorObject

    @include Dumpable

    ###
    # @param [Hash] options
    ###
    constructor: (options) ->
      options = param.optional options, {}

      @project = null

      @__id = ID.objId "texture"
      @_id = @__id.prefix
      @_url = param.optional options.url, ""
      @_name = param.optional options.name, ""

    getID: -> @_id
    getName: -> @_name
    setName: (@_name) -> @
    getURL: -> @_url
    setURL: (@_url) -> @

    ###
    # Delete context menu callback function
    # @param [Texture] texture
    # @return [self]
    ###
    contextFuncDelete: (texture) ->
      if @project
        @project.textures = _.without @project.textures, (t) ->
          t._id == texture._id

        window.AdefyEditor.ui.pushEvent "remove.texture",
          texture: texture

      @

    ###
    # Rename context menu callback function
    # @param [Texture] texture
    # @return [self]
    ###
    contextFuncRename: (texture) ->
      window.AdefyEditor.ui.modals.showRename texture,
        cb: (t, name) =>
          t.setName(name)
          window.AdefyEditor.ui.pushEvent "rename.texture",
            texture: t

        validate: (t, name) =>
          return "Name must be longer than 3 characters" if name.length <= 3

          isNotUnique = _.any @project.textures, (t2) -> t2._name == name
          return "Name must be unique" if isNotUnique

          true
      @

    ###
    # @return [Object]
    ###
    getContextProperties: ->
      {
        name: @getName()
        functions:
          "Delete": => @contextFuncDelete @
          "Rename": => @contextFuncRename @
      }

    dump: ->
      _.extend Dumpable::dump.call(@),
        version: "1.0.0"
        id: @_id
        name: @_name
        url: @_url

    load: (data) ->
      Dumpable::load.call @, data

      @_name = data.name
      @_url = data.url

      @

    @load: (data) ->
      texture = new Texture
      texture.load data
