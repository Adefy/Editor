requirejs.config baseUrl: "lib/"
requirejs ["editor"], (Editor) ->
  window.AdefyEditor = new Editor