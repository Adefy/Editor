#requirejs.config baseUrl: "/editor/build/lib/"
requirejs.config baseUrl: "lib/"
requirejs ["editor"], (Editor) ->
  window.AdefyEditor = new Editor
  window.AdefyEditor.init()