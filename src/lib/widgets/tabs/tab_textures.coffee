define (require) ->

  ID = require "util/id"
  Tab = require "widgets/tabs/tab"
  TemplateTabTextures = require "templates/tabs/textures"
  TemplateTabTexturesFooter = require "templates/tabs/textures_footer"

  class TexturesTab extends Tab

    ###
    # @param [UIManager] ui
    # @param [SidebarPanel] parent
    ###
    constructor: (@ui, parent) ->
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
      "textures thumbs"

    ###
    # @private
    ###
    _regListeners: ->

      #@_bindContextClick()

      #$(document).on "click", ".files .toggle-directory", (e) =>
      #  @_onToggleDirectory $(e.target).closest(".asset.directory")

    ###
    # @return [String]
    ###
    render: ->
      TemplateTabTextures()

    ###
    # The footer has to be rendered seperately
    # @return [Void]
    ###
    renderFooter: ->
      TemplateTabTexturesFooter()