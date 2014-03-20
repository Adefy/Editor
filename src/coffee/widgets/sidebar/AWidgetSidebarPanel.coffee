# @depend AWidgetSidebarItem.coffee
class AWidgetSidebarPanel extends AWidgetSidebarItem

  constructor: (parent, opts) ->
    @_tabs = []

    super parent, [ "apanel" ]

    @_parent.addItem @
    @_parent.render()

  addTab: (d) ->
    @_tabs.push(d)

  render: ->
    @genElement "div", class: "as-panel", =>
      _html = @genElement "div", class: "tabs", =>
        @genElement("div", class: "tab selected", => "Assests") +
        @genElement("div", class: "tab", => "Tab2") +
        @genElement("div", class: "tab", => "Tab3")
      _html += @genElement "div", class: "content ps-container"

