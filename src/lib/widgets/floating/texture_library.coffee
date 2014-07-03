define (require) ->

  param = require "util/param"
  TextureLibraryTemplate = require "templates/modal/texture"
  FloatingWidget = require "widgets/floating_widget"
  Project = require "project"

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
    #   @option options [String] direction "left", "top", or "right"
    #   @option options [Number] x x component of origin
    #   @option options [Number] y y component of origin
    #   
    ###
    constructor: (@ui, options) ->
      options ||= {}
      options.direction ||= "top"
      param.required options.x
      param.required options.y

      super @ui, title: "Texture Library", extraClasses: ["texture-library"]

      @setDirection options.direction
      @makeDraggable "#{@getSel()} header"
      @setAnimateSpeed 300

      width = @getElement().width()
      height = @getElement().height()

      TextureLibrary.ACTIVE_LIBRARY.kill() if TextureLibrary.ACTIVE_LIBRARY
      TextureLibrary.ACTIVE_LIBRARY = @

      if options.direction == "top"
        options.x += -width + 24
        options.y += 28
      else if options.direction == "left"
        options.x += (width / 2) + 64
        options.y += 56
      else if options.direction == "right"
        options.x += -width - 24

      @show options.x, options.y

    render: ->
      TextureLibraryTemplate textures: Project.current.getTextures()

    ###
    # Set the direction we spawn from, to properly render the header
    #
    # @param [String] origin "left", "top", or "right"
    ###
    setDirection: (origin) ->
      return if origin != "left" && origin != "top" && origin != "right"

      $("#{@getSel()} header").removeClass "origin-top"
      $("#{@getSel()} header").removeClass "origin-left"
      $("#{@getSel()} header").removeClass "origin-right"
      $("#{@getSel()} header").addClass "origin-#{origin}"

    ###
    # Kill any active texture libraries
    ###
    @close: ->
      TextureLibrary.ACTIVE_LIBRARY.kill() if TextureLibrary.ACTIVE_LIBRARY
      TextureLibrary.ACTIVE_LIBRARY = null

    ###
    # Bind a listener for item clicks. Listeners are automatically removed
    # when we are killed
    #
    # @param [Method] cb
    ###
    setOnItemClick: (cb) ->
      @getElement().on "click", ".tl-entry", (e) ->

        image = $(@).find ".tl-entry-img div"
        filename = $(@).find ".tl-entry-filename"
        dimensions = $(@).find ".tl-entry-dimensions"
        filesize = $(@).find ".tl-entry-filesize"

        info = {}
        info.filename = $(filename).text() if filename

        if image
          rawURL = $(image).css "background-image"
          info.image = rawURL.match(/\((.*?)\)/)[1].replace(/('|")/g, "")

        if dimensions
          dimensionsStr = $(dimensions).text().replace("px", "").split "x"

          info.dimensions =
            w: Number dimensionsStr[0]
            h: Number dimensionsStr[1]

        # Format filesize to bytes
        if filesize
          filesizeStr = $(filesize).text().toLowerCase().replace "b", ""

          if filesizeStr.indexOf("k") >= 0
            info.filsize = Number(filesizeStr.split("k")[0]) * 1024
          else if filesizeStr.indexOf("m") >= 0
            info.filsize = Number(filesizeStr.split("m")[0]) * 1024 * 1024

        cb info
