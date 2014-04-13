define (require) ->

  ID = require "util/id"
  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"

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
        id: ID.prefId("tab-textures")
        parent: parent
        classes: ["tab-textures"]

      @_registerFooterListeners()
      @_setupDragging()

    ###
    # Setup drag event listeners
    ###
    _setupDragging: ->
      $(document).on "dragstart", "#{@_sel} .thumb .img img", (e) ->
        e.originalEvent.dataTransfer.setData "image/texture", $(e.target).attr "src"

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
      filepicker.pickAndStore
        mimetype: "image/*"
      ,
        location: "S3"
        path: "/ads/assets/"
      , (blob) ->
        #$scope.$apply -> $scope.ad.native.iconURL = blob[0]

    ###
    # @private
    ###
    _registerFooterListeners: ->
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
      html = TemplateTabThumb
        src: "http://www.sacher.com/assets/Uploads/_resampled/croppedimage1220870-0Start.jpg"
        name: "Cake.jpg"
      html += TemplateTabThumb
        src: "http://www.colourbox.com/preview/8468585-163424-hipster-geometric-background-made-of-cubes-retro-hipster-color-mosaic-background-square-composition-with-geometric-shapes-geometric-hipster-retro-background-with-place-for-your-text-retro-background.jpg"
        name: "Retro.jpg"
      html += TemplateTabThumb
        src: "http://placekitten.com/200/200"
        name: "Cat1.jpg"
      html += TemplateTabThumb
        src: "http://placekitten.com/200/300"
        name: "Cat2.jpg"
      html += TemplateTabThumb
        src: "http://placekitten.com/300/300"
        name: "Cat3.jpg"

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
