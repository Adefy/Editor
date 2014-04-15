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
      {{#each properties}}
       {{#if isProperty}}
        <div id="{{ id }}" data-property="{{ id }}" class="row property keyframes">

         {{#each keyframes}}
          <div id="{{ id }}" data-time="{{ time }}" style="left: {{ left }}px" class="keyframe"></div>
         {{/each}}

        </div>
       {{else}}
        <div class="row">
          <div style="left: {{ left }}px; width: {{ width }}px" class="bar"></div>
        </div>
       {{/if}}
      {{/each}}

    </div>
  """
