# @depend Templates.coffee
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