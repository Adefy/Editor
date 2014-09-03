requirejs.config baseUrl: "/coffee/"
requirejs ["editor"], (Editor) ->
  window.AdefyEditor = new Editor
  window.AdefyEditor.init()
