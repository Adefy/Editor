define ->

  ###
  # Content that appears on the left of the Timeline
  # @property [String] id
  # @property [Number] index
  # @property [Id] actorid
  # @property [String] title
  # @property [Array<Object>] properties
  #   @property [String] id
  #   @property [String] title
  #   @property [String] value
  ###
  Handlebars.compile """
    <li data-actorid="{{ actorid }}"
         data-index="{{ index }}"
         id="{{ id }}" class="actor">

      <div class="actor-info row">
        <div class="visibility"><i class="fa fa-fw fa-eye"></i></div>
        <div class="expand"><i class="fa fa-fw fa-caret-right"></i></div>
        <div class="title">{{ title }}</div>
      </div>

      <ul class="actor-properties">
        {{#each properties}}

        <li data-id="{{ id }}" class="row">
          <div class="title">{{ title }}</div>
          <div class="value">{{ value }}</div>
        </li>

        {{/each}}
      </ul>
    </li>
  """
