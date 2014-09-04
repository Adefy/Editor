define ->

  ###
  # Control bar and base
  # @property [String] id
  # @property [String] timlineId
  # @property [Time] currentTime
  # @property [HTML] contents Actors will go here
  # @property [HTML] timeContents Actor time & keyframes will go here
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
      <div timelineid="{{timelineId}}" class="control right">
        <i class="fa fa-fw fa-toggle-down"></i>
      </div>
    </div>

    <div class="content">

      <div class="list">
        <section>
          <label class="timeline-label static-actors">Static Actors</label>
          <div class="timeline-actor-list static-actors">
            {{#each staticActorList}} {{{ this }}} {{/each}}
          </div>
        </section>

        <section>
          <label class="timeline-label animated-actors">Animated Actors</label>
          <div class="timeline-actor-list animated-actors">
            {{#each animatedActorList}} {{{ this }}} {{/each}}
          </div>
        </section>
      </div>

      <div class="time">
        <div id="timeline-cursor" class="cursor">
          <div class="cursor-top"></div>
        </div>
        <div class="time-delimit"></div>

        <section class="time-static-actors">
          {{#each staticActorTimebars}} {{{ this }}} {{/each}}
        </section>

        <section class="time-animated-actors">
          {{#each animatedActorTimebars}} {{{ this }}} {{/each}}
        </section>
      </div>

    </div>
  """
