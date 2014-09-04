define (require) ->

  config = require "config"
  param = require "util/param"
  AUtilLog = require "util/log"

  EditorSuperClass = require "superclass"
  Renderable = require "mixin/renderable"
  Dumpable = require "mixin/dumpable"

  # Widgets are the building blocks of the editor's interface
  class Widget extends EditorSuperClass

    @include Renderable
    @include Dumpable

    ###
    # Optionally appends a new div to the body to be used as the container for
    # the widget. The parent is either a string selector, or an object offering
    # a getSel() method.
    #
    # Offers smart listener management, unbinding them on removal
    #
    # @param [UIManager] ui
    # @param [Object] options
    #   @option [ID] id
    #   @option [Object] parent
    #   @option [Array<String>] classes
    #   @option [Array<Object>] listeners
    ###
    constructor: (@ui, options) ->
      options ||= {}

      @_id = options.id
      @_parent = options.parent || ".editor"
      @_classes = options.classes || []
      @_listeners = options.listeners || []

      # If static, we always render the same HTML
      @_static = !!options.static
      @_staticHTML = options.html

      # Container selector
      @_sel = "##{@_id}" if "#{@_id}".length > 0

      # Bind listeners
      for listener in @_listeners
        if listener.prefixSelf
          selector = "#{@_sel} #{listener.sel}"
        else
          selector = listener.sel

        $(document).on listener["event"], selector, listener.cb

    ###
    # Removes our HTML from the document, and unbinds any listeners. Widgets
    # are expected to be discarded after this method is called.
    ###
    remove: ->

      # Unbind listeners
      for listener in @_listeners
        $(document).off listener["event"], listener.sel, listener.cb

      $(@getSel()).remove()

    ###
    # Called by the UIManager at the end of a hard refresh.
    #
    # @return [Widget] self
    ###
    postInit: -> @

    ###
    # Get the classes present on our main element
    #
    # @return [Array<String>] classes
    ###
    getClasses: -> @_classes

    ###
    # Retrieve widget selector (typically the id)
    #
    # @return [String] sel
    ###
    getSel: -> @_sel

    ###
    # Retrieve widget's parent selector (typically the id)
    #
    # @return [String] sel
    ###
    getParentSel: ->
      if typeof @_parent == "string"
        @_parent
      else if @_parent.getSel != undefined and @_parent.getSel != null
        @_parent.getSel()
      else
        throw new Error "Invalid parent specified!"

    ###
    # Retrieve widget's element using its own selector, optional a subSelector
    # can be provided to select an element inside the current.
    #
    # @param [String] subSelector
    #   @optional
    # @return [jQuery] element
    ###
    getElement: (subSelector) ->
      if subSelector
        $("#{@_sel} #{subSelector}")
      else
        $(@_sel)

    ###
    # @return [jQuery] element
    ###
    getParentElement: ->
      $(@getParentSel())

    ###
    # Return widget id as a string
    #
    # @return [String] id
    ###
    getID: ->
      "#{@_id}"

    ###
    # Removes the element, if subSelector is provided, removes the element
    # under the current
    #
    # @param [String] subSelector optional
    # @return [Widget] self
    ###
    removeElement: (subSelector) ->
      @getElement(subSelector).remove()
      @

    ###
    # Replaces the element, if subSelector is provided, places the element
    # under the current
    #
    # @param [String] subSelector optional
    # @return [Widget] self
    ###
    replaceElement: (content, subSelector) ->
      @getElement(subSelector).replaceWith(content)
      @

    ## rendering

    ###
    # Generate an HTML string that is ready for injection into our stub
    #
    # @return [Widget] self
    ###
    render: ->
      if @_static
        Renderable::render.call(@) + @_staticHTML
      else
        Renderable::render.call(@)

    ###
    # The stub is our top level element; Any content provided on the options
    # object is injected (calling @renderStub @render() effectively generates
    # an HTML string fully identifying us, which should be injected into our
    # parent)
    #
    # @return [String] stub
    ###
    renderStub: (options) ->
      options ||= {}
      options.content ||= ""

      stubHTML = """
      <div id=\"#{@_id}\" class=\"#{@_classes.join(" ")}\">
        #{options.content}
      </div>
      """

      Renderable::renderStub.call(@) + stubHTML

    ###
    # Generate the HTML defining our top level element, including our content.
    #
    # @return [String] html
    ###
    renderWithStub: ->
      @renderStub content: @render()

    ###
    # Rebuilds and injects our HTML content
    #
    # @return [Widget] self
    ###
    refresh: ->
      @getElement().html @render()
      @

    ###
    # Performs a full *hard* refresh; fully removes and reconstructs our element
    #
    # @return [Widget] self
    ###
    refreshStub: ->
      @removeElement()
      @getParentElement().append @renderStub()
      @

    ###
    # Called by the UIManager after a refresh has occured
    #
    # @return [Widget] self
    ###
    postRefresh: ->
      @

    ## Event handling

    ###
    # Called by ui.pushEvent
    #
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      #

    ## Dumpable

    ###
    # @return [Object] data
    ###
    dump: ->
      _.extend Dumpable::dump.call(@), widgetVersion: "1.0.0"

    ###
    # Load from Widget dump
    #
    # @param [Object] data
    ###
    load: (data) ->
      Dumpable::load.call @, data

      # data.widgetVersion

      @
