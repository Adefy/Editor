define ->

  ###
  # @property [String] name
  # @property [String] placeholder
  # @property [Number] value
  ###
  Handlebars.compile """
    <dd>
      <input type="text"
        data-control="text"

        data-controlgroup="{{ controlgroup }}"
        name="{{ name }}"
        placeholder="{{ placeholder }}"
        value="{{ value }}"
      />
    </dd>
  """.split("\n").join " "
