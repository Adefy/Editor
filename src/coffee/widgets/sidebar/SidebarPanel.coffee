# @depend SidebarItem.coffee
class AWidgetSidebarPanel extends AWidgetSidebarItem

  constructor: (parent, opts) ->
    @_tabs = []

    super parent, [ "as-panel" ]

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
    tab = {}
    tab.name = name
    tab.selected = ""
    tab.content = cb() if cb
    @addTab(tab)
    tab

  scrollbarSelector: ->
    "#{@_sel} .as-panel .content"

  onResize: ->
    $(@scrollbarSelector()).perfectScrollbar "update"

  render: ->
    contents = ""
    contentsKlass = ""
    for tab in @_tabs
      if tab.selected == "selected"
        if tab.content instanceof String
          contents =  tab.content
        else # probably is a Object
          contents = tab.content.render()
          contentsKlass = tab.content.cssKlass()

        break

    ATemplate.sidebarPanel(id: @_id, tabs: @_tabs, contents: contents, contentsKlass: contentsKlass)

  postRender: ->
    console.log @scrollbarSelector()
    console.log $(@scrollbarSelector())
    $(@scrollbarSelector()).perfectScrollbar suppressScrollX: true