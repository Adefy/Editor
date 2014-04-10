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
      <label for="{{textnameID}}">Texture Name: </label>
      <input name="{{textnameID}}" type="text" value="{{textname}}"></input>
    <div>
    <div class="input_group">
      <label for="{{textpathID}}">Select Texture: </label>
      <input name="{{textpathID}}" type="file" value="{{textpath}}" multiple>
      </input>
    <div>
  """
