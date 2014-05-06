define (require) ->

  config = require "config"

  param = require "util/param"
  ID = require "util/id"

  EditorObject = require "core/editor_object"
  Dumpable = require "mixin/dumpable"

  class Texture extends EditorObject

    @include Dumpable

    ###
    # @param [Project] project
    # @param [Hash] options
    ###
    constructor: (@project, options) ->
      param.required project
      param.required options
      key  = param.required options.key
      name = param.required options.name

      @_id = ID.objID("texture").prefixed

      @_uid = param.optional options.uid, ID.uID()
      @_name = name

      @setKey key

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

    ###
    # Delete context menu callback function
    # @param [Texture] texture
    # @return [self]
    ###
    contextFuncDelete: (texture) ->
      _.remove @project.textures, (t) -> t.getID() == texture.getID()

      AdefyEditor.ui.events.push "texture", "remove",
        texture: texture

      @

    ###
    # Rename context menu callback function
    # @param [Texture] texture
    # @return [self]
    ###
    contextFuncRename: (texture) ->
      AdefyEditor.ui.modals.showRename texture,
        cb: (t, name) =>
          t.setName(name)
          AdefyEditor.ui.events.push "texture", "rename", texture: t

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
            name: config.locale.del
            cb: => @contextFuncDelete @
          rename:
            name: config.locale.label.rename_modal
            cb: => @contextFuncRename @
      }

    ###
    # Set key and update URL
    #
    # @param [String] key
    ###
    setKey: (key) ->
      @_key = key
      @_url = "#{@project.getCDNUrl()}/#{key}"

    ###
    # @return [Object] data
    ###
    dump: ->
      _.extend Dumpable::dump.call(@),
        textureVersion: "1.2.0"
        id: @_id
        uid: @_uid
        name: @_name
        key: @_key

    ###
    # @param [Object] data
    # @return [self]
    ###
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
      @setKey data.key

      @

    ###
    # @param [Object] data
    # @return [self]
    ###
    @load: (project, data) ->
      param.required project
      param.required data
      texture = new Texture project, data
      texture.load data

###
@ChangeLog

  - "1.0.0": Initial
  - "1.1.0": Added uid
  - "1.2.0": dumpVersion bump changes

###
