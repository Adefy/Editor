##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Bootstrap-like modal (except not!)
class AWidgetModal extends AWidget

  # Set to true once our event listeners have been registered
  # @private
  @__listenersRegistered: false

  # Instantiates us with a title and HTML content
  #
  # @param [String] title displayed at the top
  # @param [String] content html content
  # @param [Boolean] modal direct action required, defaults to false
  # @param [Method] cb callback, takes an object with input values (key - name)
  # @param [Method] validation optional, called to validate with cb data
  # @param [Method] change optional, called on input change with delta and data
  constructor: (@title, @content, modal, @cb, @validation, @change) ->
    param.required @title
    param.required @content
    modal = param.optional modal, false
    @cb = param.optional @cb, null
    @change = param.optional @change, null
    @validation = param.optional @validation, null

    # Only one modal can be active at any one time
    if $("body").data("activeModal") != undefined
      $("body").data("activeModal").close()
      $("body").removeData "activeModal"

    # Protection against premature resurrection
    @dead = true

    super prefId("amodal"), "#aeditor", [ "amodal" ]

    @show()

    if not AWidgetModal.__listenersRegistered
      AWidgetModal.__listenersRegistered = true

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
        $(document).on "click", ".amodal .amf-dismiss", ->
          id = $(@).closest(".amodal").attr "id"
          $("body").data("##{id}").close()

        # Close dialog on submit
        $(document).on "click", ".amodal .amf-submit", ->
          id = $(@).closest(".amodal").attr "id"
          $("body").data("##{id}").close true

        # Input change
        $(document).on "change", ".amodal input", (e) ->
          id = $(@).closest(".amodal").attr "id"
          $("body").data("##{id}").changed e.target

  # Returns input values as an object with keys the same as input names. The
  # result of this is passed to both the callback and validation methods!
  #
  # @return [Object] data scraped input data [inputName] = inputValue
  scrapeData: ->
    data = {}
    data[$(i).attr("name")] = $(i).val() for i in $("#{@_sel} input")
    data

  # Called when an input is changed, validates and in turn calls @change() if
  # provided. Passes name of altered input, new value, and a full data scrape.
  #
  # @change is expected to return altered values, if an update is desired
  #
  # @param [Object] i input that has changed
  changed: (i) ->
    param.required i

    if @change == null then return
    data = @scrapeData()

    if @validation != null then if @validation(data) != true then return
    delta = @change $(i).attr("name"), $(i).val(), data

    $("#{@_sel} input[name=\"#{d}\"]").val v for d, v of delta

  # Injects and shows us. Doesn't work if we aren't dead
  show: ->
    if not @dead then return else @dead = false

    # Build!
    _html =  "<div class=\"aminner\">"
    _html +=   "<span class=\"amtitle\">#{@title}</span>"
    _html +=   "<div class=\"ambody\">#{@content}</span>"
    _html +=   "<div class=\"amfooter\">"
    _html +=     "<span class=\"amerror\"></span>"
    _html +=     "<button class=\"amf-dismiss\">Close</button>"

    if @cb != null
      _html += "<button class=\"amf-submit\">Submit</button>"

    _html +=   "</div>"
    _html += "</div>"

    $(@_sel).html _html

    # Register us for later
    $("body").data "activeModal", @

    $(@_sel).animate { opacity: 1 }, 400

  # Closes and kills us
  #
  # @param [Boolean] submit optional, signifies we need to call the cb
  close: (submit) ->
    submit = param.optional submit, false

    # If a callback was supplied, parse inputs and send
    if @cb != null

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

  # Sets an error string to display
  #
  # @param [String] error
  setError: (error) ->
    param.required error

    $("#{@_sel} .amerror").text error

  # Private kill method, called once we are no longer visible
  # @private
  _kill: ->
    $("body").removeData "activeModal"
    $(@_sel).remove()