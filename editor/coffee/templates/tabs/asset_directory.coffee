define ->

  ###
  # @property [String] directoryStateIcon
  # @property [Object] directory
  #   @property [String] name
  # @property [HTML] content
  ###
  Handlebars.compile """
    <dl id="{{directory.id}}" class="asset directory {{expanded}}">
      <dt class="toggle-directory">
        <i class="fa fa-fw {{directoryStateIcon}}"></i>
      </dt>
      <dd>
        <i class="fa fa-fw fa-folder"></i>
        <label class="name">{{directory.name}}</label>
        {{{ content }}}
      </dd>
    </dl>
  """
