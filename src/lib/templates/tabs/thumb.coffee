define ->

  ###
  # @property [String] id
  ###
  Handlebars.compile """
    <div id="{{id}}" class="thumb">
      <div class="img">
        <img draggable="true" src="{{src}}"></img>
      </div>
      <div class="name">{{name}}</div>
    </div>
  """
