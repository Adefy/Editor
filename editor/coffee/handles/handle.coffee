define (require) ->

  param = require "util/param"
  ID = require "util/id"
  config = require "config"

  EditorSuperClass = require "superclass"
  Dumpable = require "mixin/dumpable"
  DropdownWidget = require "widgets/floating/dropdown"

  # Base class for all elements that can be manipulated by the editor
  window.Handle = class Handle extends EditorSuperClass

    @include Dumpable

    ###
    # Instantiates us, should never be called directly. We serve mearly
    # as a base class. Properties are setup here, so set up the property object
    # on extending classes after calling super(). Note that you can un-set
    # properties internally after this is done
    #
    # @param [UIManager] ui
    ###
    constructor: (@ui) ->

      # User modifiable properties
      # Set handle-global properties here
      @_properties = {}

      # Basic right-click menu functions
      @_ctx =
        rename:
          name: "#{config.strings.rename}..."
          prepend: true
          cb: =>

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
                @setName results.name

        del:
          name: config.strings.delete
          cb: => @delete()
          append: true

      # Give ourselves a unique id so we can be discovered on the body
      generatedID = ID.objID "handle"
      @_id_numeric = generatedID.id
      @_id = generatedID.prefixed

      @name = "handle #{@_id_numeric}"

      @_handleType = "Handle"

    ###
    # Get our id. TODO: Consider giving us a base class, possible giving doing
    # the same to Widget
    #
    # @return [String] id
    ###
    getID: -> @_id

    ###
    # Return's the handle's name
    # @return [String] name
    ###
    getName: -> @name

    ###
    # Set the handle's name
    # @param [String] name
    # @return [Handle] self
    ###
    setName: (@name) ->
      @ui.pushEvent "renamed.handle", handle: @
      @

    ###
    # Cleans us up. Any classes extending us should also extend this method, and
    # clean up anything it instantiates (I'm looking at you BaseActor)
    ###
    delete: ->

      # Also remove ourselves from the body's object list
      $("body").removeData @getID()

    ###
    # Returns an object representing the modifiable properties the object holds,
    # in key/value form. Default values are set in the constructor, after that
    # modifications are made through the other accessor.
    ###
    getProperties: -> @_properties

    ###
    # Set property in key, value form. Note that new properties can not be
    # created!
    #
    # @param [String] key
    # @param [Object] val
    ###
    setProperty: (key, val) ->

      # Prevent creation of new properties
      if @_properties[key] != undefined then @_properties[key] = val

    ###
    # Get an object describing the context menu shown when we are right-clicked
    #
    # The object should provide a "name" key, and a "functions" key. Functions
    # should be a hash of names and methods.
    ###
    getContextProperties: ->
      {
        name: @getName()
        functions: @_ctx
      }

    ###
    # Dump handle into basic Object
    #
    # @return [Object] data
    ###
    dump: ->
      data = _.extend Dumpable::dump.call(@),
        handleVersion: "1.1.0"
        _handleType: @_handleType
        type: "#{@.constructor.name}"
        name: @name
        properties: {}

      for name, property of @_properties
        data.properties[name] = property.dump()

      data

    ###
    # Load properties
    #
    # @param [Object] data
    ###
    load: (data) ->
      Dumpable::load.call @, data
      @name = data.name || "handle #{@_id_numeric}"

      for name, property of data.properties
        @_properties[name].load property if @_properties[name]

      @
