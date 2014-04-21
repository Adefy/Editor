define (require) ->

  param = require "util/param"
  SettingsWidgetTemplate = require "templates/modal/settings"
  FloatingWidget = require "widgets/floating_widget"

  ###
  # Specialized settings widget, drops down from the top of the screen
  ###
  class SettingsWidget extends FloatingWidget

    constructor: (options) ->
      super "", ["settings-widget"]

      @setAnimateSpeed 300
      @setCloseOnFocusLoss()

      @show()

    render: ->
      @getElement().html SettingsWidgetTemplate()

    show: ->
      return if @_visible

      w = @getElement().width()
      x = param.optional x, (window.innerWidth / 2) - (w / 2)

      @getElement().offset left: x, top: @getHiddenY()
      @getElement().css "opacity", 1
      @getElement().animate top: @getVisibleY(), @_animateSpeed, ->
        @_visible = true

    hide: ->
      return unless @_visible

      @getElement().animate top: @getHiddenY(), @_animateSpeed, ->
        @getElement().css "opacity", 0
        @_visible = false

    getVisibleY: ->
      $("#editor > header").height()

    getHiddenY: ->
      @getVisibleY() - @getElement().height()
