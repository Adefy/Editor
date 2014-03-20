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
    content = ""
    contentKlass = ""
    for tab in @_tabs
      if tab.selected == "selected"
        if tab.content instanceof String
          content =  tab.content
        else # probably is a Object
          content = tab.content.render()
          contentKlass = tab.content.cssKlass()

        break

    ATemplate.sidebarPanel id: @_id, tabs: @_tabs, content: content, contentKlass: contentKlass

  postRender: ->
    $(@scrollbarSelector()).perfectScrollbar suppressScrollX: true