define ["widgets/widget"], (Widget) ->

  class Tab extends Widget

    #constructor: (id, parent, klasses, prepend) ->
    #  super id, parent, klasses, prepend

    ###
    # What css class should be appended to the parent element?
    # @return [String]
    ###
    cssAppendParentClass: ->
      ""

    ###
    # @return [String]
    ###
    render: ->
      #
