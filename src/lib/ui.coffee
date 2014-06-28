define (require) ->

  AUtilLog = require "util/log"
  AUtilEventLog = require "util/event_log"
  param = require "util/param"
  PropertyBar = require "widgets/property_bar"
  MenuBar = require "widgets/menubar"
  StatusBar = require "widgets/statusbar/statusbar"
  Timeline = require "widgets/timeline/timeline"
  Workspace = require "widgets/workspace/workspace"
  Sidebar = require "widgets/sidebar"
  ModalManager = require "modal_manager"

  class UIManager

    constructor: (@editor) ->

      if UIManager.instance
        throw new Error "UIManager already instantiated!"
      else
        UIManager.instance = @

      @widgets = []

      @widgets.push @initializeMenu()
      # @widgets.push @initializePropertyBar()
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
    # swiped from:
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
      $("section.main").height $(window).height() - \
                               $("header").height() - \
                               $("footer").height()
      @

    onResize: =>

      @updateSectionMain()

      for widget in @widgets
        widget.onResize() if widget.onResize

    renderAll: -> widget.render() for widget in @widgets

    initializePropertyBar: -> @propertyBar = new PropertyBar @
    initializeStatusbar: -> @statusbar = new StatusBar @, parent: "footer"
    initializeTimeline: -> @timeline = new Timeline @

    initializeWorkspace: ->
      throw new Error "Timeline required for workspace" unless @timeline
      @workspace = new Workspace @

    initializeSidebar: ->
      @sidebar = new Sidebar @

    initializeMenu: ->

      @menu = new MenuBar @, [
        label: "File"
        children: [
          label: "New Creative..."
          click: => @editor.fileNewAd()
        ,
          label: "Open..."
          click: => @editor.fileOpen()
          sectionEnd: true
        ,
          label: "Save"
          click: => @editor.fileSave()
        ,
          label: "Save As..."
          click: => @editor.fileSaveAs()
        ,
          label: "Export..."
          click: => @editor.fileExport()
          sectionEnd: true
        ,
          label: "Preferences"
          click: => @modals.showPrefSettings()
          sectionEnd: true
        ]
      ,
        label: "Edit"
        children: [
          label: "Undo"
        ,
          label: "Redo"
        ,
          label: "History..."
          sectionEnd: true
          click: => @modals.showEditHistory()
        ,
          label: "Copy"
        ,
          label: "Cut"
        ,
          label: "Paste"
        ]
      ,
        label: "View"
        children: [
          label: "Toggle Sidebar"
          click: => @sidebar.toggle()
        ,
          label: "Toggle Timeline"
          click: => @timeline.toggle()
          sectionEnd: true
        ,
          label: "Fullscreen"
          click: => @toggleFullScreen()
          sectionEnd: true
        ,
          label: "Refresh"
          click: =>
            @refresh()
            @onResize()
          sectionEnd: true
        ]
      ,
        label: "Canvas"
        children: [
          label: "Set Screen Properties ..."
          click: => @modals.showSetScreenProperties()
        ,
          label: "Set Background Color ..."
          click: => @modals.showSetBackgroundColor()
        ]
      ,
        label: "Help"
        children: [
          label: "About Editor"
          click: => @modals.showHelpAbout()
        ,
          label: "Changelog"
          click: => @modals.showHelpChangeLog()
          sectionEnd: true
        ]
      ]

    ###
    # @return [self]
    ###
    refreshStub: ->
      AUtilLog.info "UI#refreshStub"
      for widget in @widgets
        widget.refreshStub() if widget.refreshStub

      @

    ###
    # @return [self]
    ###
    refresh: ->
      AUtilLog.info "UI#refresh"
      for widget in @widgets
        widget.refresh() if widget.refresh

      @

    ###
    # @return [self]
    ###
    postInit: ->
      AUtilLog.info "UI#postInit"
      for widget in @widgets
        widget.postInit() if widget.postInit

      @

    ###
    # @return [self]
    ###
    postRefresh: ->
      AUtilLog.info "UI#postRefresh"
      for widget in @widgets
        widget.postRefresh() if widget.postRefresh

      @

    ###
    # @return [self]
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
    # @param [String] type
    # @param [Object] params
    ###
    pushEvent: (type, params) ->

      unless @_ignoreEventList == null || @_ignoreEventList == undefined
        if _.include @_ignoreEventList, type
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
      if @_eventStats[type] == null || @_eventStats[type] == undefined
        @_eventStats[type] = 0
      @_eventStats[type]++

    ###
    # Allows incoming event of (type)
    # @param [String] type
    ###
    allowEvent: (type) ->

      if @_ignoreEventList == null || @_ignoreEventList == undefined
        return

      index = @_ignoreEventList.indexOf(type)
      @_ignoreEventList.splice index, 1

    ###
    # Blocks incoming event of (type)
    # @param [String] type
    ###
    ignoreEvent: (type) ->

      if @_ignoreEventList == null || @_ignoreEventList == undefined
        @_ignoreEventList = []

      @_ignoreEventList.push type

