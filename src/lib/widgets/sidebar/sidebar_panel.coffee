define (require) ->

  SidebarItem = require "widgets/sidebar/sidebar_item"
  SidebarPanelTemplate = require "templates/sidebar_panel"

  class SidebarPanel extends SidebarItem

    constructor: (parent, opts) ->
      @_tabs = []

      super parent, [ "panel" ]

      @_parent.addItem @

    clearTabs: ->
      @_tabs.length = 0

    addTab: (tab) ->
      #tab.index = @_tabs.length
      @_tabs.push(tab)

    selectTab: (index) ->
      for tab in @_tabs
        tab.selected = ""

      if tab = @_tabs[index]
        tab.selected = "selected"

    newTab: (name, cb) ->
      tab = name: name, selected:""
      tab.content = cb() if cb
      @addTab tab
      tab

    scrollbarSelector: ->
      "#{@_sel}.panel .content"

    onResize: ->
      $(@scrollbarSelector()).perfectScrollbar "update"

    render: ->
      content = ""
      contentKlass = ""
      for tab in @_tabs
        if tab.selected == "selected"
          if tab.content instanceof String
            content =  tab.content
          else # probably is a Object
            content = tab.content.render()
            contentKlass = tab.content.cssAppendParentClass()

          break

      SidebarPanelTemplate
        id: @_id,
        tabs: @_tabs,
        content: content,
        contentKlass: contentKlass

    postRender: ->
      $(@scrollbarSelector()).perfectScrollbar suppressScrollX: true
