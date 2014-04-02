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
    <dl style="width: {{ width }}" class="control">
      <dt>{{ name }}</dt>
      <dd>
        <input type="number"
          data-control="number"

          {{#if parent}}
          data-parent="{{ parent }}"
          {{/if}}

          name="{{ name }}"
          data-max="{{ max }}"
          data-min="{{ min }}"
          data-float="{{ float }}"
          placeholder="{{ placeholder }}"
          value="{{ value }}"
        />
      </dd>
    </dl>
  """.split("\n").join " "
