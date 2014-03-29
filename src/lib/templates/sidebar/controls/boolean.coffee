define ->

  ###
  # @property [String] name
  # @property [Number] value
  ###
  Handlebars.compile """
    <dl style="width: {{ width }}">
      <dt>{{ name }}</dt>
      <dd>
        <input type="checkbox"
          data-control="bool"

          data-controlgroup="{{ controlgroup }}"
          name="{{ name }}"
          {{bindAttr checked="value"}}
        />
      </dd>
    </dl>
  """.split("\n").join " "
