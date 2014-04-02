define ->

  ###
  # The format module is used to convert objects to strings used in the UI
  ###
  class AUtilFormat

    ## Basic types

    ###
    # Formats a given number with precision, if n is not given or
    # n is null: a "-" filled String is returned
    # @overload num()
    # @overload num(n)
    #   @param [Number] n
    # @overload num(n, precision)
    #   @param [Number] n
    #   @param [Number] precision
    # @return [String]
    ###
    @num: (n, precision) ->
      unless isNaN n
        "#{Number(n).toFixed(precision||0)}"
      else
        s = "-"
        if precision && precision > 0 # "-.-"
          s += "."
          for i in [0...precision]
            s += "-"
        else # "--"
          s += "-"
        s

    ###
    # @overload px()
    # @overload px(n)
    #   @param [Number] n
    # @overload px(n, precision)
    #   @param [Number] n
    #   @param [Number] precision
    # @return [String]
    ###
    @px: (n, precision) -> "#{@num(n, precision)}px"

    ###
    # @overload degree()
    # @overload degree(n)
    #   @param [Number] n
    # @overload degree(n, precision)
    #   @param [Number] n
    #   @param [Number] precision
    # @return [String]
    ###
    @degree: (n, precision) -> "#{@num(n, precision)}°"


    ## Composite types

    ###
    # @overload pos()
    # @overload pos(pos)
    #   @param [Position] pos
    # @overload pos(pos, precision)
    #   @param [Position] pos
    #   @param [Number] precision
    # @return [String]
    ###
    @pos: (pos, precision) ->
      if pos
        "#{@num(pos.x, precision)}, #{@num(pos.y, precision)}"
      else
        n = @num(null, precision)
        "#{n}, #{n}"

    ###
    # @overload color()
    # @overload color(color)
    #   @param [Color] color
    # @overload color(color, precision)
    #   @param [Color] color
    #   @param [Number] precision
    # @return [String]
    ###
    @color: (colr, precision) ->
      if colr
        [
          @num(colr.r, precision)
          @num(colr.g, precision)
          @num(colr.b, precision)
        ].join ", "
      else
        n = @num(null, precision)
        "#{n}, #{n}, #{n}"
