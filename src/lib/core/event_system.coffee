define (require) ->

  config = require "config"
  param = require "util/param"

  ID = require "util/id"
  AUtilEventLog = require "util/event_log"

  class EventSystem

    constructor: ->
      @id = ID.objID "EventSystem"
      @name = @id.prefixed

      @init()

    ###
    # Sets the current EventSystem as the current
    # NOTE* this does not affect the internals, only external callers to
    # the EventSystem.current
    #
    # @return [self]
    ###
    setAsCurrent: ->
      EventSystem.current = @
      @

    ###
    # Initializes the system's internals
    # @return [self]
    ###
    init: ->
      @listenerID = 0
      @listeners = {}
      @

    ###
    # Clears a listener group
    # @return [self]
    ###
    clearListeners: (group) ->
      if group
        if ary = @listeners[group]
          ary.length = 0
      else
        @listeners = {}

      @

    ###
    # @param [Object] listener
    # @param [String] groupname  which listen group be registerd to?
    #   @default "*"
    ###
    listen: (listener, groupname) ->
      param.required listener

      listener.listenID = @listenerID++

      unless groupname
        groupname = "*"
      (@listeners[groupname] ||= []).push listener

      @

    ###
    # @param [Object] listener
    ###
    removeListener: (listener, groupname) ->
      param.required listener

      unless groupname
        groupname = "*"

      if group = @listeners[groupname]
        @listeners[groupname] = _.without group, (obj) ->
          obj.listenID == listener.listenID

      @

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

    ###
    # @param [String] groupname  listen group to push the event for
    # @param [String] type  type of event
    # @param [Object] params  event parameters
    #   @optional
    ###
    pushToGroup: (groupname, type, params) ->
      param.required groupname
      param.required type

      if group = @listeners[groupname]
        unless @_ignoreEventList == null || @_ignoreEventList == undefined
          if _.include @_ignoreEventList, type
            return AUtilEventLog.ignore @name, type

        AUtilEventLog.epush @name, groupname, type

        for listener in group
          listener.respondToEvent groupname, type, params

    ###
    # @param [String] type  tyoe of event
    # @param [Object] params  event parameters
    #   @optional
    ###
    push: (groupname, type, params) ->
      param.required type

      unless groupname == "*"
        @pushToGroup "*", type, params # wildcard group

      @pushToGroup groupname, type, params
