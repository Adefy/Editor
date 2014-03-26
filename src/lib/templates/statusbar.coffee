define ->

  ###
  # @property [String] version The current Adefy Editor version
  ###
  Handlebars.compile """
    Version {{ version }}<div class="save done"><i class="fa fa-fw fa-circle"></i></div>
  """
