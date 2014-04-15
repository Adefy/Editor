define (require) ->

  #AUtilLog = require "util/log"
  param = require "util/param"
  ID = require "util/id"
  Widget = require "widgets/widget"
  TemplateModal = require "templates/modal"

  # Bootstrap-like modal (except not!)
  class Modal extends Widget

    ###
    # Set to true once our event listeners have been registered
    # @type [Boolean]
    # @private
    ###
    @__listenersRegistered: false

    ###
    # Instantiates us with a title and HTML content
    #
    # @param [Object] options
    #   @option [String] title displayed at the top
    #   @option [String] content html content
    #   @option [Boolean] modal direct action required, defaults to false
    #   @option [Method] cb callback, takes an object with input values (key - name)
    #   @option [Method] validation optional, called to validate with cb data
    #   @option [Method] change optional, called on input change with delta and data
    ###
    constructor: (options) ->
      @title = param.required options.title
      @content = param.required options.content
      modal = param.optional options.modal, false
      @cb = param.optional options.cb, null
      @change = param.optional options.change, null
      @validation = param.optional options.validation, null

      # Only one modal can be active at any one time
      if $("body").data("activeModal") != undefined
        $("body").data("activeModal").close()
        $("body").removeData "activeModal"

      # Protection against premature resurrection
      @dead = true

      super
        id: ID.prefId("modal")
        classes: [ "modal" ]

      @show()

      unless Modal.__listenersRegistered
        Modal.__listenersRegistered = true

        # Closing non-modal on clicking
        $(document).mouseup (e) ->
          return unless $("body").data("activeModal")
          
          us = $($("body").data("activeModal")._sel)

          # Clicked outside of us, hide if we aren't modal
          if !us.is(e.target) && us.has(e.target).length == 0
            $("body").data("activeModal").close() unless modal

        # Close modal on dismiss click
        $(document).on "click", ".modal .modal-dismiss", ->
          id = $(@).closest(".modal").attr "id"
          $("body").data("##{id}").close()

        # Close dialog on submit
        $(document).on "click", ".modal .modal-submit", ->
          id = $(@).closest(".modal").attr "id"
          $("body").data("##{id}").close true

        # Input change
        $(document).on "change", ".modal input, .modal select", (e) ->
          id = $(@).closest(".modal").attr "id"
          $("body").data("##{id}").changed e.target

    ###
    # Returns input values as an object with keys the same as input names. The
    # result of this is passed to both the callback and validation methods!
    #
    # @return [Object] data scraped input data [inputName] = inputValue
    ###
    scrapeData: ->
      data = {}

      for i in @getElement("input")
        if $(i).attr("type") != "radio" then data[$(i).attr("name")] = $(i).val()
        else if $(i).is ":checked" then data[$(i).attr("name")] = $(i).val()

      for i in @getElement("textarea")
        data[$(i).attr("name")] = $(i).val()

      data

    ###
    # Called when an input is changed, validates and in turn calls @change() if
    # provided. Passes name of altered input, new value, and a full data scrape.
    #
    # @change is expected to return altered values, if an update is desired
    #
    # @param [Object] i input that has changed
    ###
    changed: (i) ->
      param.required i

      return if @change == null
      data = @scrapeData()

      return if @validation and @validation(data) != true
      delta = @change $(i).attr("name"), $(i).val(), data

      @getElement("*[name=\"#{d}\"]").val v for d, v of delta

    ###
    # Injects and shows us. Doesn't work if we aren't dead
    ###
    show: ->
      return unless @dead
      @dead = false

      @getElement().html TemplateModal
        title: @title
        content: @content
        cb: !!@cb

      # Register us for later
      $("body").data "activeModal", @

      @getElement().animate opacity: 1, 200

    ###
    # Closes and kills us
    #
    # @param [Boolean] submit optional, signifies we need to call the cb
    ###
    close: (submit) ->
      submit = param.optional submit, false

      if submit
        # If a callback was supplied, parse inputs and send
        if @cb

          data = @scrapeData()

          # If a validation method was also supplied, bail with an error if
          # validation fails
          if @validation != null
            valid = @validation data

            if valid != true
              @setError valid
              return

          @cb data

        if @dead then return else @dead = true

        unless @getElement().is ":visible"
          @_kill()
        else
          @getElement().animate { opacity: 0 }, 200, => @_kill()
      else
        unless @getElement().is ":visible"
          @_kill()
        else
          @getElement().animate { opacity: 0 }, 200, => @_kill()

    ###
    # Sets an error string to display
    #
    # @param [String] error
    ###
    setError: (error) ->
      param.required error
      @getElement(".modal-error").text error

    ###
    # Private kill method, called once we are no longer visible
    # @private
    ###
    _kill: ->
      $("body").removeData "activeModal"
      @getElement().remove()
