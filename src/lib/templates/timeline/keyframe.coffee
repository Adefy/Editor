define ->

  ###
  # Content that appears on the right of the Timeline
  # @property [String] id
  # @property [Number] left
  ###
  Handlebars.compile """
    <div data-time="{{ time }}" style="left: {{ left }}px" class="keyframe"></div>
  """
