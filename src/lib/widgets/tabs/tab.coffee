define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"

  Widget = require "widgets/widget"

  class Tab extends Widget

    #constructor: (id, parent, klasses, prepend) ->
    #  super id, parent, klasses, prepend

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
      @getId()

    ###
    # @return [String]
    ###
    render: ->
      #

    ###
    # @return [Void]
    ###
    postRender: ->
      #

    ###
    # Iterate through our parents untill we reach our parent sidebar
    ###
    getSidebar: ->
      sidebar = @_parent

      while sidebar.getSidebar
        sidebar = sidebar.getSidebar()

      sidebar

    ###
    # Tabs do not refresh themselves sadly, so ask the parents to refresh them
    ###
    refresh: ->
      @_parent.refresh() if @_parent.refresh