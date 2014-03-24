# @depend Templates.coffee
###
# @property [String] id
# @property [HTML] contents
# @property [Time] currentTime
###
ATemplate.timelineBase = Handlebars.compile """
<div id="{{id}}" class="header">
  <div class="current_time">{{ currentTime }}</div>
  <a href="#"><i class="fa fa-fw fa-fast-backward"></i></a>
  <a href="#"><i class="fa fa-fw fa-backward"></i></a>
  <a href="#"><i class="fa fa-fw fa-play"></i></a>
  <a href="#"><i class="fa fa-fw fa-forward"></i></a>
  <a href="#"><i class="fa fa-fw fa-fast-forward"></i></a>
</div>
<div class="content">
  <div class="list">
    {{{ contents }}}
  </div>
  <div class="time">
    <div class="cursor" style="left: 64px"></div>
  </div>
</div>
"""

###
# @property [String] id
# @property [String] title
# @property [String] value
###
ATemplate.timelineActorProperty = Handlebars.compile """
<div id="{{id}}" class="row property">
  <div class="live">
    <button><i class="fa fa-fw fa-clock-o"></i></button>
  </div>
  <div class="graph">
    <button><i class="fa fa-fw fa-cog"></i></button>
  </div>
  <div class="title">{{title}}</div>
  <div class="value">{{value}}</div>
</div>
"""

###
# @property [String] id
# @property [String] title
# @property [HTML] properties
###
ATemplate.timelineActor = Handlebars.compile """
<div id="{{id}}" class="actor">
  <div class="row">
    <div class="visibility"><i class="fa fa-fw fa-eye"></i></div>
    <div class="expand"><i class="fa fa-fw fa-caret-down"></i></div>
    <div class="title">{{title}}</div>
  </div>
  {{{properties}}}
</div>
"""

###
# @property
###
ATemplate.timelineActor = Handlebars.compile """
<div id="{{id}}" class="actor">
  <div class="row">
    <div class="visibility"><i class="fa fa-fw fa-eye"></i></div>
    <div class="expand"><i class="fa fa-fw fa-caret-down"></i></div>
    <div class="title">{{title}}</div>
  </div>
  {{properties}}
</div>
"""