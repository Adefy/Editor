define ->

  ###
  # @property [String] title
  # @property [HTML] content
  # @property [Boolean] cb is a callback present? (this will enable the Submit button)
  ###
  Handlebars.compile """
    <div class="header">
      <div class="title">{{ title }}</div>
      <div class="close">
        <button class="modal-dismiss">
          <i class="fa fa-times"></i>
        </button>
      </div>
    </div>
    <div class="modal-body">
      {{{ content }}}
    </div>
    <div class="modal-footer">
      <div class="modal-error"></div>
      <button class="modal-dismiss close">Close</button>
      {{#if cb}}
        <button class="modal-submit">Submit</button>
      {{/if}}
    </div>
  """
