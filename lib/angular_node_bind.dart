// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library angular_node_bind;

import 'dart:html';
import 'package:angular/angular.dart';
import 'package:observe/observe.dart';
import 'package:template_binding/template_binding.dart';

/**
 * An Angular-DI module for installing [NodeBindDirective].
 */
class NodeBindModule extends Module {
  NodeBindModule() {
    type(NodeBindDirective);
  }
}

/**
 * Allows binding expressions to elements that implement Node.bind, an aspiring
 * standard for adding databinding to HTML.
 *
 * Bindings are created by setting an attribute to an expression in your
 * template, but using square-brackets instead of curly-braces.
 *
 * Example:
 *
 *     <input value="[[ expr ]]'>
 *
 * The binding is two-way by default: if the expression is assignable, and if
 * the element publishes changes to it.
 *
 * Dart includes a polyfill, or shim, for Node.bind so that all elements
 * implement it. By default calling Node.bind will set the attribute. If
 * Node.bind handles the property name, it will create a binding to the
 * property. Existing elements like `<input>` have Node.bind implementations
 * that create two-way bindings for important properties, like `value`.
 *
 */
@NgDirective(selector: r'[*=/\[\[.*\]\]/]')
class NodeBindDirective {
  static final RegExp _EXPR_REGEXP = new RegExp(r'^\[\[(.*)\]\]$');
  static final RegExp _INTERPOLATE_REGEXP = new RegExp(r'\[\[(.*)\]\]');

  NodeBindDirective(Node node, Interpolate interpolate, Parser parser,
      Scope scope) {

    Element element = node;
    for (var attr in element.attributes.keys) {
      var value = element.attributes[attr];
      var exprMatch = _EXPR_REGEXP.firstMatch(value);

      var box = new ObservableBox();
      var binding = nodeBind(node).bind(attr, box, 'value');

      if (exprMatch != null) {
        var expr = exprMatch[1];
        Expression expression = parser(expr);
        if (expression.isAssignable) {
          box.changes.listen((_) => expression.assign(scope, box.value));
        }
        scope.$watch(expression.eval, (value, _) => box.value = value,
            '$attr=$value');
      } else {
        var curlies = value.splitMapJoin(_INTERPOLATE_REGEXP,
            onMatch: (m) => '{{${m[1]}}}');
        var interpolation = interpolate(curlies);
        interpolation.setter = (text) => box.value = text;
        scope.$watchSet(interpolation.watchExpressions, interpolation.call,
            '$attr=$value');
      }
    }
  }
}
