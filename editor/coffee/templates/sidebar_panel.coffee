define ->

  ###
  # @property [String] id
  # @property [String] sidebarId
  # @property [Array<Object>] tabs
  #   @property [String] selected
  #   @property [String] name
  # @property [String] contentId
  # @property [String] contentKlass
  # @property [HTML] content
  ###
  Handlebars.compile """
    {{#if usesFooter}}
    <div id="{{id}}" class="panel with-footer">
    {{else}}
    <div id="{{id}}" class="panel">
    {{/if}}
      <div class="tabs">
        {{#each tabs}}

        {{#if selected}}
        <div class="tab selected" data-index="{{ index }}">{{ name }}</div>
        {{else}}
        <div class="tab" data-index="{{ index }}">{{ name }}</div>
        {{/if}}

        {{/each}}

        <div data-sidebarid="{{sidebarId}}" class="button toggle">
          <i class="fa fa-fw "></i>
        </div>
      </div>
      <div id="{{contentId}}" class="content {{contentKlass}}">
        {{{ content }}}
      </div>
      <div class="footer cf">
      </div>
    </div>
  """
