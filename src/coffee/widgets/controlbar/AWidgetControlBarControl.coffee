##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Control to appear on the controlbar, with inputs and a status
class AWidgetControlBarControl

  # Essential classes broken out for styling (or just to be awesome)
  @classSection: "awcb-section"
  @classTitle: "awcb-section-title"
  @classStatus: "awcb-control-status"
  @classControl: "awcb-control"

  # We add ourselves to AWidgetControlBar's static objects array, so we get
  # rendered with it
  #
  # @param [String] title title to appear on the controlbar
  # @param [String] default status to show
  # @param [Array<Object>] controls an array of control definitions
  constructor: (@title, @status, @controls) ->
    param.required @title
    @status = param.optional @status, "-"
    @controls = param.optional @controls, []

    # Note that the status state defaults to off!
    @statusState = "off"

    # Set to true after @initialize(), prevents future calls
    @_initialized = false

    AWidgetControlBar.getMe().addControl @

  # Helpful function to set up initial state. Called on the next render if it
  # hasn't already been called.
  initialize: ->
    if @_initialized then return

    #

  # Shippp itttt! A bit overexited, eh.
  #
  # @return [String] html rendered html
  render: ->

    # Shorter lines, sacrificing elegance day by day
    c_section = AWidgetControlBarControl.classSection
    c_title = AWidgetControlBarControl.classTitle
    c_status = AWidgetControlBarControl.classStatus
    c_control = AWidgetControlBarControl.classControl

    if not @_initialized
      @initialize()
      @_initialized = true

    _h = ""
    _h += "<div class=\"#{c_section}\">"
    _h +=   "<div class=\"#{c_title}\">#{@title}</div>"

    # Awesome function that lets us bind a click listener, while giving it
    # access to the control's index, along with ourselves. With some simple
    # cBar.controls[i] magic, the cb can modify its own control
    #
    # At least in theory. Will test it soon
    cBar = @
    _registerClickHandler = (myIndex) =>
      $(document).on "click", "##{@controls[myIndex].id}", ->
        cBar.controls[myIndex].cb myIndex

    for c, i in @controls

      # Ensure the control is valid
      param.required c.name
      param.required c.icon
      param.required c.state
      param.optional c.cb

      # Give out ids to controls that don't already have them, and register
      # listeners
      if c.id == undefined or c.id == null

        c.id = prefId "awcbcontrol"
        _registerClickHandler i

      _h += "<div id=\"#{c.id}\" class=\"#{c_control} #{c.state}\">"
      _h +=   c.name
      _h +=  "<i class=\"#{c.icon}\"></i>"
      _h += "</div>"

    _h +=   "<div class=\"#{c_status} #{@statusState}\">#{@status}</div>"
    _h += "</div>"

    _h

  # Set the state of the status. This just changes the class applied to it.
  # This is used internally, but can be called from the outside
  #
  # @param [String] statusState
  # @param [Boolean] render whether or not to immediately re-render
  setStatusState: (@statusState, render) ->
    param.required @statusState
    if render then AWidgetControlBar.getMe().render()

  # Force a certain status. As with @setStatusState, this can be used both
  # internally and externally
  #
  # @param [String] status
  # @param [Boolean] render whether or not to immediately re-render
  setStatus: (@status, render) ->
    param.required @status
    if render then AWidgetControlBar.getMe().render()