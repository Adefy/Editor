# @depend AWidgetSidebarItem.coffee
class AWidgetSidebarPanel extends AWidgetSidebarItem

  constructor: (parent, opts) ->
    @_tabs = []

    super parent, [ "apanel" ]

    @_parent.addItem @

  clearTabs: ->
    @_tabs.length = 0

  addTab: (tab) ->
    #tab.index = @_tabs.length
    @_tabs.push(tab)

  newTab: (name, cb) ->
    tab = {}
    tab.name = name
    tab.isSelected = false
    tab.content = cb() if cb
    @addTab(tab)
    tab

  render: ->
    @genElement "div", class: "as-panel", =>
      _html = @genElement "div", class: "tabs", =>
        __html = ""

        for tab in @_tabs
          selected = tab.isSelected ? "selected" : ""
          __html += @genElement("div", class: "tab #{selected}", => tab.name)

        __html

      _html + @genElement "div", class: "content ps-container", =>
        __html = ""

        for tab in @_tabs
          if tab.content
            if tab.content instanceof String
              __html += tab.content
            else if tab.content.render
              __html += tab.content.render()

        __html

