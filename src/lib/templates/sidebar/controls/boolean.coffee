define ->

  ###
  # @property [String] name
  # @property [Number] value
  ###
  Handlebars.compile """
  <div class="control">
    <label>{{displayName}}</label>

    <input type="checkbox"
      data-control="bool"

      {{#if parent}}
      data-parent="{{ parent }}"
      {{/if}}

      name="{{ name }}"

      {{#if value}}
        checked="checked"
      {{/if}}
    />
  </div>
  """.split("\n").join " "
