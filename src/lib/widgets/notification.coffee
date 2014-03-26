define (require) ->

  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"

  # Notification widget, handles stacking
  class Notification extends Widget

    # @property [Number] count Living instance count
    @count: 0

    # @property [Number] cHeight
    @cHeight: 0

    # @property [Object] colors color definitions
    @colors:
      red: "#cc0000"
      green: "#669900"
      blue: "#0099cc"

    # Set to true the first time, signifies the event listener was registered
    # @private
    @_listenersRegistered: false

    # Instantiates and renders us, sets timeout for death
    #
    # @param [Number] msg message to display
    # @param [Number] color notification color
    # @param [Number] life lifetime length in ms, defaults to 2000
    constructor: (msg, color, life) ->
      param.required msg
      color = param.optional color, "blue", [ "blue", "red", "green" ]
      life = param.optional life, 2000

      # For premature timeout clearing
      @timeout = null

      # Register listener
      if not Notification._listenersRegistered

        $(document).ready ->
          $(document).on "click", ".anotification .icon-remove", ->
            target = $("body").data("##{$(@).parent().attr("id")}")
            if target != undefined then target.killMe()

        Notification._listenersRegistered = true

      # Create object
      super ID.prefId("anotification"), "#editor", [ "anotification" ]

      # Build and inject
      _html =  ""
      _html += "<i class=\"icon-remove\"></i>"
      _html += "<p>#{msg}</p>"
      # ...room for more info (a title, icon, etc)

      $(@_sel).html _html

      # Position
      $(@_sel).css
        left: $(window).width() - $(@_sel).width() - 32
        top: 24 + Notification.cHeight + (8  * Notification.count)
        "background-color": Notification.colors[color]

      # Register us on the body
      $("body").data @_sel, @

      # Show
      me = @
      $(@_sel).show()
      $(@_sel).animate { opacity: 1 }, 200, =>
        @timeout = setTimeout (-> me.killMe() ), life

      # Notify others of our existence
      Notification.count++
      Notification.cHeight += $(@_sel).height() + 16

    # A tad morbid, but descriptive. Hides us, clears out the HTML and decrements
    # the counter
    killMe: ->

      if @timeout != null then clearInterval @timeout

      Notification.count--
      Notification.cHeight -= $(@_sel).height() + 16

      $("body").removeData @_sel
      $("#{@_sel} i").css "opacity", "0"
      $(@_sel).animate { opacity: 0 }, 400, => $(@_sel).remove()
