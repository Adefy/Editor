define ->

  ###
  # @property [String] name
  # @property [Number] value
  ###
  Handlebars.compile """
    <h1 data-name="{{dataName}}">
      <i class="fa fa-fw {{icon}}"></i>
      <label>{{displayName}}</label>
    </h1>
    <div>
      {{{contents}}}
    </div>
  """.split("\n").join " "