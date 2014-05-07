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
      <label for="{{ hex }}">Hex: </label>
      <input name="{{ hex }}" type="text" value="\#{{ hexstr }}"></input>
    <div>

    <br />
    <p style="text-align: center">Or...</p>
    <br />

    <div class="input_group">
      <label for="{{r}}">R: </label>
      <input name="{{r}}" type="text" value="{{colorRed}}"></input>
    <div>

    <div class="input_group">
      <label for="{{g}}">G: </label>
      <input name="{{g}}" type="text" value="{{colorGreen}}"></input>
    <div>

    <div class="input_group">
      <label for="{{b}}">B: </label>
      <input name="{{b}}" type="text" value="{{colorBlue}}"></input>
    <div>

    <div id="{{preview}}" class="bg-color-preview" style="{{pInitial}}"></div>
  """
