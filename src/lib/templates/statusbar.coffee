define ->

  ###
  # @property [String] version The current Adefy Editor version
  ###
  Handlebars.compile """
    <div class="version">Version {{ version }}</div><div id="save-status" class="save done"><i class="fa fa-fw fa-circle"></i></div>
  """
