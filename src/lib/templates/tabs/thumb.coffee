define ->

  ###
  # @property [String] id
  ###
  Handlebars.compile """
    <div class="thumb">
      <div class="img"><img src="{{src}}"></img></div>
      <div class="name">{{name}}</div>
    </div>
  """