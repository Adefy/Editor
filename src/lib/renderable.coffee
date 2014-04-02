define (requre) ->

  param = require "util/param"

  class Renderable

    ###
    # render stub function
    ###
    render: ->

    ###
    # For cases where templates don't really make sense
    # @param [String] type
    # @param [Object] attributes optional hash of attributes
    # @param [Method] cb optional method that returns the element body
    # @return [String] html
    ###
    genElement: (type, attributes, cb) ->
      param.required type
      attributes = param.optional attributes, {}
      cb = param.optional cb, -> ""

      attributes_s = _.pairs(attributes).map (a) -> "#{a[0]}=\"#{a[1]}\""

      """
        <#{type} #{attributes_s.join " "}>
          #{cb()}
        </#{type}>
      """

    ###
    # Convenience method for creating buttons with icons in them
    # @param [String] iconName
    # @param [Object] options
    #   @option [Boolean] fixedWidth
    #   @option [Object] buttonAttrs
    #   @option [Object] iconAttrs
    # @return [String] html
    ###
    genButtonIcon: (iconName, options) ->
      options = param.optional options, {}
      buttonAttrs = param.optional options.buttonAttrs, {}
      iconAttrs = param.optional options.iconAttrs, {}

      if options.fixedWidth
        iconKlass = "fa fa-fw fa-#{iconName}"
      else
        iconKlass = "fa fa-#{iconName}"

      iconAttrs["class"] = "" unless iconAttrs["class"]
      iconAttrs["class"] += iconKlass

      @genElement "button", buttonAttrs, =>
        @genElement "i", iconAttrs
