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
    constructor: (@ui, options) ->
      @_textures = options.textures
      @_actor = options.actor

      super @ui, title: "Select Texture"

      @setAnimateSpeed 100
      @makeDraggable "#{@_sel} .header"

      @show()

    registerListeners: ->
      $(document).on "click", "#{@_sel} img", (e) =>

        new ContextMenu @ui,
          x: e.pageX
          y: e.pageY
          properties:
            name: "Apply Texture?"
            functions:
              ok:
                name: "Yes"
                cb: =>
                  @_actor.setTextureByUID $(e.target).attr "data-uid"
                  @kill()
              cancel:
                name: "No"
                cb: =>

    render: ->
      SelectTextureModal
        textures: @_textures
