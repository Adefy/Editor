define ->

  ###
  # Content that appears on the right of the Timeline
  # @property [String] id
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
    {{#if isExpanded}}
    <div id="{{ id }}" class="actor expanded">
    {{else}}
    <div id="{{ id }}" class="actor">
    {{/if}}

      {{#each properties}}
       {{#if isProperty}}
        <div id="{{ id }}" class="row property">
          <div style="left: {{ left }}px; width: {{ width }}px" class="bar"></div>
        </div>
       {{else}}
        <div id="{{ id }}" class="row">

         {{#each keyframes}}
          <div id="{{ id }}" style="left: {{ left }}px" class="keyframe"></div>
         {{/each}}

        </div>
       {{/if}}
      {{/each}}

    </div>
  """
