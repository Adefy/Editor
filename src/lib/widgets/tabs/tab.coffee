define (require) ->

  Widget = require "widgets/widget"

  class Tab extends Widget

    #constructor: (id, parent, klasses, prepend) ->
    #  super id, parent, klasses, prepend

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
    # Iterate through our parents untill we reach our parent sidebar
    ###
    getSidebar: ->
      sidebar = @_parent

      while sidebar.getSidebar
        sidebar = sidebar.getSidebar()

      sidebar
