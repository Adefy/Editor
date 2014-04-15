define ->

  ###
  # @property [String] name
  # @property [Number] value
  ###
  Handlebars.compile """
    <dl style="width: {{ width }}" class="control">
      <dt>{{ displayName }}</dt>
      <dd>
        <input type="checkbox"
          data-control="bool"

          {{#if parent}}
          data-parent="{{ parent }}"
          {{/if}}

          name="{{ name }}"
          {{bindAttr checked="value"}}
        />
      </dd>
    </dl>
  """.split("\n").join " "
