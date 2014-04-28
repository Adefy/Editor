define (require) ->

  config = require "config"
  param = require "util/param"

  class Effects

    @shake: require "effects/shake"