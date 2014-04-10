define (require) ->

  AUtilLog = require "util/log"
  SidebarItem = require "widgets/sidebar/sidebar_item"
  TemplateSidebarPanel = require "templates/sidebar_panel"

  class SidebarPanel extends SidebarItem

    ###
    # Create a new SidebarPanel
    # @param [Sidebar] parent
    ###
    constructor: (parent, opts) ->
      @_tabs = []
      @_footerActive = false

      super parent, [ "panel" ]

      @_parent.addItem @

      @registerEvents()

    ###
    # returns the scrollbar selector
    # @return [String]
    # @private
    ###
    _scrollbarSelector: ->
      "#{@_sel}.panel .content"

    ###
    # Returns the scrollbar element
    # @return [jQuery]
    # @private
    ###
    _scrollbarElement: ->
      $(@_scrollbarSelector())

    ###
    # @return [Void]
    # @private
    ###
    _setupScrollbar: ->
      @_scrollbarElement().perfectScrollbar suppressScrollX: true

    ###
    # @return [Void]
    # @private
    ###
    _updateScrollbar: ->
      @_scrollbarElement().perfectScrollbar "update"

    ###
    # onresize callback function
    # @return [Void]
    ###
    onResize: ->
      @_updateScrollbar()

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
      tab.selected = false for tab in @_tabs
      @_tabs[index].selected = true

    ###
    # @param [String] name The name of this tab
    # @param [Function] cb The content callback, called immediately
    #   @optional
    ###
    newTab: (name, cb) ->
      tab = name: name, selected: ""
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
      usesFooter = false

      tab = _.find @_tabs, (t) -> t.selected

      if tab
        if tab.content instanceof String
          content = tab.content

        else # probably is a Object
          tcontent = tab.content
          content = tcontent.render()
          contentKlass = tcontent.cssAppendParentClass()
          contentId = tcontent.appendParentId()
          usesFooter = tcontent.needPanelFooter()

      @_footerActive = usesFooter

      TemplateSidebarPanel
        id: @_id
        sidebarId: @_parent.getId()
        tabs: @_tabs
        content: content
        contentId: contentId
        contentKlass: contentKlass
        usesFooter: @_footerActive

    ###
    # @return [Void]
    ###
    registerEvents: ->
      $(document).on "click", "#{@_sel} .tab", (e) =>
        @selectTab Number $(e.target).closest(".tab").attr "data-index"
        @_parent.render()

    ###
    # @return [Void]
    ###
    postRender: ->
      @_setupScrollbar()
      for tab in @_tabs
        if content = tab.content
          if content.postRender
            content.postRender()
          if @_footerActive && content.renderFooter
            @getElement(".footer").html content.renderFooter()

    ###
    # When a child element changes size, position, this function is called
    # @param [Widget] child
    ###
    onChildUpdate: (child) ->
      @_updateScrollbar()

    ###
    # @param [String] type
    # @param [Object] params
    ###
    respondToEvent: (type, params) ->
      for tab in @_tabs
        if tab.content
          tab.content.respondToEvent type, params if tab.content.respondToEvent

    ###
    # Panels don't refresh themselves
    ###
    refresh: ->
      @_parent.refresh() if @_parent.refresh