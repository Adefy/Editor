define ->

  ###
  # @property [String] name
  # @property [Number] max
  # @property [Number] min
  # @property [Boolean] float
  # @property [String] placeholder
  # @property [Number] value
  ###
  Handlebars.compile """
  <div class="control">
    <label>{{displayName}}</label>

    <input type="number"
      data-control="number"

      {{#if parent}}
      data-parent="{{ parent }}"
      {{/if}}

      name="{{ name }}"
      max="{{ max }}"
      min="{{ min }}"
      data-float="{{ float }}"
      placeholder="{{ placeholder }}"
      value="{{ value }}"
    />
  </div>
  """.split("\n").join " "
