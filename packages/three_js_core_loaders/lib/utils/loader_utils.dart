import 'dart:convert' as convert;

class LoaderUtils {
  static String decodeText(List<int> array) {
    final s = const convert.Utf8Decoder().convert(array);
    return s;
  }

  static String extractUrlBase(String url) {
    var index = url.lastIndexOf('/');

    if (index == -1) return './';

    return url.substring(0, index + 1);
  }

  /* UTILITY FUNCTIONS */
  static String resolveURL(String url, String path) {
    // Host Relative URL
    final reg1 = RegExp("^https?://", caseSensitive: false);
    if (reg1.hasMatch(path) &&
        RegExp("^/", caseSensitive: false).hasMatch(url)) {
      final reg2 = RegExp("(^https?://[^/]+).*", caseSensitive: false);

      final matches = reg2.allMatches(path);

      for (RegExpMatch match in matches) {
        path = path.replaceFirst(match.group(0)!, match.group(1)!);
      }

      print("GLTFHelper.resolveURL todo debug  ");
      // path = path.replace( RegExp("(^https?:\/\/[^\/]+).*", caseSensitive: false), '$1' );

    }

    // Absolute URL http://,https://,//
    if (RegExp("^(https?:)?//", caseSensitive: false).hasMatch(url)) {
      return url;
    }

    // Data URI
    if (RegExp(r"^data:.*,.*$", caseSensitive: false).hasMatch(url)) return url;

    // Blob URL
    if (RegExp(r"^blob:.*$", caseSensitive: false).hasMatch(url)) return url;

    // Relative URL
    return path + url;
  }
}
