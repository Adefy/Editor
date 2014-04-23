define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"

  Widget = require "widgets/widget"

  class Tab extends Widget

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
      #@replaceElement @render()
      @removeElement()
      @getParentElement().append @render()
      @