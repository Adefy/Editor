define [
  "util/id"
  "util/param"
  "widgets/widget"
  "templates/modal"
], (ID, param, Widget, ModalTemplate) ->

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

      super ID.prefId("modal"), "#aeditor", [ "modal" ]

      @show()

      if not Modal.__listenersRegistered
        Modal.__listenersRegistered = true

        me = @
        $(document).ready ->

          # Closing non-modal on clicking
          $(document).mouseup (e) ->

            if $("body").data("activeModal") == undefined then return
            else us = $($("body").data("activeModal")._sel)

            # Clicked outside of us, hide if we aren't modal
            if !us.is(e.target) && us.has(e.target).length == 0
              if not modal then $("body").data("activeModal").close()

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

      for i in $("#{@_sel} input")
        if $(i).attr("type") != "radio" then data[$(i).attr("name")] = $(i).val()
        else if $(i).is ":checked" then data[$(i).attr("name")] = $(i).val()

      for i in $("#{@_sel} textarea")
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

      if @change == null then return
      data = @scrapeData()

      if @validation != null then if @validation(data) != true then return
      delta = @change $(i).attr("name"), $(i).val(), data

      $("#{@_sel} *[name=\"#{d}\"]").val v for d, v of delta

    ###
    # Injects and shows us. Doesn't work if we aren't dead
    ###
    show: ->
      if not @dead then return else @dead = false

      # Build!
      $(@_sel).html ModalTemplate title: @title, content: @content, cb: !!@cb

      # Register us for later
      $("body").data "activeModal", @

      $(@_sel).animate { opacity: 1 }, 400

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

        if not $(@_sel).is ":visible" then @_kill()
        else $(@_sel).animate { opacity: 0 }, 400, => @_kill()
      else
        if not $(@_sel).is ":visible" then @_kill()
        else $(@_sel).animate { opacity: 0 }, 400, => @_kill()

    ###
    # Sets an error string to display
    #
    # @param [String] error
    ###
    setError: (error) ->
      param.required error

      $("#{@_sel} .modal-error").text error

    ###
    # Private kill method, called once we are no longer visible
    # @private
    ###
    _kill: ->
      $("body").removeData "activeModal"
      $(@_sel).remove()
