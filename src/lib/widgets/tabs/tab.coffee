define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"

  Widget = require "widgets/widget"

  class Tab extends Widget

    ###
    # @param [UIManager] ui
    # @param [Object] options
    ###
    constructor: (@ui, options) ->
      super @ui, options

    ###
    # @return [Boolean] needPanelFooter do we need a panel footer?
    ###
    needPanelFooter: -> false

    ###
    # @return [HTML]
    ###
    renderFooter: -> ""

    ###
    # What css class should be appended to the parent element?
    # @return [String]
    ###
    cssAppendParentClass: ->
      @getClasses().join " "

    ###
    # What should the content id of the tab be
    # @return [String]
    ###
    appendParentId: ->
      @getID()

    ###
    # Iterate through our parents untill we reach our parent sidebar
    # @return []
    ###
    getSidebar: ->
      sidebar = @_parent

      while sidebar.getSidebar
        sidebar = sidebar.getSidebar()

      sidebar

    ###
    # @return [String]
    ###
    render: ->
      super()

    ###
    # @return [Void]
    ###
    postRefresh: ->
      super()

    ###
    # @return [self]
    ###
    refresh: ->
      # tabs replace their content in the parent instead of self managing
      @getElement().html @render()
      @_parent.onChildRefresh @ if @_parent
      @

    ###
    # @return [self]
    ###
    onUpdate: ->
      @_parent.onChildUpdate @ if @_parent
      @
