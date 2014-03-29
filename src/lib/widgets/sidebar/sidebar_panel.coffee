define (require) ->

  AUtilLog = require "util/log"
  SidebarItem = require "widgets/sidebar/sidebar_item"
  SidebarPanelTemplate = require "templates/sidebar_panel"

  class SidebarPanel extends SidebarItem

    ###
    # Create a new SidebarPanel
    # @param [Sidebar] parent
    ###
    constructor: (parent, opts) ->
      @_tabs = []

      super parent, [ "panel" ]

      @_parent.addItem @

    ###
    # returns the scrollbar selector
    # @return [String]
    ###
    _scrollbarSelector: ->
      "#{@_sel}.panel .content"

    ###
    # Returns the scrollbar element
    # @return [jQuery]
    ###
    _scrollbarElement: ->
      $(@_scrollbarSelector())

    ###
    # onresize callback function
    ###
    onResize: ->
      @_scrollbarElement().perfectScrollbar "update"

    ###
    # Clear all tabs from this panel
    ###
    clearTabs: ->
      @_tabs.length = 0

    ###
    # All the tabs have their index reset
    ###
    reindexTabs: ->
      for i in [0...@_tabs.length]
        @_tabs[i].index = i

    ###
    # Add a new tab to the panel, this will also automagically assign
    # an index to the tab
    ###
    addTab: (tab) ->
      tab.index = @_tabs.length
      @_tabs.push(tab)

    ###
    # Selects a tab based on index
    ###
    selectTab: (index) ->
      for tab in @_tabs
        tab.selected = ""

      if tab = @_tabs[index]
        tab.selected = "selected"

    ###
    # @param [String] name The name of this tab
    # @param [Function] cb The content callback, called immediately
    #   @optional
    ###
    newTab: (name, cb) ->
      tab = name: name, selected:""
      tab.content = cb() if cb
      @addTab tab
      tab

    ###
    # @return [HTML]
    ###
    render: ->
      content = ""
      contentKlass = ""
      contentId = ""

      tab = _.find @_tabs, (t) -> t.selected == "selected"
      if tab
        if tab.content instanceof String
          content =  tab.content

        else # probably is a Object
          content = tab.content.render()
          contentKlass = tab.content.cssAppendParentClass()
          contentId = tab.content.appendParentId()

      SidebarPanelTemplate
        id: @_id
        sidebarId: @_parent.getId()
        tabs: @_tabs
        content: content
        contentId: contentId
        contentKlass: contentKlass

    ###
    # @return [Void]
    ###
    setupScrollbar: ->
      @_scrollbarElement().perfectScrollbar suppressScrollX: true

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      for tab in @_tabs
        if tab.content
          tab.content.respondToEvent type, params if tab.content.respondToEvent
