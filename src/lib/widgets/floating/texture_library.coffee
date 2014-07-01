define (require) ->

  param = require "util/param"
  TextureLibraryTemplate = require "templates/modal/texture"
  FloatingWidget = require "widgets/floating_widget"

  ###
  # Epic texture library widget. Allows the user to upload new texture, delete
  # existing ones, apply textures onto actors, or spawn textured actors
  # directly.
  ###
  class TextureLibrary extends FloatingWidget

    # Keep track of any open library, so we can close it when opening a new one
    ACTIVE_LIBRARY: null

    ###
    # Initialises and displays a texture library
    #
    # @param [Object] options
    #   @option options [String] direction "left", "top", "right", or "bottom"
    #   @option options [Number] x x component of origin
    #   @option options [Number] y y component of origin
    #   
    ###
    constructor: (@ui, options) ->
      super @ui, title: "Texture Library", extraClasses: ["texture-library"]

      @makeDraggable "#{@getSel()} header"
      @setAnimateSpeed 300

      width = @getElement().width()
      height = @getElement().height()

      TextureLibrary.ACTIVE_LIBRARY.kill() if TextureLibrary.ACTIVE_LIBRARY
      TextureLibrary.ACTIVE_LIBRARY = @

      @show options.x - width + 24, options.y + 28

    render: ->
      TextureLibraryTemplate()
