define (require) ->

  param = require "util/param"
  SelectTextureModal = require "templates/modal/select_texture"
  FloatingWidget = require "widgets/floating_widget"
  ContextMenu = require "widgets/context_menu"

  class FloatingTextureSelect extends FloatingWidget

    ###
    # Instantiates and shows us
    #
    # @param [Array<Texture>] textures list of textures to display
    # @param [BaseActor] targetActor actor to apply textures to
    ###
    constructor: (textures, targetActor) ->
      @_textures = param.required textures
      @_actor = param.required targetActor

      super "Select Texture"

      @setAnimateSpeed 100
      @makeDraggable "#{@_sel} .header"

      @show()

    registerListeners: ->
      $(document).on "click", "#{@_sel} img", (e) =>

        new ContextMenu e.pageX, e.pageY,
          name: "Apply Texture?"
          functions:
            "Yes": =>
              @_actor.setTextureByUID $(e.target).attr "data-uid"
              @kill()
            "No": =>

    render: ->
      @getElement().html SelectTextureModal
        textures: @_textures
