define ->

  ###
  # @property [String] name
  # @property [String] placeholder
  # @property [Number] value
  ###
  Handlebars.compile """
    <dl style="width: {{ width }}" class="control">
      <dt>{{ name }}</dt>
      <dd>
        <input type="text"
          data-control="text"

          {{#if parent}}
          data-parent="{{ parent }}"
          {{/if}}

          name="{{ name }}"
          placeholder="{{ placeholder }}"
          value="{{ value }}"
        />
      </dd>
    </dl>
  """.split("\n").join " "
