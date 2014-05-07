define ->

  ###
  # @property [String] name
  # @property [Number] value
  ###
  Handlebars.compile """
  <label data-name="{{dataName}}">{{displayName}}</label>

  {{{contents}}}
  """.split("\n").join " "
