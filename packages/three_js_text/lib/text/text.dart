import 'extrude.dart';
import 'font.dart';

/// A class for generating text as a single geometry. It is constructed by providing a string of text, and a set of
/// parameters consisting of a loaded font and settings for the geometry's parent [ExtrudeGeometry].
/// See the [FontLoader] page for additional details.
class TextGeometry extends ExtrudeGeometry{
  TextGeometry.create(super.shapes, super.options){
    type = "TextGeometry";
  }

  /// [text] — The text that needs to be shown.
  ///
  /// [parameters] — [TextGeometryOptions] that can contains the following parameters.
  factory TextGeometry(String text, TextGeometryOptions parameters) {
    Font? font = parameters.font;
    if (!(font != null && font.isFont)) {
      throw ('THREE.TextGeometry: font parameter is not an instance of THREE.Font.');
    }

    final shapes = font.generateShapes(text, size: parameters.size);

    // translate parameters to ExtrudeGeometry API

    // parameters["depth"] = parameters["height"] ?? 50;

    // defaults

    // if (parameters.bevelThickness == null) parameters["bevelThickness"] = 10;
    // if (parameters.bevelSize == null) parameters["bevelSize"] = 8;
    // if (parameters.bevelEnabled == null) parameters["bevelEnabled"] = false;

    TextGeometry textBufferGeometry = TextGeometry.create(shapes, parameters);

    return textBufferGeometry;
  }
}

class TextGeometryOptions extends ExtrudeGeometryOptions{
  /// [font] — an instance of Font.
  /// 
  /// [size] — Size of the text. Default is 100.
  /// 
  /// [depth] — Thickness to extrude text.  Default is 50.
  /// 
  /// [curveSegments] — Number of points on the curves. Default is 12.
  /// 
  /// [bevelEnabled] — Turn on bevel. Default is False.
  /// 
  /// [bevelThickness] — How deep into text bevel goes. Default is 10.
  /// 
  /// [bevelSize] — How far from text outline is bevel. Default is 8.
  /// 
  /// [bevelOffset] — How far from text outline bevel starts. Default is 0.
  /// 
  /// [bevelSegments] — Number of bevel segments. Default is 3.
  TextGeometryOptions({
    this.size = 100,
    this.font,

    super.curveSegments = 12,
    super.steps = 1,
    super.depth = 100,
    super.bevelEnabled = false,
    super.bevelThickness = 10,
    super.bevelSize = 8,
    super.bevelOffset = 0,
    super.extrudePath,
    super.bevelSegments = 3,
  });
  
  final double size;
  final Font? font;
}