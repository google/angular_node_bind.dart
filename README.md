Angular Node Bind
=================

Utilities to allow Angular templates to use `Node.bind()`.

### NodeBindDirective

`NodeBindDirective` lets you use [Node.bind()][1] in an Angular app. This means
that you can bind to custom elements, including [Polymer][2] elements. The
bindings are declared by expressions in attribute values surrounded by
double-square-brackets, like so:

    <input value="[[ name ]]">
    
This declares that the expression <code>name</code> should be bound to the
`value` property of the element using `Node.bind()`. The advantages of using
Node.bind are:

  * Node.bind() takes care of setting up the binding, including two-way
    bindings, eliminating the need for directives for every property for two-way
    bindings.
  * Custom elements that expose properties will be properly bound, again
    including two-way bindings. You can use the growing collection of
    custom element libraries in your Angular app.

[1]: http://www.polymer-project.org/platform/node_bind.html
[2]: http://www.polymer-project.org/
