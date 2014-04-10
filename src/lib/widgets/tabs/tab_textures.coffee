define (require) ->

  ID = require "util/id"
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

      @_regListeners()

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

    _onToggleViewMode: (mode) ->
      @_viewMode = mode
      @refresh()

    ###
    # @private
    ###
    _regListeners: ->
      $(document).on "click", ".panel .footer .toggle-list", (e) =>
        console.log e
        @_onToggleViewMode "list"

      $(document).on "click", ".panel .footer .toggle-thumbs", (e) =>
        console.log e
        @_onToggleViewMode "thumbs"

    ###
    # @return [String]
    ###
    render: ->
      TemplateTabThumb
        src: "http://www.sacher.com/assets/Uploads/_resampled/croppedimage1220870-0Start.jpg"
        name: "Cake.jpg"

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