define ->

  ###
  # @property [String] name
  # @property [String] placeholder
  # @property [Number] value
  ###
  Handlebars.compile """
    <dl style="width: {{ width }}">
      <dt>{{ name }}</dt>
      <dd>
        <input type="text"
          data-control="text"

          data-controlgroup="{{ controlgroup }}"
          name="{{ name }}"
          placeholder="{{ placeholder }}"
          value="{{ value }}"
        />
      </dd>
    </dl>
  """.split("\n").join " "
