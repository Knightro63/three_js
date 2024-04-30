import 'extrude.dart';
import 'font.dart';

class TextGeometry extends ExtrudeGeometry{
  TextGeometry.create(super.shapes, super.options){
    type = "TextGeometry";
  }

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