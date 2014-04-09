define ->

  ###
  # @property [String] directoryStateIcon
  # @property [Object] directory
  #   @property [String] name
  # @property [HTML] content
  ###
  Handlebars.compile """
    <dl id="{{directory.id}}" class="asset directory">
      <dt class="toggle-directory">
        <i class="fa fa-fw {{directoryStateIcon}}"></i>
      </dt>
      <dd>
        <i class="fa fa-fw fa-folder"></i>{{directory.name}}
        {{{ content }}}
      </dd>
    </dl>
  """
