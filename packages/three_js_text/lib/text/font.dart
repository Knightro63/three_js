import 'package:three_js_curves/three_js_curves.dart';

abstract class Font {
  String type = 'Font';
  late Map<String, dynamic> data;
  bool isFont = true;

  void dispose();

  List<Shape> generateShapes(text, {double size = 100});
  List<ShapePath> createPaths(String text, double size, Map<String, dynamic> data);
  Map<String, dynamic> createPath(String char, double scale, double offsetX, double offsetY, data);
}