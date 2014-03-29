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
    <dd>
      <input type="number"
        data-control="number"

        data-controlgroup="{{ controlgroup }}"
        name="{{ name }}"
        data-max="{{ max }}"
        data-min="{{ min }}"
        data-float="{{ float }}"
        placeholder="{{ placeholder }}"
        value="{{ value }}"
      />
    </dd>
  """.split("\n").join " "
