define ->

  ###
  # Content that appears on the right of the Timeline
  # @property [String] id
  # @property [Number] index
  # @property [Id] actorid
  # @property [Number] dataIndex
  # @property [Boolean] isExpanded
  # @property [Array<Object>] properties
  #   @property [String] id
  #   @property [Boolean] isProperty
  #   @property [Number] left if not isProperty
  #   @property [Number] width if not isProperty
  #   @property [Array<Object>] keyframes if isProperty
  #     @property [String] id
  #     @property [Number] left
  ###
  Handlebars.compile """
    <div data-actorid="{{ actorid }}"
         data-index="{{ index }}"
         id="{{ id }}"
         class="actor">

      <div class="row">
        <div id="{{ id }}"
             style="left: {{ left }}; width: {{ width }}"
             data-start="{{start}}"
             data-end="{{end}}"
             class="bar">
          <div class="bar-birth"></div>
          <div class="bar-death"></div>

          {{#each properties}}
          {{#each keyframes}}
          <div id="{{ id }}"
               style="left: {{ left }}"
               data-index="{{index}}"
               data-property="{{../name}}"
               data-time="{{ time }}"
               class="keyframe">
          </div>
          {{/each}}
          {{/each}}

        </div>
      </div>

    </div>
  """
