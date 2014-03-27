define ->

  ###
  # @property [String] id
  # @property [String] sidebarId
  # @property [Array<Object>] tabs
  #   @property [String] selected
  #   @property [String] name
  # @property [String] contentKlass
  # @property [HTML] content
  ###
  Handlebars.compile """
    <div id="{{ id }}" class="panel">
      <div class="tabs">
        {{#each tabs}}
        <div class="tab {{selected}}">{{ name }}</div>
        {{/each}}
        <div sidebarid="{{sidebarId}}" class="button toggle">
          <i class="fa fa-fw fa-arrow-left"></i>
        </div>
      </div>
      <div class="content {{contentKlass}}">
        {{{ content }}}
      </div>
    </div>
  """
