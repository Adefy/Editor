define (require) ->

  param = require "util/param"
  ID = require "util/id"

  EditorSuperClass = require "superclass"
  Dumpable = require "mixin/dumpable"
  DropdownWidget = require "widgets/floating/dropdown"

  class Texture extends EditorSuperClass

    @include Dumpable

    ###
    # @param [Project] project
    # @param [Hash] options
    ###
    constructor: (@project, options) ->
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
    # @return [Texture] self
    ###
    contextFuncRename: (texture) ->
      new DropdownWidget @ui,
        title: "Rename"
        settings: [
          type: String
          label: "Name"
          placeholder: "Enter a name"
          value: @name
          id: "name"
        ]
        cb: (results) =>
          texture.setName results.name
          window.AdefyEditor.ui.pushEvent "rename.texture", texture: texture

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
      texture = new Texture project, data
      texture.load data
