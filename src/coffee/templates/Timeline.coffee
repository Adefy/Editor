##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# @depend Templates.coffee

###
# Control bar and base
# @property [String] id
# @property [Time] currentTime
# -property [HTML] contents Actors will go here
# -property [HTML] timecontents Actor time & keyframes will go here
###
ATemplate.timelineBase = Handlebars.compile """
<div id="{{ id }}" class="header">
  <div id="timeline-cursor-time" class="current_time">{{ currentTime }}</div>
  <a id="timeline-control-fast-backward"><i class="fa fa-fw fa-fast-backward"></i></a>
  <a id="timeline-control-backward"><i class="fa fa-fw fa-backward"></i></a>
  <a id="timeline-control-play"><i class="fa fa-fw fa-play"></i></a>
  <a id="timeline-control-forward"><i class="fa fa-fw fa-forward"></i></a>
  <a id="timeline-control-fast-forward"><i class="fa fa-fw fa-fast-forward"></i></a>
</div>
<div class="content">
  <div class="list">
    {{! <div class="timebar"></div> }}
    {{! contents }}
  </div>
  <div class="time">
    <div id="timeline-cursor" class="cursor"></div>
    {{! <div class="timebar"></div> }}
    <div class="time-actors">
      {{! timeContents }}
    </div>
  </div>
</div>
"""

###
# Actor Property
# @property [String] id
# @property [String] title
# @property [String] value
###
#ATemplate.timelineActorProperty = Handlebars.compile """
#<div id="{{ id }}" class="row property">
#  <div class="live">
#    <button><i class="fa fa-fw fa-clock-o"></i></button>
#  </div>
#  <div class="graph">
#    <button><i class="fa fa-fw fa-cog"></i></button>
#  </div>
#  <div class="title">{{ title }}</div>
#  <div class="value">{{ value }}</div>
#</div>
#"""

###
# Content that appears on the left of the Timeline
# @property [String] id
# @property [Id] actorId
# @property [String] title
# @property [Array<Object>] properties
#   @property [String] id
#   @property [String] title
#   @property [String] value
###
ATemplate.timelineActor = Handlebars.compile """
<div id="{{ id }}" class="actor">
  <div class="actor-info row">
    <div actorid="{{actorId}}" class="visibility"><i class="fa fa-fw fa-eye"></i></div>
    <div actorid="{{actorId}}" class="expand"><i class="fa fa-fw fa-caret-right"></i></div>
    <div actorid="{{actorId}}" class="title">{{ title }}</div>
  </div>
 {{#each properties}}
  <div id="{{ id }}" class="actor-property row property">
    <div class="live">
      <div class="button"><i class="fa fa-fw fa-clock-o"></i></div>
    </div>
    <div class="graph">
      <div class="button"><i class="fa fa-fw fa-cog"></i></div>
    </div>
    <div class="title">{{ title }}</div>
    <div class="value">{{ value }}</div>
  </div>
 {{/each}}
</div>
"""

###
# Content that appears on the right of the Timeline
# @property [String] id
# @property [Number] dataIndex
# @property [Boolean] isExpanded
# @property [Array<Object>] properties
#   @property [String] id
#   @property [Boolean] isProperty
#   @property [Number] left if not isProperty
#   @property [Number] width if not isProperty
#   @property [Array<Object>] keyframes if isProperty
#     @property [String] id
#     @property [Number] left
###
ATemplate.timelineActorTime = Handlebars.compile """
{{#if isExpanded}}
<div id="{{ id }}" data-index="{{ dataIndex }}" class="actor expanded">
{{else}}
<div id="{{ id }}" data-index="{{ dataIndex }}" class="actor">
{{/if}}
  {{#each properties}}
   {{#if isProperty}}
    <div id="{{ id }}" class="row property">
      <div style="left: {{ left }}px; width: {{ width }}px" class="bar"></div>
    </div>
   {{else}}
    <div id="{{ id }}" class="row">
     {{#each keyframes}}
      <div id="{{ id }}" style="left: {{ left }}px" class="keyframe"></div>
     {{/each}}
    </div>
   {{/if}}
  {{/each}}
</div>
"""