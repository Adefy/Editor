define (require) ->

  param = require "util/param"
  TemplateModal = require "templates/modal"
  FloatingWidget = require "widgets/floating_widget"

  ###
  # Generic floating form; provides validation
  ###
  class FloatingForm extends FloatingWidget

    ###
    # Instantiates us with a title and HTML content
    #
    # @param [Object] options
    #   @option [String] title displayed at the top
    #   @option [String] content html content
    #   @option [Method] cb callback, takes an object with input values (key - name)
    #   @option [Method] validation optional, called to validate with cb data
    #   @option [Method] change optional, called on input change with delta and data
    ###
    constructor: (@ui, options) ->
      @_title = param.required options.title
      @_HTMLContent = param.required options.content
      @_submitCB = param.optional options.cb, null
      @_changeCB = param.optional options.change, null
      @_validationCB = param.optional options.validation, null

      super @ui, options

      @setAnimateSpeed 100
      @makeDraggable "#{@_sel} .header"
      @setCloseOnFocusLoss()

      @show()

    registerListeners: ->

      # Submit listener
      $(document).on "click", "#{@_sel} .modal-submit", (e) =>
        @close true

      # Input change
      $(document).on "change", "#{@_sel} input, #{@_sel} select", (e) =>
        @changed e.target

    ###
    # Returns input values as an object with keys the same as input names. The
    # result of this is passed to both the callback and validation methods!
    #
    # @return [Object] data scraped input data [inputName] = inputValue
    ###
    scrapeData: ->
      data = {}

      for i in @getElement("input")
        if $(i).attr("type") != "radio"
          data[$(i).attr("name")] = $(i).val()
        else if $(i).is ":checked"
          data[$(i).attr("name")] = $(i).val()

      for i in @getElement("textarea")
        data[$(i).attr("name")] = $(i).val()

      data

    ###
    # Called when an input is changed.
    #
    # Performs validation if we have a validator, then calls our change
    # callback. The callback is given the name of the changed input, its' value,
    # and a full data scrape.
    #
    # The result of the change callback is interpreted as an absolute change
    # delta, and applied to inputs (hash, of the type "input name" => "value")
    #
    # @param [DOMElement] input input that has changed
    ###
    changed: (input) ->
      param.required input
      return unless @_changeCB

      data = @scrapeData()

      return if @_validation and @_validation(data) != true

      inputName = $(input).attr("name")
      inputValue = $(input).val()

      delta = @_changeCB inputName, inputValue, data

      @getElement("*[name=\"#{d}\"]").val v for d, v of delta

    ###
    # @return [String]
    ###
    render: ->
      super() +
      TemplateModal
        title: @_title
        content: @_HTMLContent
        cb: !!@_submitCB

    ###
    # Submits our contents and kills us (if we are valid!)
    ###
    close: ->
      if @_submitCB
        data = @scrapeData()

        if @validation
          valid = @validation data
          return @setError valid unless valid == true

        @_submitCB data

      @kill()

    ###
    # Sets an error string to display
    #
    # @param [String] error
    ###
    setError: (error) ->
      param.required error
      @getElement(".modal-error").text error
