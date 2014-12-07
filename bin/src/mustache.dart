library mustache;
import 'dart:io';
import 'dart:async';
import 'package:mustache4dart/mustache4dart.dart' as m4d;

class _MustacheTemplater {
  // These next to vars should be implemented as configuration files
  static var _templateDirectory = '${Directory.current.parent.path}/web/templates';
  static var _developmentMode = true;

  static var _cache = new Map<String, Function>();

  static Future<String> mustache(String filename, Object context) {
    return new Future(() {
      if (_developmentMode || !_cache[filename].containsKey(context)) {
        var template = (new File('$_templateDirectory/$filename')).readAsStringSync();

        String partialProvider(String partialName) =>
            (new File('$_templateDirectory/$partialName')).readAsStringSync();

        _cache[filename] = m4d.compile(template, partial: partialProvider);
      }
      return _cache[filename](context);
    });
  }
}

Future<String> mustache(String filename, [Object context = const Object()]) =>
    _MustacheTemplater.mustache(filename, context);