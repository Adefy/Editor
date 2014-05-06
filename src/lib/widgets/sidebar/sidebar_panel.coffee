define (require) ->

  AUtilLog = require "util/log"
  SidebarItem = require "widgets/sidebar/sidebar_item"
  TemplateSidebarPanel = require "templates/sidebar_panel"

  class SidebarPanel extends SidebarItem

    ###
    # Create a new SidebarPanel
    # @param [Sidebar] parent
    ###
    constructor: (@ui, options) ->
      param.required options.parent

      @_tabs = []
      @_footerActive = false

      options.classes = param.optional options.classes, []
      options.classes.push "panel"

      super @ui, options

      @_parent.addItem @

      @_registerEvents()

    ###
    # @return [self]
    ###
    postInit: ->
      super()
      for tab in @_tabs
        tab.postInit()

      @

    ###
    # @return [Void]
    ###
    _registerEvents: ->
      $(document).on "click", "#{@_sel} .tab", (e) =>
        @selectTab Number $(e.target).closest(".tab").attr "data-index"
        @_parent.render()

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
        @_tabs[i].tabindex = i

    ###
    # Add a new tab to the panel, this will also automagically assign
    # an index to the tab
    ###
    addTab: (tab) ->
      tab.tabindex = @_tabs.length
      @_tabs.push tab

    ###
    # Selects a tab based on index
    ###
    selectTab: (index) ->
      tab.tabselected = false for tab in @_tabs
      @_tabs[index].tabselected = true

    ###
    # @param [String] name The name of this tab
    # @param [Function] cb The content callback, called immediately
    #   @optional
    ###
    newTab: (name, cb) ->
      tab = cb()
      tab.tabname = name
      tab.tabselected = false
      @addTab tab
      tab

    ###
    # @return [Tab]
    ###
    getSelectedTab: ->
      tab = _.find @_tabs, (t) -> t.tabselected

    ###
    # @return [HTML]
    ###
    render: ->
      content = ""
      contentKlass = ""
      contentId = ""
      usesFooter = false

      if tab = @getSelectedTab()
        content = tab.render()
        contentKlass = tab.cssAppendParentClass()
        contentId = tab.appendParentId()
        usesFooter = tab.needPanelFooter()

      @_footerActive = usesFooter

      super() +
      TemplateSidebarPanel
        id: @_id
        sidebarId: @_parent.getID()
        tabs: @_tabs
        content: content
        contentId: contentId
        contentKlass: contentKlass
        usesFooter: @_footerActive

    ###
    # @return [self]
    ###
    refresh: ->
      super()
      if tab = @getSelectedTab()
        tab.refresh()

      @

    ###
    # @return [self]
    ###
    refreshStub: ->
      super()

    ###
    # @return [self]
    ###
    postRefreshStub: ->
      super()
      if tab = @getSelectedTab()
        tab.postRefreshStub() if tab.postRefreshStub

      @

    ###
    # @return [self]
    ###
    postRefresh: ->
      super()
      @_setupScrollbar()
      if tab = @getSelectedTab()
        tab.postRefresh() if tab.postRefresh
        if @_footerActive && tab.renderFooter
          @getElement(".footer").html tab.renderFooter()

      @

    ###
    # When a child element refreshes
    # @param [Widget] child
    ###
    onChildRefresh: (child) ->
      @_setupScrollbar()

    ###
    # When a child element does some form of content update
    # @param [Widget] child
    ###
    onChildUpdate: (child) ->
      @_updateScrollbar()