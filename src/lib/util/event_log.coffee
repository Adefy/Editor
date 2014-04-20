define ->

  AUtilLog = require "util/log"

  class AUtilEventLog

    ###
    # @type [Boolean]
    ###
    @enabled: false

    ###
    # @param [String] tag
    # @param [String] method
    # @param [String] type
    ###
    @elog: (tag, method, type) ->
      if @enabled
        AUtilLog.debug "[#{tag}] #{method} event(type: \"#{type}\")"

    ###
    # @param [String] tag
    # @param [String] type
    ###
    @epush: (tag, type) -> @elog tag, "PUSH", type

    ###
    # @param [String] tag
    # @param [String] type
    ###
    @egot: (tag, type) -> @elog tag, "GOT", type

    ###
    # @param [String] tag
    # @param [String] type
    ###
    @eignore: (tag, type) -> @elog tag, "IGNORE", type
