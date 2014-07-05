define (requre) ->

  config = require "config"
  param = require "util/param"
  AUtilLog = require "util/log"

  ###
  # A low level class providing basic scaffolding for widgets & other renderable
  # objects. Provides virtual methods for basic rendering, and a generic HTML
  # element generator.
  ###
  class Renderable

    ###
    # Generates a basic HTML element, with the provided attributes
    #
    # @param [String] type
    # @param [Object] attributes optional hash of attributes
    # @param [Method] cb optional method that builds the element body
    # @return [String] html
    ###
    genElement: (type, attributes, cb) ->
      attributes ||= {}
      cb ||= -> ""

      attributes_s = _.pairs(attributes).map (a) ->
        "#{a[0]}=\"#{a[1]}\""
      .join " "

      "<#{type} #{attributes_s}>#{cb()}</#{type}>"

    ###
    # This method is expected to construct a full content HTML string, which
    # will be injected into the outer stub.
    #
    # @return [String] html
    ###
    render: ->
      AUtilLog.info "#{@.constructor.name}#render" if config.debug.render_log
      ""

    ###
    # The stub is the outer HTML element forming renderables. This method is
    # expected to construct the full empty element, which is later injected with
    # the return value of @render()
    #
    # @return [String] stubHTML
    ###
    renderStub: ->
      AUtilLog.info "#{@.constructor.name}#renderStub" if config.debug.render_log
      ""
