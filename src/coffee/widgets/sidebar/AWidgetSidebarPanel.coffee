# @depend AWidgetSidebarItem.coffee
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

  newTab: (name, cb) ->
    tab = {}
    tab.name = name
    tab.isSelected = false
    tab.content = cb(tab) if cb
    @addTab(tab)
    tab

  scrollbarSelector: ->
    "#{@_sel} .as-panel .content"

  onResize: ->
    $(@scrollbarSelector()).perfectScrollbar "update"

  render: ->
    @genElement "div", id: @_id, =>
      @genElement "div", class: "as-panel", =>
        _html = @genElement "div", class: "tabs", =>
          __html = ""

          for tab in @_tabs
            selected = ""
            selected = "selected" if tab.isSelected
            __html += @genElement("div", class: "tab #{selected}", => tab.name)

          __html

        _stab = null
        for tab in @_tabs
          if tab.content && tab.isSelected
            _stab = tab
            break

        klass = "content"
        if _stab && _stab.addedParentClass
          klass += " #{_stab.addedParentClass}"

        _html + @genElement "div", class: klass, =>
          if _stab
            if _stab.content instanceof String
              _stab.content
            else
              _stab.content.render()

  postRender: ->
    console.log @scrollbarSelector()
    console.log $(@scrollbarSelector())
    $(@scrollbarSelector()).perfectScrollbar suppressScrollX: true