define ->

  ###
  # @property [Array<Object>] entries
  #   @property [String] name
  #   @property [String] dataId
  ###
  Handlebars.compile """
    {{#if name}}
      <dl class="label">{{name}}</dl>
    {{/if}}
    <ul>
      {{#each entries}}
        <li data-id="{{dataId}}">{{name}}</li>
      {{/each}}
    </ul>
  """
