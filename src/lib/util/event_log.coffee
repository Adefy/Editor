define ->

  AUtilLog = require "util/log"

  class AUtilEventLog

    @enabled: true

    @elog: (tag, meth, type) ->
      if @enabled
        AUtilLog.debug "[#{tag}] #{meth} event(type: \"#{type}\")"

    @epush: (tag, type) -> @elog tag, "PUSH", type
    @egot: (tag, type) -> @elog tag, "GOT", type
    @eignore: (tag, type) -> @elog tag, "IGNORE", type