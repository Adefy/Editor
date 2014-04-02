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

    ###
    # Backward playback button clicked (prev keyframe)
    # @friend [Timeline]
    # @private
    ###
    onClickBackward: ->

    ###
    # @friend [Timeline]
    # @private
    ###
    onClickFastBackward: ->
      _currentPosition = @timeline.getCursorTime()
      _newPosition = null
      _min = 99999
      index = Workspace.getSelectedActor()

      # only enter checks if an actor is actually selected
      if index != null and index != undefined
        for actor, i in @timeline._actors
          if actor.getId() == index then index = i

        _animations = @timeline._actors[index].getAnimations()
        for anim of _animations
          if anim > _currentPosition
            if anim - _currentPosition < _min and anim - _currentPosition > 1
              _newPosition = anim
              _min = Math.round(anim - _currentPosition)

        # if no animations after current position, go to the end of the timeline
        if _newPosition != null
          if @timeline._playbackID != null and @timeline._playbackID != undefined
            @_pausePlayback()
          @timeline.setCursorTime _newPosition
        else
          # If we move cursor to duration, it is not on the screen anymore
          # maybe an issue with the width, maybe just because of how my
          # screens are set up. Something to keep an eye on.
          @timeline.setCursorTime @timeline._duration
          @_pausePlayback()

    ###
    # @friend [Timeline]
    # @private
    ###
    onClickFastForward: ->
      _currentPosition = @timeline.getCursorTime()
      _newPosition = null
      _min = 99999
      index = Workspace.getSelectedActor()

      # only enter checks if an actor is actually selected
      if index != null and index != undefined
        for actor, i in @_actors
          if actor.getId() == index then index = i

        _animations = @timeline._actors[index].getAnimations()
        for anim of _animations
          if anim < _currentPosition
            if _currentPosition - anim < _min and _currentPosition - anim > 1
              _newPosition = anim
              _min = Math.round(_currentPosition - anim)

        # if no animtaions before this one we go to the beginning of the timeline
        if _newPosition != null
          if @timeline._playbackID != null and @timeline._playbackID != undefined
            @_pausePlayback()
          @timeline.setCursorTime _newPosition
        else
          @timeline.setCursorTime 0
          @_endPlayback()