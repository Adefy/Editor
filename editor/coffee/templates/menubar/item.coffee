define ->

  ###
  # @property [String] title
  # @property [HTML] content
  # @property [Boolean] cb is a callback present? (this will enable the Submit button)
  ###
  Handlebars.compile """
    <a id="{{id}}" class="{{klass}}" href="{{href}}">
      <li>{{name}}</li>
    </a>
  """