define ->

  ###
  # @property [String] id
  ###
  Handlebars.compile """
    <div class="toggle-thumbs">
      <i class="left fa fa-fw fa-th-large {{thumbsActive}}"></i>
    </div>
    <div class="toggle-list">
      <i class="left fa fa-fw fa-th-list {{listActive}}"></i>
    </div>
    <div class="upload"><i class="right fa fa-fw fa-upload"></i></div>
  """