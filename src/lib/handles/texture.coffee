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

      @__id = ID.objID "texture"
      @_id = @__id.prefix

      @_uid = ID.uID()

      @_url = param.optional options.url, ""
      @_name = param.optional options.name, ""

    ###
    # This is the ID used by handles inside the editor
    # NOTE* This ID can/will change everytime the editor is restarted
    # @return [String]
    ###
    getID: -> @_id

    ###
    # This ID is used to reference the texture in another object
    # Such as an Actor, this ID will remain the same on reload unlike
    # the _id
    # @return [String]
    ###
    getUID: -> @_uid

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

          if @project
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
          del:
            name: "Delete"
            cb: => @contextFuncDelete @
          rename:
            name: "Rename"
            cb: => @contextFuncRename @
      }

    dump: ->
      _.extend Dumpable::dump.call(@),
        textureVersion: "1.2.0"
        id: @_id
        uid: @_uid
        name: @_name
        url: @_url

    load: (data) ->
      Dumpable::load.call @, data

      if data.textureVersion > "1.0.0" || \
       (data.dumpableVersion == "1.0.0" && data.version > "1.1.0")
        @_uid = data.uid

      # we are probably dealing with an old v1.0.0 texture, so we'll
      # need to generate a uid for it
      else
        @_uid = ID.uID()

      @_name = data.name
      @_url = data.url

      @

    @load: (data) ->
      texture = new Texture
      texture.load data

###
  ChangeLog
    dump: "1.0.0"
      Initial

    dump: "1.1.0"
      Added uid

    dump: "1.2.0"
      dumpVersion bump changes

###