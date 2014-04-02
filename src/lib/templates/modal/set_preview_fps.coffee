define ->

  ###
  # @property [Number] previewFPS
  # @property [String] name
  ###
  Handlebars.compile """
    <div class="input_group">
    <label for="_tPreviewRate">Framerate: </label>
    <input type="text" value="{{previewFPS}}" placeholder="30" name="{{name}}" />
    </div>
  """