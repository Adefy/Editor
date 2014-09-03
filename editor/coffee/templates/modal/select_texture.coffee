define ->

  ###
  # @property [Hex] hex
  ###
  Handlebars.compile """
    <div id="modal-set-texture">

      <div class="header">
        <div class="title">Select Texture</div>
        <div class="close"><button class="modal-dismiss"><i class="fa fa-times"></i></button></div>
      </div>

      <ul>
        {{#each textures}}
        <li>
          <img data-uid="{{uid}}" src="{{url}}"></img>
        </li>
        {{/each}}
      </ul>
    </div>
  """
