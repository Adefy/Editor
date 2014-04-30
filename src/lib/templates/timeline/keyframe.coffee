define ->

  ###
  # Content that appears on the right of the Timeline
  # @property [String] id
  # @property [Number] left
  ###
  Handlebars.compile """
    <div id="{{id}}" data-property="{{property}}" data-time="{{time}}" style="left: {{left}}" class="keyframe"></div>
  """
