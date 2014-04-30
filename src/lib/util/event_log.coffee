define ->

  config = require "config"
  AUtilLog = require "util/log"

  class AUtilEventLog

    ###
    # @param [String] tag
    # @param [String] method
    # @param [String] groupname
    # @param [String] type
    ###
    @elog: (tag, method, groupname, type) ->
      if config.debug.event_log
        AUtilLog.debug "[#{tag}] #{method} event(group: \"#{groupname}\" type: \"#{type}\")"

    ###
    # @param [String] tag
    # @param [String] type
    ###
    @epush: (tag, groupname, type) -> @elog tag, "PUSH", groupname, type

    ###
    # @param [String] tag
    # @param [String] type
    ###
    @egot: (tag, groupname, type) -> @elog tag, "GOT", groupname, type

    ###
    # @param [String] tag
    # @param [String] type
    ###
    @eignore: (tag, groupname, type) -> @elog tag, "IGNORE", groupname, type
