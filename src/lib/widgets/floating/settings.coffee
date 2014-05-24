define (require) ->

  param = require "util/param"
  SettingsWidgetTemplate = require "templates/modal/settings"
  FloatingWidget = require "widgets/floating_widget"

  ###
  # Specialized settings widget, drops down from the top of the screen
  ###
  class SettingsWidget extends FloatingWidget

    ###
    # Construct a settings widget with the supplied settings hash and callback
    #
    # The hash should be of the form:
    # [{
    #   type: Number
    #   label: "Some Label"
    #   placeholder: "Some placeholder"
    #   value: 500
    #   id: "foober"
    #   min: 0
    #   max: 1000
    # }, ...]
    #
    # The callback is passed a hash of results, with keys being the ids of the
    # supplied inputs.
    #
    # @param [Object] options
    #   @option [String] title
    #   @option [Array<Object>] settings
    #   @option [Methind] cb
    ###
    constructor: (@ui, options) ->
      @_title = param.required options.title
      @_settings = param.required options.settings
      @_doneCB = param.required options.cb
      @_closeCB = options.cb_close

      super @ui, title: "", extraClasses: ["settings-widget"]

      @setAnimateSpeed 300
      @setCloseOnFocusLoss()

      @show()

    getVisibleY: ->
      $("body > header").height()

    getHiddenY: ->
      @getVisibleY() - @getElement().height()

    render: ->

      settings = _.clone @_settings

      for setting in settings
        if setting.type == Number
          setting.computedType = "number"
        else if setting.type == Boolean
          setting.checked = true if setting.value
          setting.computedType = "checkbox"
        else
          setting.computedType = "text"

      SettingsWidgetTemplate
        settings: settings
        title: @_title

    ###
    # @return [self]
    ###
    show: ->
      return if @_visible

      w = @getElement().width()
      x = x || (window.innerWidth / 2) - (w / 2)

      @getElement().offset left: x, top: @getHiddenY()
      @getElement().css "opacity", 1
      @getElement().animate top: @getVisibleY(), @_animateSpeed, =>
        @_visible = true

      @

    ###
    # @return [self]
    ###
    hide: ->
      return unless @_visible

      @getElement().animate top: @getHiddenY(), @_animateSpeed, =>
        @getElement().css "opacity", 0
        @_visible = false

      @

    ###
    # @return [self]
    ###
    kill: ->
      @_closeCB() if @_closeCB
      super()
      @

    ###
    # @return [self]
    ###
    submit: ->
      @_doneCB @_dumpData()
      super()
      @

    ###
    # Parse data from our HTML element, ready to pass to callback
    #
    # @private
    # @return [Object] data
    ###
    _dumpData: ->
      settings = _.pluck @_settings, "id"

      values = _.map @_settings, (setting) =>

        inputSel = ".input input[data-id=#{setting.id}]"

        if setting.type == Number
          value = Number @getElement(inputSel).val()
        else if setting.type == Boolean
          value = @getElement(inputSel).is(":checked")
        else
          value = @getElement(inputSel).val()

        value

      _.zipObject settings, values
