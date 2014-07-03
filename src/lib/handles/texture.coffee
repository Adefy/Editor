define (require) ->

  param = require "util/param"
  ID = require "util/id"

  EditorSuperClass = require "superclass"
  Dumpable = require "mixin/dumpable"

  class Texture extends EditorSuperClass

    @include Dumpable

    ###
    # @param [Project] project
    # @param [Hash] options
    ###
    constructor: (@project, options) ->
      param.required project
      param.required options
      param.required options.key
      param.required options.name
      param.required options.size

      @_id = ID.objID("texture").prefixed

      @_uid = options.uid || ID.uID()
      @_name = options.name
      @_size = options.size

      @setKey options.key

    ###
    # This is the ID used by handles inside the editor
    # NOTE* This ID can/will change everytime the editor is restarted
    #
    # @return [String] id
    ###
    getID: -> @_id

    ###
    # This ID is used to reference the texture in another object
    # Such as an Actor, this ID will remain the same on reload unlike
    # the _id
    #
    # @return [String] uid
    ###
    getUID: -> @_uid

    getName: -> @_name
    setName: (@_name) -> @

    getURL: -> @_url
    getSize: -> @_size

    ###
    # Delete context menu callback function
    # @param [Texture] texture
    # @return [self]
    ###
    contextFuncDelete: (texture) ->
      _.remove @project.textures, (t) -> t.getID() == texture.getID()

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
          window.AdefyEditor.ui.pushEvent "rename.texture", texture: t

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
        size: @_size

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
      @_size = data.size

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
