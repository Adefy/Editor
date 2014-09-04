define ->

  ###
  # @property [Number] autosaveFreq
  # @property [ID] autosaveFreqID
  ###
  Handlebars.compile """
  <div class="content">
    <ul>
      {{#each settings}}
      <li class="input {{#if halfw}}halfw{{/if}}">
        <label>{{label}}</label>
        <input

          {{#if checked}}
          checked="checked"
          {{/if}}

          {{#if min}}min="{{min}}"{{/if}}
          {{#if max}}max="{{max}}"{{/if}}
          data-id="{{id}}"
          type="{{computedType}}"
          placeholder="{{placeholder}}"
          value="{{value}}"/>
      </li>
      {{/each}}
    </ul>
  </div>

  <span class="footer-title">
    {{title}}
    <i class="fa fa-check close"></i>
  </span>
  """
