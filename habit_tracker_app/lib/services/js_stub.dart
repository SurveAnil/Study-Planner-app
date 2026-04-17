/// Mock class to satisfy the compiler on mobile.
class JsContext {
  dynamic callMethod(String method, [List<dynamic>? args]) => null;
}

/// The top-level 'context' variable that mirrors 'dart:js'
final context = JsContext();
