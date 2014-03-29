define ->

  ###
  # @property [String] directoryStateIcon
  # @property [Object] directory
  #   @property [String] name
  # @property [HTML] content
  ###
  Handlebars.compile """
    <ul class="properties">
      {{#each controls}}
      <li class="control-group">{{{this}}}</li><hr>
      {{/each}}
    </ul>
  """
