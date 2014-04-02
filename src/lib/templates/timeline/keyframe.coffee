define ->

  ###
  # Content that appears on the right of the Timeline
  # @property [String] id
  # @property [Number] left
  ###
  Handlebars.compile """
    <div id="{{ id }}" style="left: {{ left }}px" class="keyframe"></div>
  """
