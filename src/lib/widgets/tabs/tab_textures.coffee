define (require) ->

  ID = require "util/id"
  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"

  ContextMenu = require "widgets/context_menu"

  Tab = require "widgets/tabs/tab"
  TemplateTabThumb = require "templates/tabs/thumb"
  TemplateTabTexturesFooter = require "templates/tabs/textures_footer"

  Project = require "project"

  class TexturesTab extends Tab

    ###
    # @param [UIManager] ui
    # @param [SidebarPanel] parent
    ###
    constructor: (@ui, options) ->
      @_viewMode = "list"

      options.id = ID.prefID("tab-textures")
      options.classes = param.optional options.classes, []
      options.classes.push "tab-textures"

      super @ui, options

      @_registerFooterListeners()
      @_setupDragging()

    ###
    # Setup drag event listeners
    ###
    _setupDragging: ->
      $(document).on "dragstart", "#{@_sel} .thumb .img img", (e) ->
        textureID = $(e.target).closest(".thumb").attr "id"
        e.originalEvent.dataTransfer.setData "image/texture", textureID

    ###
    # Does this tab require a Panel footer?
    # @return [Boolean]
    ###
    needPanelFooter: ->
      true

    ###
    # @return [String]
    ###
    cssAppendParentClass: ->
      "textures #{@_viewMode}"

    ###
    # @return [Void]
    ###
    _onToggleViewMode: (mode) ->
      @_viewMode = mode
      @refresh()

    ###
    # @return [Void]
    ###
    _onClickUpload: ->
      @ui.modals.showUploadTextures cb: (blob) =>
        @refresh()

    ###
    # @private
    ###
    _registerFooterListeners: ->

      $(document).on "contextmenu", ".textures .thumb", (e) =>

        project = @ui.editor.project
        textureElement = $(e.target).closest(".thumb")
        textureId = textureElement[0].id
        texture = _.find project.textures, (t) -> t.getID() == textureId

        if texture
          new ContextMenu @ui,
            x: e.pageX, y: e.pageY, properties: texture.getContextProperties()

        e.preventDefault()
        false

      $(document).on "click", ".panel .footer .toggle-list", (e) =>
        @_onToggleViewMode "list"

      $(document).on "click", ".panel .footer .toggle-thumbs", (e) =>
        @_onToggleViewMode "thumbs"

      $(document).on "click", ".panel .footer .upload", (e) =>
        @_onClickUpload()

    ###
    # @return [String]
    ###
    render: ->
      html = super()
      return html unless Project.current

      for texture in Project.current.textures
        html += TemplateTabThumb
          id: texture.getID()
          src: texture.getURL()
          name: texture.getName()

      html

    ###
    # The footer has to be rendered seperately
    # @return [Void]
    ###
    renderFooter: ->
      listActive = ""
      thumbsActive = ""

      listActive = "active" if @_viewMode == "list"
      thumbsActive = "active" if @_viewMode == "thumbs"

      TemplateTabTexturesFooter
        listActive: listActive
        thumbsActive: thumbsActive

    ###
    #
    # @param [Texture] texture
    ###
    updateTexture: (texture) ->

      textureElement = $("##{texture.getID()}")
      textureElement.find(".img img").attr "src", texture.getURL()
      textureElement.find(".name img").text texture.getName()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      AUtilEventLog.egot "tab.textures", type

      switch type
        when "rename.texture", "update.texture"
          @updateTexture params.texture
        when "upload.textures", "remove.texture"
          # params.texture
          @refresh()
