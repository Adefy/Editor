Adefy Editor
============

Part of the adefy backend, this editor is used for building adefy ads and
deploying them to the adefy servers. It is built as a JS module, and creates
all the necessary HTML itself on instantiation. The only dependencies at the
moment are JQuery and JQuery UI.

Building
--------
Grunt! Targets are straighforward, use `grunt full` to perform a full rebuild,
and `grunt dev` to spawn a server and watch operation. Then navigate to
`http://localhost:8080/dev/test.html` to test things out.

The general way of things
-------------------------
* Use `param.required` to declare a required parameter in any method
* Use `param.optional` to declare an optional parameter in any method
* Perform all editor initialization inside of a document `ready` block
* Object classes should be prefixed with all major initals. i.e. `AWidgetSidebarObjectGroup` has a class `asog-catname` for the group name.
* Specify all colors in `colors.styl`, and define actual color codes seperate from their useages
* For widgets with at least one related/child widget class, put all files pertaining to it in their own folder
* All widgets are bound as data on the body element, under a key matching their selector
