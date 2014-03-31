define ->

  ###
  # Content that appears on the left of the Timeline
  # @property [String] id
  # @property [Number] index
  # @property [Id] actorId
  # @property [String] title
  # @property [Array<Object>] properties
  #   @property [String] id
  #   @property [String] title
  #   @property [String] value
  ###
  Handlebars.compile """
    <div data-actorid="{{ actorid }}" data-index="{{ index }}" id="{{ id }}" class="actor">

      <div class="actor-info row">
        <div class="visibility"><i class="fa fa-fw fa-eye"></i></div>
        <div class="expand"><i class="fa fa-fw fa-caret-right"></i></div>
        <div class="title">{{ title }}</div>
      </div>

     {{#each properties}}
      <div id="{{ id }}" class="actor-property row property">

        <div class="live">
          <div class="button"><i class="fa fa-fw fa-clock-o"></i></div>
        </div>

        <div class="graph">
          <div class="button"><i class="fa fa-fw fa-cog"></i></div>
        </div>

        <div class="title">{{ title }}</div>
        <div class="value">{{ value }}</div>
      </div>
     {{/each}}
    </div>
  """
