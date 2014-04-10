define (require) ->

  param = require "util/param"
  ID = require "util/id"

  # Base class for all elements that can be manipulated by the editor
  Handle = class Handle

    ###
    #
    ###
    @_handle: null

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
        "Rename": => window.AdefyEditor.ui.modals.showRename @
        "Delete": => @delete()

      # Give ourselves a unique id so we can be discovered on the body
      @_id = ID.prefId "handle"

      # Attach ourselves to the body
      $("body").data @getId(), @

    ###
    # Get our id. TODO: Consider giving us a base class, possible giving doing
    # the same to Widget
    #
    # @return [String] id
    ###
    getId: -> @_id

    ###
    # Cleans us up. Any classes extending us should also extend this method, and
    # clean up anything it instantiates (I'm looking at you BaseActor)
    ###
    delete: ->

      # Also remove ourselves from the body's object list
      $("body").removeData @getId()

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
    # Get an object containing key/value pairs of contextual functions, in the
    # form name: cb
    #
    # These will be displayed in the context menu when the object is right
    # cliecked on. Again, just like the properties, global properties may be
    # applied by ancestors
    ###
    getContextProperties: ->
      {
        name: @_id
        functions: @_ctx
      }

    ###
    # Dump handle into JSON representation
    #
    # @return [String] actorJSON
    ###
    serialize: ->
      data =
        type: "#{@.constructor.name}"
        properties: {}

      for name, property of @_properties
        data.properties[name] = property.serialize()

      data

    ###
    # Set properties from serialized state
    #
    # @param [String] data
    ###
    cloneFromData: (data) ->
      data = JSON.parse data

      @setPosition data.position

    ###
    # Deserialize properties
    #
    # @param [Object] state saved state with properties object
    ###
    deserialize: (state) ->
      for name, property of state.properties
        if @_properties[name]
          @_properties[name].deserialize property
