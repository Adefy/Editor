# @depend Templates.coffee
ATemplate.modal = Handlebars.compile """
<div class="modal-inner">
  <div class="modal-header">
    <div class="title">{{ title }}</div>
    <div class="close"><button class="modal-dismiss"><i class="fa fa-times"></i></button></div>
  </div>
  <div class="modal-body">
    {{{ content }}}
  </div>
  <div class="modal-footer">
    <div class="modal-error"></div>
    <button class="modal-dismiss">Close</button>
    {{#if cb}}
      <button class="modal-submit">Submit</button>
    {{/if}}
  </div>
</div>
"""