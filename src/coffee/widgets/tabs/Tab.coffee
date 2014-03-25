##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

class AWidgetTab extends AWidget

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