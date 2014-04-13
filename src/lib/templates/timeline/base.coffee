define ->

  ###
  # Control bar and base
  # @property [String] id
  # @property [String] timlineId
  # @property [Time] currentTime
  # -property [HTML] contents Actors will go here
  # -property [HTML] timecontents Actor time & keyframes will go here
  ###
  Handlebars.compile """
    <div id="{{ id }}" class="header timeline-control-bar">
      <div id="timeline-cursor-time" class="current_time">{{ currentTime }}</div>
      <a id="timeline-control-fast-backward" class="control">
        <i class="fa fa-fw fa-fast-backward"></i>
      </a>
      <a id="timeline-control-backward" class="control">
        <i class="fa fa-fw fa-backward"></i>
      </a>
      <a id="timeline-control-play" class="control">
        <i class="fa fa-fw fa-play"></i>
      </a>
      <a id="timeline-control-forward" class="control">
        <i class="fa fa-fw fa-forward"></i>
      </a>
      <a id="timeline-control-fast-forward" class="control">
        <i class="fa fa-fw fa-fast-forward"></i>
      </a>
      <div timelineid="{{timelineId}}" class="button toggle">
        <i class="fa fa-fw fa-toggle-down"></i>
      </div>
    </div>
    <div class="content">
      <div class="list">
        {{! <div class="timebar"></div> }}
        {{! contents }}
      </div>
      <div class="time">
        <div id="timeline-cursor" class="cursor"></div>
        {{! <div class="timebar"></div> }}
        <div class="time-actors">
          {{! timeContents }}
        </div>
      </div>
    </div>
  """
