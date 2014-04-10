define ->

  ###
  # @property [Array<Object>] entries
  #   @property [String] name
  #   @property [String] dataId
  ###
  Handlebars.compile """
    {{#each entries}}
      <li data-id="{{dataId}}">{{name}}</li>
    {{/each}}
  """
