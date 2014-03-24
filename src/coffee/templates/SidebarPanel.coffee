# @depend Templates.coffee
###
# @property [String] id
# @property [Array<Object>] tabs
#   @property [String] selected
#   @property [String] name
# @property [String] contentKlass
# @property [HTML] content
###
ATemplate.sidebarPanel = Handlebars.compile """
<div id="{{ id }}" class="panel">
  <div class="tabs">
    {{#each tabs}}
    <div class="tab {{selected}}">{{ name }}</div>
    {{/each}}
  </div>
  <div class="content {{contentKlass}}">
    {{{ content }}}
  </div>
</div>
"""