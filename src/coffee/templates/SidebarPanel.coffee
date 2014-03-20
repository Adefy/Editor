# @depend templates.coffee
ATemplate.sidebarPanel = Handlebars.compile """
<div id="{{ id }}">
  <div class="as-panel">
    <div class="tabs">
      {{#each tabs}}
      <div class="tab {{selected}}">{{ name }}</div>
      {{/each}}
    </div>
    <div class="contents {{contentsKlass}}">
      {{{ contents }}}
    </div>
  </div>
</div>
"""