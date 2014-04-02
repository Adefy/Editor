define (require) ->

  param = require "util/param"

  # Bezier curve implementation
  class Bezier

    ###
    # Instantiate with start, end, and control points. Values are expected to be
    # passed in as objects containing (x,y) keys. Only 1st and 2nd degree
    # beziers are expected, with 1 and 2 control points required respectively.
    #
    # If a degree of 0 is passed in, the class returns the result of normal
    # linear interpolation. Sexy linear interpolation at that.
    #
    # Buffering is an optional feature, where eval results are saved, and not
    # recalculated if avaliable. The buffer is discarded if any internal points
    # change.
    #
    # @param [Object] start start point
    # @param [Object] end end point
    # @param [Number] degree 1st or 2nd degree (or 0th for linear interpolation)
    # @param [Array<Object>] control control points
    # @param [Boolean] buffer optionally enables eval buffering
    ###
    constructor: (@_start, @_end, @_degree, @_control, @_buffer) ->
      param.required @_start
      param.required @_end
      param.required @_degree, [0, 1, 2]

      # Set buffering
      @_buffer = param.optional @_buffer, false
      @_bufferData = {}

      # Recyle param to check for coordinates
      param.required @_start.x
      param.required @_start.y
      param.required @_end.x
      param.required @_end.y

      # Simplez brute control param validation
      if @_degree > 0
        param.required @_control

        if @_degree > 1
          param.required @_control[0].x
          param.required @_control[0].y

        if @_degree == 2
          param.required @_control[1].x
          param.required @_control[1].y

    # Evaluate for a certain t, between 0 and 1. Returns a basic object
    # containing (x,y) keys.
    #
    # http://devmag.org.za/2011/04/05/bzier-curves-a-tutorial/
    #
    # @param [Number] t position on the curve, 0.0 - 1.0
    # @return [Object] pos position as an object with (time, value) keys
    eval: (t) ->
      param.required t

      # If buffering is enabled, buffer!
      if @_buffer
        if @_bufferData[String(t)] != undefined
          return @_bufferData[String(t)]

      # Throw an error if t is out of bounds. We could just cap it, but it should
      # never be provided out of bounds. If it is, something is wrong with the
      # code calling us
      if t > 1 or t < 0 then throw new Error "t out of bounds! #{t}"

      # 0th degree, linear interpolation
      if @_degree == 0

        val =
          x: @_start.x + ((@_end.x - @_start.x) * t)
          y: @_start.y + ((@_end.y - @_start.y) * t)

        # Buffer if requested
        if @_buffer then @_bufferData[String(t)] = val

      # 1st degree, quadratic
      else if @_degree == 1

        # Speed things up by pre-calculating some elements
        _Mt = 1 - t
        _Mt2 = _Mt * _Mt
        _t2 = t * t

        # [x, y] = [(1 - t)^2]P0 + 2(1 - t)tP1 + (t^2)P2
        val =
          x: (_Mt2 * @_start.x) + (2 * _Mt * t * @_control[0].x) + _t2 * @_end.x
          y: (_Mt2 * @_start.y) + (2 * _Mt * t * @_control[0].y) + _t2 * @_end.y

        # Buffer if requested
        if @_buffer then @_bufferData[String(t)] = val

      # 2nd degree, cubic
      else if @_degree == 2

        # As above, minimal optimization
        _Mt = 1 - t
        _Mt2 = _Mt * _Mt
        _Mt3 = _Mt2 * _Mt
        _t2 = t * t
        _t3 = _t2 * t

        # [x, y] = [(1 - t)^3]P0 + 3[(1 - t)^2]P1 + 3(1 - t)(t^2)P2 + (t^3)P3
        val =
          x: (_Mt3 * @_start.x) + (3 * _Mt2 * t * @_control[0].x) \
             + (3 * _Mt * _t2 * @_control[1].x) + (_t3 * @_end.x)
          y: (_Mt3 * @_start.y) + (3 * _Mt2 * t * @_control[0].y) \
             + (3 * _Mt * _t2 * @_control[1].y) + (_t3 * @_end.y)

        # Buffer if requested
        if @_buffer then @_bufferData[String(t)] = val

      else throw new Error "Invalid degree, can't evaluate (#{@_degree})"

      val

    ###
    # Enable buffering
    ###
    enableBuffer: -> @_buffer = true

    ###
    # Disable buffering
    ###
    disableBuffer: ->
      @_buffer = false
      @_bufferData = {}
