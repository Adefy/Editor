define ->

  ###
  #
  ###
  Handlebars.compile """
    <div class="controls">
      <span class="target-name">{{actorName}}</span>

      {{#controls}}
      <div class="control-wrapper">
        {{{.}}}
      </div>
      {{/controls}}
    </div>
  """
