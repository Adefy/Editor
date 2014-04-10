define ->

  ###
  # @property [Object] file
  #   @property [String] name
  ###
  Handlebars.compile """
    <dl id="{{file.id}}" class="asset file">
      <dt><i class="fa fa-fw"></i></dt>
      <dd><i class="fa fa-fw fa-file"></i>
        <label class="name">{{file.name}}</label>
      </dd>
    </dl>
  """
