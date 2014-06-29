define ->

  ###
  # @property [String] name menu name
  # @property [Array<Object>] items
  #   @property [String] name
  #   @property [String] id
  ###
  Handlebars.compile """
    <ul class="floating-menu">

      {{#if name}}
      <a class="label" href="javascript:void(0)">
        <li>{{name}}</li>
      </a>
      {{/if}}

      {{#each items}}
      <a data-id="{{id}}" href="javascript:void(0)">
        <li>{{name}}</li>
      </a>
      {{/each}}
    </ul>
  """
