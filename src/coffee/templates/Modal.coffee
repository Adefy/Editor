# @depend templates.coffee

ATemplate.modal = Handlebars.compile """
<div class="aminner">
  <div class="amheader">
    <div class="title">{{ title }}</div>
    <div class="close"><button class="amf-dismiss"><i class="fa fa-times"></i></button></div>
  </div>
  <div class="ambody">
    {{{ content }}}
  </div>
  <div class="amfooter">
    <div class="amerror"></div>
    <button class="amf-dismiss">Close</div>
    {{#if cb}}
      <button class="amf-submit">Submit</div>
    {{/if}}
  </div>
</div>
"""