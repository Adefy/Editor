define ->

  Handlebars.compile """
    <div id="{{id}}" class="editor-canvas">
      <div id="{{id}}-overlay-left" class="canvas-overlay"></div>
      <div id="{{id}}-overlay-right" class="canvas-overlay"></div>
      <div id="{{id}}-overlay-top" class="canvas-overlay"></div>
      <div id="{{id}}-overlay-bottom" class="canvas-overlay"></div>
      <div id="{{id}}-overlay-center" class="canvas-overlay-center"></div>
    </div>
  """
