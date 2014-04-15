define ->

  ###
  # @property [Hex] hex
  ###
  Handlebars.compile """
    {{#each textures}}
    <ul>
      <li>
        <img width="48px" height="48px" src="{{url}}"></img>
      </li>
    </ul>
    {{/each}}
  """
