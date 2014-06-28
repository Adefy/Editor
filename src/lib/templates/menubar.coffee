define ->

  ###
  # @property [Array<Object>] items
  #   @property [String] label
  #   @property [Array<Object>] children
  #     @property [String] label
  #     @property [Method] click
  #     @property [Boolean] sectionEnd optional
  ###
  Handlebars.compile """
  <div class="mb-decorater"></div>

  <ul class="mb-primary">
  {{#each items}}
    <a data-id="{{id}}" href="javascript:void(0)">
      <li>{{label}}</li>
    </a>
  {{/each}}
  </ul>

  {{#each items}}
  {{#if children}}
  <ul class="mb-secondary" data-owner="{{id}}">
    {{#each children}}
    <a data-id="{{id}}" href="javascript:void(0)"
    {{#if sectionEnd}} class="mb-section-end" {{/if}}
    >
      <li>{{label}}</li>
    </a>
    {{/each}}
  </ul>
  {{/if}}
  {{/each}}
  """
