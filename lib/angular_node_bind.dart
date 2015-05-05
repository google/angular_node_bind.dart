// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library angular_node_bind;

import 'dart:html';
import 'package:angular/angular.dart';
import 'package:angular/core/parser/syntax.dart' show Expression;
import 'package:observe/observe.dart';
import 'package:template_binding/template_binding.dart';
import 'package:angular/core/module_internal.dart';

/**
 * An Angular-DI module for installing [NodeBindDirective].
 */
class NodeBindModule extends Module {
  NodeBindModule() {
    bind(NodeBindDirective);
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
@Decorator(selector: r'[*=/\[\[.*\]\]/]')
class NodeBindDirective {
  static final RegExp _EXPR_REGEXP = new RegExp(r'^\[\[(.*)\]\]$');
  static final RegExp _INTERPOLATE_REGEXP = new RegExp(r'\[\[(.*)\]\]');

  NodeBindDirective(Node node, Interpolate interpolate, Parser parser,
      Scope scope, FormatterMap formatterMap) {

    Element element = node;
    for (var attr in element.attributes.keys) {
      var value = element.attributes[attr];
      var exprMatch = _EXPR_REGEXP.firstMatch(value);

      var box = new ValueBindable();
      var binding = nodeBind(node).bind(attr.replaceFirst('bind-', ''), box);

      if (exprMatch != null) {
        var expr = exprMatch[1];
        Expression expression = parser(expr);
        if (expression.isAssignable) {
          box.onChange = (v) => expression.assign(scope.context, v);
        }
        scope.watch(expr, box.update);
      } else {
        var interpolation = interpolate(value, false, '[[', ']]');
        scope.watch(
            interpolation.expression, box.update, formatters: formatterMap);
      }
    }
  }
}

typedef dynamic _Nullary();
typedef dynamic _Unary(a);

class ValueBindable implements Bindable {
  var _value;
  var callback;
  var onChange;

  @override
  void close() {
    callback = null;
  }

  @override
  open(callback) {
    this.callback = callback;
    return _value;
  }

  void update(newValue, oldValue) {
    _value = newValue;
    if (callback != null) {
      if (callback is _Nullary) {
        callback();
      } else if (callback is _Unary) {
        callback(_value);
      }
    }
  }

  @override
  set value(newValue) {
    _value = newValue;
    if (onChange != null) onChange(_value);
  }

  @override
  get value => _value;
}
