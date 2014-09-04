define ->

  ###
  # @property [String] name
  # @property [Number] value
  ###
  Handlebars.compile """
  <span data-name="{{dataName}}" class="label">{{displayName}}</span>

  {{{contents}}}
  """.split("\n").join " "
