define ->

  ###
  # @property [String] name
  # @property [Number] value
  ###
  Handlebars.compile """
    <dd>
      <input type="checkbox"
        data-control="bool"

        data-controlgroup="{{ controlgroup }}"
        name="{{ name }}"
        {{bindAttr checked="value"}}
      />
    </dd>
  """.split("\n").join " "
