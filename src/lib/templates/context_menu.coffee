define ->

  ###
  # @property [String] name  name of the context menu
  # @property [Array<Object>] entries
  #   @property [String] name
  #   @property [String] dataId
  ###
  Handlebars.compile """
    {{#if name}}
      <label>{{name}}</label>
    {{/if}}
    <ul>
      {{#each entries}}
      <li data-id="{{dataId}}">
        {{#if icon}}<i class="fa fa-fw {{icon}}"></i>{{/if}}
        {{name}}
      </li>
      {{/each}}
    </ul>
  """
