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
    <div id="{{ id }}" class="panel">
      <div class="tabs">
        {{#each tabs}}

        {{#if selected}}
        <div class="tab selected" data-index="{{ index }}">{{ name }}</div>
        {{else}}
        <div class="tab" data-index="{{ index }}">{{ name }}</div>
        {{/if}}

        {{/each}}

        <div data-sidebarid="{{sidebarId}}" class="button toggle">
          <i class="fa fa-fw fa-arrow-left"></i>
        </div>
      </div>
      <div id="{{contentId}}" class="content {{contentKlass}}">
        {{{ content }}}
      </div>
    </div>
  """