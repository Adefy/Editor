# Base manipulateable class for actors
class AHBaseActor extends AHandle

  # Defines a raw actor, with no shape information or any other presets.
  # This serves as the base for the other actor classes
  constructor: ->

    # Set up properties object (global defaults set)
    super()

    # Default actor properties, common to all actors
    @_properties["position"] =
      type: "composite"
      components:
        x:
          type: "number"
          float: true
          default: 0
        y:
          type: "number"
          float: true
          default: 0

    @_properties["rotation"] =
      type: "number"
      min: 0
      max: 360
      float: true
      default: 0

    @_properties["color"] =
      type: "composite"
      components:
        r:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 0
        g:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 0
        b:
          type: "number"
          min: 0
          max: 255
          float: false
          default: 0

    @_properties["psyx"] =
      type: "bool"
      default: false

    # Note that we don't create an actual actor!
    @_actor = null

  delete: ->

    # For now, this is simple, we just delete the actor. In the future, we will
    # need to remove associated manipulatables, such as timeline elements
    if @_actor != null

      # Notify the workspace
      AWidgetWorkspace.getMe().notifyDemise @

      # Go through and remove ourselves from
      @_actor.destroy()
      @_actor = null

    super()

  # Get internal actors' id. Note that the actor must exist for this!
  #
  # @return [Number] id
  getActorId: -> @_actor.getId()
