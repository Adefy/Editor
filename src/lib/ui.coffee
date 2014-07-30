define (require) ->

  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"
  config = require "config"

  MenuBar = require "widgets/menubar"
  StatusBar = require "widgets/statusbar"
  Timeline = require "widgets/timeline/timeline"
  Workspace = require "widgets/workspace"
  Sidebar = require "widgets/sidebar"
  ModalManager = require "modal_manager"
  TextureLibrary = require "widgets/floating/texture_library"

  ###
  # Singleton god class, responsible for initializing and keeping references
  # of all top-level UI elements.
  ###
  class UIManager

    constructor: (@editor) ->
      if UIManager.instance
        throw new Error "UIManager already instantiated!"
      else
        UIManager.instance = @

      @widgets = []

      @widgets.push @initializeMenu()
      @widgets.push @initializeTimeline()
      @widgets.push @initializeWorkspace()
      # @widgets.push @initializeStatusbar()

      # Temporarily disable sidebar untill the workspace is updated
      @widgets.push @initializeSidebar()

      @modals = new ModalManager @

      @refreshHard()

      @onResize()
      window.onresize = @onResize

    ###
    # Swiped from:
    # http://xparkmedia.com/blog/enter-fullscreen-mode-javascript/
    ###
    toggleFullScreen: ->

      if (document.fullScreenElement && document.fullScreenElement != null) || \
       (!document.mozFullScreen && !document.webkitIsFullScreen)
        if document.documentElement.requestFullScreen
          document.documentElement.requestFullScreen()
        else if document.documentElement.mozRequestFullScreen
          document.documentElement.mozRequestFullScreen()
        else if document.documentElement.webkitRequestFullScreen
          document.documentElement.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT)
      else
        if document.cancelFullScreen
          document.cancelFullScreen()
        else if document.mozCancelFullScreen
          document.mozCancelFullScreen()
        else if document.webkitCancelFullScreen
          document.webkitCancelFullScreen()

    updateSectionMain: =>
      height = $(window).height() - $("header").height() - $("footer").height()
      $("section.main").height height
      @

    onResize: =>
      @updateSectionMain()

      for widget in @widgets
        widget.onResize() if widget.onResize

    renderAll: -> widget.render() for widget in @widgets

    initializeStatusbar: -> @statusbar = new StatusBar @, parent: "footer"
    initializeTimeline: -> @timeline = new Timeline @

    initializeWorkspace: ->
      throw new Error "Timeline required for workspace" unless @timeline
      @workspace = new Workspace @

    initializeSidebar: ->
      @sidebar = new Sidebar @

    initializeMenu: ->

      @menu = new MenuBar @, [
        label: config.strings.file
        children: [
          label: "#{config.strings.new_creative}..."
          click: => @editor.fileNewAd()
        ,
          label: "#{config.strings.open}..."
          click: => @editor.fileOpen()
          sectionEnd: true
        ,
          label: config.strings.save
          click: => @editor.fileSave()
        ,
          label: "#{config.strings.make_a_copy}..."
          click: => @editor.fileSaveAs()
          sectionEnd: true
        ,
          label: "#{config.strings.revision_history}..."
          click: => alert "Unimplemented"
        ,
          label: "#{config.strings.export}..."
          click: =>
        ]
      ,
        label: config.strings.edit
        children: [
          label: config.strings.undo
          click: => alert "Unimplemented"
        ,
          label: config.strings.redo
          click: => alert "Unimplemented"
          sectionEnd: true
        ,
          label: config.strings.copy
          click: => alert "Unimplemented"
        ,
          label: config.strings.cut
          click: => alert "Unimplemented"
        ,
          label: config.strings.paste
          click: => alert "Unimplemented"
        ]
      ,
        label: config.strings.view
        children: [
          label: config.strings.toggle_sidebar
          click: => @sidebar.toggle()
        ,
          label: config.strings.toggle_timeline
          click: => @timeline.toggle()
        ,
          label: config.strings.fullscreen
          click: => @toggleFullScreen()
          sectionEnd: true
        ,
          label: config.strings.preview
          click: => alert "Unimplemented"
        ]
      ,
        label: config.strings.canvas
        children: [
          label: "#{config.strings.screen_properties}..."
          click: => @modals.showSetScreenProperties()
        ,
          label: "#{config.strings.background_color}..."
          click: => @modals.showSetBackgroundColor()
        ]
      ,
        label: config.strings.help
        children: [
          label: config.strings.quick_start
          click: => alert "Unimplemented"
        ,
          label: config.strings.tutorials
          click: => alert "Unimplemented"
        ,
          label: config.strings.documentation
          click: => alert "Unimplemented"
        ]
      ,
        label: config.strings.texture_library
        right: true
        image: "/editor/img/favicon.png"
        click: (e) =>

          if TextureLibrary.isOpen()
            TextureLibrary.close()
          else

            # Pass the center of the button as the origin
            if $(e.target).attr "href"
              origin = $(e.target).position()
              origin.left += $(e.target).width() / 2
              origin.top += $(e.target).height()
            else
              elm = $(e.target).closest "a"
              origin = elm.position()
              origin.left += elm.width() / 2
              origin.top += elm.height()

            @openTextureLibrary "top", origin.left, origin.top
      ,
        label: config.strings.actor_library
        right: true
        icon: config.icon.actor_library
      ]

    ###
    # Show the texture library from the specified origin
    #
    # @param [String] direction "left", "top", "right", "bottom"
    # @param [Number] x
    # @param [Number] y
    ###
    openTextureLibrary: (direction, x, y) ->
      new TextureLibrary @,
        direction: direction
        x: x
        y: y

    ###
    # Refresh all wigdet stubs
    #
    # @return [UIManager] self
    ###
    refreshStub: ->
      AUtilLog.info "UI#refreshStub"
      for widget in @widgets
        widget.refreshStub() if widget.refreshStub

      @

    ###
    # Refresh all widgets
    #
    # @return [UIManager] self
    ###
    refresh: ->
      AUtilLog.info "UI#refresh"
      for widget in @widgets
        widget.refresh() if widget.refresh

      @

    ###
    # Call postInit() on all widgets supporting it
    #
    # @return [UIManager] self
    ###
    postInit: ->
      AUtilLog.info "UI#postInit"
      for widget in @widgets
        widget.postInit() if widget.postInit

      @

    ###
    # Call postRefresh() on all widgets supporting it
    #
    # @return [UIManager] self
    ###
    postRefresh: ->
      AUtilLog.info "UI#postRefresh"
      for widget in @widgets
        widget.postRefresh() if widget.postRefresh

      @

    ###
    # Perform a full re-render. This destroys and rebuilds all widgets!
    #
    # @return [UIManager] self
    ###
    refreshHard: ->
      @refreshStub() # create widget stubs
      @refresh()     # render the widget content
      @postRefresh() # conduct all post refresh shebang
      @onResize()    # ensure that all widgets have the correct size
      @postInit()    # finish initializing the widgets
      @

    ###
    ## UES - UI Event System
    ###

    ###
    # Adds a new event
    #
    # @param [String] type
    # @param [Object] params
    ###
    pushEvent: (type, params) ->
      if @_ignoreEventList and _.include @_ignoreEventList, type
        return AUtilEventLog.ignore "ui", type

      AUtilEventLog.epush "ui", type

      if type == "timeline.hiding" || type == "timeline.showing"
        @updateSectionMain()

      if type == "timeline.hide" || type == "timeline.show"
        @onResize()

      ## we should probably fine tune this later
      for widget in @widgets
        widget.respondToEvent type, params if widget.respondToEvent

      ##
      # more debugging stuff
      @_eventStats ||= {}
      @_eventStats[type] = 0 if isNaN @_eventStats[type]
      @_eventStats[type]++

    ###
    # Allows incoming event of (type)
    #
    # @param [String] type
    ###
    allowEvent: (type) ->
      return unless !!@_ignoreEventList

      index = @_ignoreEventList.indexOf(type)
      @_ignoreEventList.splice index, 1

    ###
    # Blocks incoming event of (type)
    #
    # @param [String] type
    ###
    ignoreEvent: (type) ->
      @_ignoreEventList = [] unless @_ignoreEventList instanceof Array
      @_ignoreEventList.push type

