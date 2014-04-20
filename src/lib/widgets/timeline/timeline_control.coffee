define (require) ->

  AUtilLog = require "util/log"
  param = require "util/param"
  Workspace = require "widgets/workspace/workspace"

  class TimelineControl

    ###
    # @param [Timeline] _timeline
    ###
    constructor: (_timeline) ->
      @timeline = _timeline

    ###
    # @private
    ###
    _endPlayback: ->
      @timeline.clearPlaybackID()
      @timeline.setCursorTime 0

    ###
    # @private
    ###
    _pausePlayback: ->
      @timeline.clearPlaybackID()

    ###
    # Playback toggle button clicked (play/pause)
    # @private
    ###
    onClickPlay: ->

      # If currently playing, remove the interval
      if @timeline._playbackID != undefined and @timeline._playbackID != null
        @_pausePlayback()
        return

      frameRate = 1000 / @timeline.getPreviewFPS()

      # Play the ad at 30 frames per second
      @timeline._playbackStart = @timeline.getCursorTime()
      @timeline._playbackID = setInterval =>
        nextTime = @timeline.getCursorTime() + frameRate
        if nextTime > @timeline._duration then nextTime = @timeline._duration

        @timeline.setCursorTime nextTime

        if nextTime >= @timeline._duration then @_endPlayback()

      , frameRate

      @timeline.controlState.play = true
      @timeline.updateControls()

    ###
    # Forward playback button clicked (next keyframe)
    # @friend [Timeline]
    # @private
    ###
    onClickForward: ->
      cursorTime = Number(@timeline.getCursorTime()|0)+1
      actorID = Workspace.getSelectedActorID()

      # if an actor is selected, jump to their nearest keyframe
      if actorID != null and actorID != undefined
        actor = _.find @timeline.getActors(), (a) -> a.getID() == actorID
        return unless actor

        time = actor.getNearestAnimationTime(cursorTime, right: true)
        @timeline.setCursorTime time if time

      # else, jump to the nearest keyframe from any actor
      else
        pairs = _.map @timeline.getActors(), (actor) ->
          [actor, actor.getNearestAnimationTime(cursorTime, right: true)]

        if minimum = _.min(pairs, (pair) -> (pair[1] || 0) - cursorTime)
          console.log cursorTime
          console.log minimum
          if time = minimum[1]
            @timeline.setCursorTime time

    ###
    # Backward playback button clicked (prev keyframe)
    # @friend [Timeline]
    # @private
    ###
    onClickBackward: ->
      cursorTime = Number(@timeline.getCursorTime()|0)-1
      actorID = Workspace.getSelectedActorID()

      # if an actor is selected, jump to their nearest keyframe
      if actorID != null and actorID != undefined
        actor = _.find @timeline.getActors(), (a) -> a.getID() == actorID
        return unless actor

        time = actor.getNearestAnimationTime(cursorTime, left: true)
        @timeline.setCursorTime time if time

      # else, jump to the nearest keyframe from any actor
      else
        pairs = _.map @timeline.getActors(), (actor) ->
          [actor, actor.getNearestAnimationTime(cursorTime, left: true)]

        if minimum = _.min(pairs, (pair) -> cursorTime - (pair[1] || 0))
          console.log cursorTime
          console.log minimum
          if time = minimum[1]
            @timeline.setCursorTime time

    ###
    # @friend [Timeline]
    # @private
    ###
    onClickFastBackward: ->
      @timeline.setCursorTime 0

    ###
    # @friend [Timeline]
    # @private
    ###
    onClickFastForward: ->
      @timeline.setCursorTime @timeline.getDuration()
