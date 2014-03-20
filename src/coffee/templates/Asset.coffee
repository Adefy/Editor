# @depend Templates.coffee
ATemplate.assetDirectory = Handlebars.compile """
  <dl>
    <dt><i class="fa fa-fw {{directoryStateIcon}}"></i></dt>
    <dd>
      <i class="fa fa-fw fa-folder"></i>{{directory.name}}
      {{{ content }}}
    </dd>
  </dl>
"""
ATemplate.assetFile = Handlebars.compile """
  <dl>
    <dt><i class="fa fa-fw"></i></dt>
    <dd><i class="fa fa-fw fa-file"></i>{{file.name}}</dd>
  </dl>
"""