define (require) ->

  ID = require "util/id"
  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"

  ContextMenu = require "widgets/context_menu"

  Tab = require "widgets/tabs/tab"
  TemplateTabThumb = require "templates/tabs/thumb"
  TemplateTabTexturesFooter = require "templates/tabs/textures_footer"

  class TexturesTab extends Tab

    ###
    # @param [UIManager] ui
    # @param [SidebarPanel] parent
    ###
    constructor: (@ui, parent) ->
      @_viewMode = "list"

      super
        id: ID.prefID("tab-textures")
        parent: parent
        classes: ["tab-textures"]

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
      window.AdefyEditor.ui.modals.showUploadTextures cb: (blob) =>
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
          new ContextMenu e.pageX, e.pageY, texture.getContextProperties()

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
      html = ""

      for texture in @ui.editor.project.textures
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

    respondToEvent: (type, params) ->
      AUtilEventLog.egot "tab.textures", type

      switch type
        when "rename.texture", "upload.textures", "remove.texture", "update.textures"
          # params.texture
          @refresh()
