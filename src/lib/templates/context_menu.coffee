define ->

  ###
  # @property [Array<Object>] entries
  #   @property [String] name
  #   @property [String] dataId
  ###
  Handlebars.compile """
    <ul class="floating-menu">

      {{#if name}}
      <a class="label" href="javascript:void(0)">
        <li>{{name}}</li>
      </a>
      {{/if}}

      {{#each entries}}

      <a data-id="{{dataId}}" href="javascript:void(0)">
        <li>{{name}}</li>
      </a>
      {{/each}}
    </ul>
  """
