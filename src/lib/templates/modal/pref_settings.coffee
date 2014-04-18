define ->

  ###
  # @property [Number] autosaveFreq
  # @property [ID] autosaveFreqID
  ###
  Handlebars.compile """
    <div class="input_group">
      <label for="{{autosaveFreqID}}">Autosave Frequency (ms): </label>
      <input name="{{autosaveFreqID}}" type="number" value="{{autosaveFreq}}"></input>
    <div>

    <div class="input_group">
      <label for="{{areRendererModeID}}">ARE RendererMode: </label>
      <input name="{{areRendererModeID}}" type="number" value="{{autosaveFreq}}"></input>
    <div>
  """
