define ->

  ###
  # @property [String] directoryStateIcon
  # @property [Object] directory
  #   @property [String] name
  # @property [HTML] content
  ###
  Handlebars.compile """
    <dl>
      <dt><i class="fa fa-fw {{directoryStateIcon}} toggle-directory"></i></dt>
      <dd>
        <i class="fa fa-fw fa-folder"></i>{{directory.name}}
        {{{ content }}}
      </dd>
    </dl>
  """
