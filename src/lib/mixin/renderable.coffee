define (requre) ->

  config = require "config"
  param = require "util/param"

  AUtilLog = require "util/log"

  class Renderable

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

      attributes_s = _.pairs(attributes).map (a) ->
        "#{a[0]}=\"#{a[1]}\""
      .join " "

      """<#{type} #{attributes_s}>#{cb()}</#{type}>"""

    ###
    # render virtual function
    # A render function must create the proper HTML String and return it
    # @return [String]
    ###
    render: ->
      AUtilLog.info "#{@.constructor.name}#render"
      ""

    ###
    # @return [String]
    ###
    renderStub: ->
      AUtilLog.info "#{@.constructor.name}#renderStub"
      ""