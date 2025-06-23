import 'package:three_js_curves/three_js_curves.dart';

enum SVGUnits{mm,cm,inch,pt,pc,px}

class SVGData{
  SVGData({
    this.paths = const [],
    this.xml
  });

  final dynamic xml;
  final List<ShapePath> paths;
}

class SVGLoaderParser {
  SVGLoaderParser(String text, {this.defaultDPI = 90, this.defaultUnit = SVGUnits.px});

  SVGLoaderParser.parser();

  List<ShapePath> paths = [];

  SVGUnits defaultUnit = SVGUnits.px;
  num defaultDPI = 90;

  // Function parse =========== start
  SVGData parse(text) {
    return SVGData(paths: paths, xml: null);
  }
}
