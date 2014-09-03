define ->

  ###
  # @property [String] name
  # @property [String] placeholder
  # @property [Number] value
  ###
  Handlebars.compile """
  <div class="control">
    <label>{{displayName}}</label>

    <input type="text"
      data-control="text"

      {{#if parent}}
      data-parent="{{ parent }}"
      {{/if}}

      name="{{ name }}"
      placeholder="{{ placeholder }}"
      value="{{ value }}"
    />
  </div>
  """.split("\n").join " "
