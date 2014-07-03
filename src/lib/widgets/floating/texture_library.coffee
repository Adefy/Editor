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
      param.required options.x
      param.required options.y

      super @ui, title: "Texture Library", extraClasses: ["texture-library"]

      @_registerUploadListener()
      @setDirection options.direction || "top"
      @makeDraggable "#{@getSel()} header"
      @setAnimateSpeed 300

      width = @getElement().width()
      height = @getElement().height()

      TextureLibrary.ACTIVE_LIBRARY.kill() if TextureLibrary.ACTIVE_LIBRARY
      TextureLibrary.ACTIVE_LIBRARY = @

      if @_direction == "top"
        options.x += -width + 24
        options.y += 28
      else if @_direction == "left"
        options.x += (width / 2) + 64
        options.y += 56
      else if @_direction == "right"
        options.x += -width - 24

      @show options.x, options.y

    render: ->
      textures = Project.current.getTextures().map (texture) ->
        formatted =
          name: texture.getName()
          url: texture.getURL()

        if texture.getSize() > 1048576
          formatted.size = "#{Math.round(texture.getSize() / 1048576)}MB"
        else
          formatted.size = "#{Math.round(texture.getSize() / 1024)}KB"

        formatted

      TextureLibraryTemplate textures: textures

    _registerUploadListener: ->
      $("#{@getSel()} button.tl-upload, #{@getSel()} .tl-empty a").click =>
        @ui.modals.showUploadTextures cb: (blob) =>
          @refresh()

    ###
    # Set the direction we spawn from, to properly render the header
    #
    # @param [String] origin "left", "top", or "right"
    ###
    setDirection: (origin) ->
      return if origin != "left" && origin != "top" && origin != "right"
      @_direction = origin

      $("#{@getSel()} header").removeClass "origin-top"
      $("#{@getSel()} header").removeClass "origin-left"
      $("#{@getSel()} header").removeClass "origin-right"
      $("#{@getSel()} header").addClass "origin-#{origin}"

    refresh: ->
      super()
      @setDirection @_direction

    ###
    # Kill any active texture libraries
    ###
    @close: ->
      TextureLibrary.ACTIVE_LIBRARY.kill() if TextureLibrary.ACTIVE_LIBRARY
      TextureLibrary.ACTIVE_LIBRARY = null

    ###
    # Check if there are any active texture libraries
    #
    # @return [Boolean] open
    ###
    @isOpen: ->
      !!TextureLibrary.ACTIVE_LIBRARY

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

          if dimensionsStr.length == 2
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
