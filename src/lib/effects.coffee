define (require) ->

  config = require "config"
  param = require "util/param"

  {
    shake: require "effects/shake"
    rock: require "effects/rock"
  }