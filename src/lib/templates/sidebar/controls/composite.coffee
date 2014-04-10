define ->

  ###
  # @property [String] name
  # @property [Number] value
  ###
  Handlebars.compile """
    <h1 data-name="{{dataName}}">
      <i class="fa fa-fw {{icon}}"></i>
      <label>{{name}}</label>
    </h1>
    {{{contents}}}
  """.split("\n").join " "