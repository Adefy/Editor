define ->

  ###
  # @property [String] id
  ###
  Handlebars.compile """
    <div class="thumb">
      <div class="img">
        <img draggable="true" src="{{ src }}"></img>
      </div>
      <div class="name">{{name}}</div>
    </div>
  """
