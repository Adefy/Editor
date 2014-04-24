define (require) ->

  config = require "config"
  param = require "util/param"

  AUtilLog = require "util/log"

  EditorObject = require "editor_object"

  Renderable = require "mixin/renderable"
  Dumpable = require "mixin/dumpable"

  # Widgets are the building blocks of the editor's interface
  class Widget extends EditorObject

    @include Renderable
    @include Dumpable

    ###
    # Optionally appends a new div to the body to be used as the container for
    # the widget. The parent is either a string selector, or an object offering
    # a getSel() method.
    #
    # @param [String] id container id
    # @param [Object] parent container parent, defaults to "body"
    # @param [Array<String>] classes an array containing classes to be applied
    # @param [Boolean] prepend if true, we are prepended to the parent
    ###
    constructor: (@ui, options) ->
      options   = param.optional options, {}

      @_id      = param.required options.id
      @_parent  = param.optional options.parent, ".editor"
      @_classes = param.optional options.classes, []

      # container selector, defaults to no container
      @_sel = null
      if "#{@_id}".length > 0
        @_sel = "##{@_id}"

      # Bind a pointer to ourselves on the body, under a key matching our @_sel
      $("body").data @_sel, @

    ###
    # @return [self]
    ###
    postInit: ->
      #
      @

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
        return @_parent
      else if @_parent.getSel != undefined and @_parent.getSel != null
        return @_parent.getSel()
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
    getID: -> "#{@_id}"

    ###
    # Removes the element, if subSelector is provided, removes the element
    # under the current
    # @param [String] subSelector
    #   @optional
    # @return [self]
    ###
    removeElement: (subSelector) ->
      @getElement(subSelector).remove()
      @

    ###
    # Replaces the element, if subSelector is provided, places the element
    # under the current
    # @param [String] subSelector
    #   @optional
    # @return [self]
    ###
    replaceElement: (content, subSelector) ->
      @getElement(subSelector).replaceWith(content)
      @

    ## rendering

    ###
    # @return [self]
    ###
    render: ->
      Renderable::render.call(@)

    ###
    # @return [String]
    ###
    renderStub: (options) ->
      options = param.optional options, {}
      Renderable::renderStub.call(@) +
      if options.content
        @genElement "div", id: @_id, class: @_classes.join(" "), ->
          options.content
      else
        @genElement "div", id: @_id, class: @_classes.join(" ")

    ###
    # @return [String]
    ###
    renderWithStub: ->
      @renderStub content: @render()

    ###
    # @return [self]
    ###
    refresh: ->
      @getElement().html @render()
      @

    ###
    # @return [self]
    ###
    refreshStub: ->
      @removeElement()
      @getParentElement().append @renderStub()
      @

    ###
    # @return [self]
    ###
    postRefresh: ->
      @

    ## Event handling

    ###
    # Called by ui.pushEvent
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
      _.extend Dumpable::dump.call(@),
        widgetVersion: "1.0.0"

    ###
    # Load from Widget dump
    # @param [Object] data
    ###
    load: (data) ->
      Dumpable::load.call @, data

      # data.widgetVersion

      @
