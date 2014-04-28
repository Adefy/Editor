define (require) ->

  param = require "util/param"
  ID = require "util/id"

  Actors = require "handles/actors"

  EditorObject = require "core/editor_object"
  Dumpable = require "mixin/dumpable"

  # Base class for all elements that can be manipulated by the editor
  Actors.Handle = class Handle extends EditorObject

    @include Dumpable

    ###
    # Instantiates us, should never be called directly. We serve mearly
    # as a base class. Properties are setup here, so set up the property object
    # on extending classes after calling super(). Note that you can un-set
    # properties internally after this is done
    ###
    constructor: ->

      # User modifiable properties
      # Set handle-global properties here
      @_properties = {}

      # Basic right-click menu functions
      @_ctx =
        rename:
          name: "Rename ..."
          cb: => AdefyEditor.ui.modals.showRename @
        del:
          name: "Delete"
          cb: => @delete()

      # Give ourselves a unique id so we can be discovered on the body
      generatedID = ID.objID "handle"
      @_id_numeric = generatedID.id
      @_id = generatedID.prefixed

      @name = "handle #{@_id_numeric}"

      @handleType = "Handle"

      # Attach ourselves to the body
      $("body").data @getID(), @

    ###
    # Helper that hides all of our properties from toolbar rendering
    ###
    hideAllProperties: ->
      for name, property of @_properties
        property.setVisibleInToolbar false

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
    # @return [self]
    ###
    setName: (@name) -> @

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

    # Called once new property values are ready for us, most often by the
    # properties sidebar widget. The update can effect any number of our
    # properties, so we just call their update() methods as needed, after
    # validation
    #
    # @param [Object] updatePacket object containing property:value pairs
    updateProperties: (updatePacket) ->
      param.required updatePacket

      for property, value of updatePacket
        if @_properties[property]
          @_properties[property].setValue value

    ###
    # Set property in key, value form. Note that new properties can not be
    # created!
    #
    # @param [String] key
    # @param [Object] val
    ###
    setProperty: (key, val) ->
      param.required key
      param.required val

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
        handleType: @handleType
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
        if @_properties[name]
          @_properties[name].load property

      @

###
@Changelog

  - "1.0.0": Initial
  - "1.0.1": Added name
  - "1.1.0": Added handleType

###
