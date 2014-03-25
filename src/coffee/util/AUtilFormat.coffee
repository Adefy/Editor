##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

###
# The format module is used to convert objects to strings used in the UI
###
class AUtilFormat

  ## Basic types

  ###
  # Formats a given number with precision (preci), if n is not given or
  # n is null: a "-" filled String is returned
  # @overload num()
  # @overload num(n)
  #   @param [Number] n
  # @overload num(n, preci)
  #   @param [Number] n
  #   @param [Number] preci
  # @return [String]
  ###
  @num: (n, preci) ->
    if n
      "#{n.toFixed(preci||0)}"
    else
      s = "-"
      if preci && preci > 0 # "-.-"
        s += "."
        for i in 0...preci
          s += "-"
      else # "--"
        s += "-"
      s

  ###
  # @overload px()
  # @overload px(n)
  #   @param [Number] n
  # @overload px(n, preci)
  #   @param [Number] n
  #   @param [Number] preci
  # @return [String]
  ###
  @px: (n, preci) -> "#{@num(n, preci)}px"

  ###
  # @overload degree()
  # @overload degree(n)
  #   @param [Number] n
  # @overload degree(n, preci)
  #   @param [Number] n
  #   @param [Number] preci
  # @return [String]
  ###
  @degree: (n, preci) -> "#{@num(n, preci)}°"


  ## Composite types

  ###
  # @overload pos()
  # @overload pos(pos)
  #   @param [Position] pos
  # @overload pos(pos, preci)
  #   @param [Position] pos
  #   @param [Number] preci
  # @return [String]
  ###
  @pos: (pos, preci) ->
    if pos
      "#{@num(pos.x, preci)}, #{@num(pos.y, preci)}"
    else
      n = @num(null, preci)
      "#{n}, #{n}"

  ###
  # @overload color()
  # @overload color(color)
  #   @param [Color] color
  # @overload color(color, preci)
  #   @param [Color] color
  #   @param [Number] preci
  # @return [String]
  ###
  @color: (colr, preci) ->
    if colr
      "#{@num(colr.r, preci)}, #{@num(colr.g, preci)}, #{@num(colr.b, preci)}"
    else
      n = @num(null, preci)
      "#{n}, #{n}, #{n}"

window.aformat = AUtilFormat