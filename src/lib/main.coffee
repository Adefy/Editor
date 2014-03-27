requirejs.config baseUrl: "lib/"
requirejs ["editor"], (Editor) ->
  window.editor = new Editor
