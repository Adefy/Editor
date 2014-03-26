define ->

  ###
  # @property [Object] file
  #   @property [String] name
  ###
  Handlebars.compile """
    <dl>
      <dt><i class="fa fa-fw"></i></dt>
      <dd><i class="fa fa-fw fa-file"></i>{{file.name}}</dd>
    </dl>
  """
