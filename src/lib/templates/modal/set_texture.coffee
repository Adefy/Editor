define ->

  ###
  # @property [Hex] hex
  ###
  Handlebars.compile """
    <ul id="modal-set-texture">
      {{#each textures}}
      <li>
        <img src="{{url}}"></img>
      </li>
      {{/each}}
    </ul>
  """
