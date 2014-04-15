define ->

  ###
  # @property [Hex] hex
  # @property [String] hexstr
  # @property [String] r
  # @property [String] g
  # @property [String] b
  # @property [Number] colorRed
  # @property [Number] colorGreen
  # @property [Number] colorBlue
  # @property [String] preview
  # @property [String] pInitial
  ###
  Handlebars.compile """
    <div class="input_group">
      <label for="{{nameId}}">Name: </label>
      <input name="{{nameId}}" type="text" value="{{name}}"></input>
    <div>
  """