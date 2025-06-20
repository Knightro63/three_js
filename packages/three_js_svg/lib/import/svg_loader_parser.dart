import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_curves/three_js_curves.dart';
import 'package:xml/xml.dart' as xmld;
import 'package:universal_html/parsing.dart';
import 'package:universal_html/html.dart' as uhtml;
import '../utils/color_utils.dart';

enum SVGUnits{mm,cm,inch,pt,pc,px}

class SVGData{
  SVGData({
    this.paths = const [],
    this.xml
  });

  final xmld.XmlName? xml;
  final List<ShapePath> paths;
}

class SVGLoaderParser {
  SVGLoaderParser(String text, {this.defaultDPI = 90, this.defaultUnit = SVGUnits.px}) {
    xmlN = xmld.XmlDocument.parse(text);
    xmlD = parseXmlDocument(text);
  }

  SVGLoaderParser.parser();

  List<ShapePath> paths = [];
  Map stylesheets = {};

  final transformStack = [];

  final tempTransform0 = Matrix3.identity();
  final tempTransform1 = Matrix3.identity();
  final tempTransform2 = Matrix3.identity();
  final tempTransform3 = Matrix3.identity();
  final tempV2 = Vector2();
  final tempV3 = Vector3();

  final currentTransform = Matrix3.identity();

  SVGUnits defaultUnit = SVGUnits.px;
  num defaultDPI = 90;

  late final xmld.XmlDocument? xmlN;
  late final uhtml.XmlDocument xmlD;

  // Units

  final units = ['mm', 'cm', 'in', 'pt', 'pc', 'px'];

  // Conversion: [ fromUnit ][ toUnit ] (-1 means dpi dependent)
  final unitConversion = {
    "mm": {
      'mm': 1,
      'cm': 0.1,
      'in': 1 / 25.4,
      'pt': 72 / 25.4,
      'pc': 6 / 25.4,
      'px': -1
    },
    "cm": {
      'mm': 10,
      'cm': 1,
      'in': 1 / 2.54,
      'pt': 72 / 2.54,
      'pc': 6 / 2.54,
      'px': -1
    },
    "in": {'mm': 25.4, 'cm': 2.54, 'in': 1, 'pt': 72, 'pc': 6, 'px': -1},
    "pt": {
      'mm': 25.4 / 72,
      'cm': 2.54 / 72,
      'in': 1 / 72,
      'pt': 1,
      'pc': 6 / 72,
      'px': -1
    },
    "pc": {
      'mm': 25.4 / 6,
      'cm': 2.54 / 6,
      'in': 1 / 6,
      'pt': 72 / 6,
      'pc': 1,
      'px': -1
    },
    "px": {'px': 1}
  };

  // Function parse =========== start
  SVGData parse(text) {
    parseNode(xmlN?.firstElementChild, {
      "fill": '#000',
      "fillOpacity": 1,
      "strokeOpacity": 1,
      "strokeWidth": 1,
      "strokeLineJoin": 'miter',
      "strokeLineCap": 'butt',
      "strokeMiterLimit": 4
    });

    return SVGData(paths: paths, xml: xmlN?.firstElementChild?.name);
  }

  double parseFloatWithUnits([String? string]) {
    if (string == null) {
      return 0;
    }

    String theUnit = 'px';
    for (int i = 0, n = units.length; i < n; i++) {
      final u = units[i];

      if (string!.endsWith(u)) {
        theUnit = u;
        string = string.substring(0, string.length - u.length);
        break;
      }
    }
    

    double scale;

    if (theUnit == 'px' && defaultUnit != SVGUnits.px) {
      // Conversion scale from  pixels to inches, then to default units
      scale = unitConversion["in"]![defaultUnit.name]! / defaultDPI;
    } 
    else {
      scale = unitConversion[theUnit]![defaultUnit.name]!.toDouble();

      if (scale < 0) {
        // Conversion scale to pixels
        scale = unitConversion[theUnit]!['in']! * defaultDPI.toDouble();
      }
    }

    String str = "$string";
    // if(_str.startsWith("-.")) {
    //   _str = _str.replaceFirst("-.", "-0.");
    // }

    List<String> strs = str.split(".");

    if (strs.length >= 3) {
      strs = strs.sublist(0, 2);
      str = strs.join(".");
    }
    return scale * num.parse(str);
  }

  // from https://github.com/ppvg/svg-numbers (MIT License)
  List<double> parseFloats(input, [flags, stride]) {
    if (input is! String) {
      throw ('Invalid input: ${input.runtimeType} ');
    }

    // Character groups
    Map<String, dynamic> re = {
      "SEPARATOR": RegExp(r"[ \t\r\n\,.\-+]"),
      "WHITESPACE": RegExp(r"[ \t\r\n]"),
      "DIGIT": RegExp(r"[\d]"),
      "SIGN": RegExp(r"[-+]"),
      "POINT": RegExp(r"\."),
      "COMMA": RegExp(r","),
      "EXP": RegExp(r"e", caseSensitive: false),
      "FLAGS": RegExp(r"[01]")
    };

    // States
    const sep = 0;
    const int_ = 1;
    const float = 2;
    const exp = 3;

    int state = sep;
    bool seenComma = true;
    String number = '', exponent = '';
    List<double> result = [];

    void throwSyntaxError(current, i, partial) {
      final error =('Unexpected character "$current" at index $i.');
      throw (error);
    }

    void newNumber() {
      if (number != '') {
        if (exponent == '') {
          result.add(double.parse(number));
        } else {
          result.add(double.parse(number) * math.pow(10, double.parse(exponent)));
        }
      }

      number = '';
      exponent = '';
    }

    String current;
    final length = input.length;

    for (int i = 0; i < length; i++) {
      current = input[i];

      // check for flags
      if (flags is List &&
          flags.contains(result.length % stride) &&
          re["FLAGS"].hasMatch(current)) {
        state = int_;
        number = current;
        newNumber();
        continue;
      }

      // parse until next number
      if (state == sep) {
        // eat whitespace
        if (re["WHITESPACE"].hasMatch(current)) {
          continue;
        }

        // start new number
        if (re["DIGIT"].hasMatch(current) || re["SIGN"].hasMatch(current)) {
          state = int_;
          number = current;
          continue;
        }

        if (re["POINT"].hasMatch(current)) {
          state = float;
          number = current;
          continue;
        }

        // throw on double commas (e.g. "1, , 2")
        if (re["COMMA"].hasMatch(current)) {
          if (seenComma) {
            throwSyntaxError(current, i, result);
          }

          seenComma = true;
        }
      }

      // parse integer part
      if (state == int_) {
        if (re["DIGIT"].hasMatch(current)) {
          number += current;
          continue;
        }

        if (re["POINT"].hasMatch(current)) {
          number += current;
          state = float;
          continue;
        }

        if (re["EXP"].hasMatch(current)) {
          state = exp;
          continue;
        }

        // throw on double signs ("-+1"), but not on sign as separator ("-1-2")
        if (re["SIGN"].hasMatch(current) &&
            number.length == 1 &&
            re["SIGN"].hasMatch(number[0])) {
          throwSyntaxError(current, i, result);
        }
      }

      // parse decimal part
      if (state == float) {
        if (re["DIGIT"].hasMatch(current)) {
          number += current;
          continue;
        }

        if (re["EXP"].hasMatch(current)) {
          state = exp;
          continue;
        }

        // throw on double decimal points (e.g. "1..2")
        if (re["POINT"].hasMatch(current) && number[number.length - 1] == '.') {
          throwSyntaxError(current, i, result);
        }
      }

      // parse exponent part
      if (state == exp) {
        if (re["DIGIT"].hasMatch(current)) {
          exponent += current;
          continue;
        }

        if (re["SIGN"].hasMatch(current)) {
          if (exponent == '') {
            exponent += current;
            continue;
          }

          if (exponent.length == 1 && re["SIGN"].hasMatch(exponent)) {
            throwSyntaxError(current, i, result);
          }
        }
      }

      // end of number
      if (re["WHITESPACE"].hasMatch(current)) {
        newNumber();
        state = sep;
        seenComma = false;
      } else if (re["COMMA"].hasMatch(current)) {
        newNumber();
        state = sep;
        seenComma = true;
      } else if (re["SIGN"].hasMatch(current)) {
        newNumber();
        state = int_;
        number = current;
      } else if (re["POINT"].hasMatch(current)) {
        newNumber();
        state = float;
        number = current;
      } else {
        throwSyntaxError(current, i, result);
      }
    }

    // add the last number found (if any)
    newNumber();

    return result;
  }

  Matrix3 parseNodeTransform(node) {
    final transform = Matrix3.identity();
    final currentTransform = tempTransform0;

    if (node.nodeName == 'use' && (node.hasAttribute('x') || node.hasAttribute('y'))) {
      final tx = parseFloatWithUnits(node.getAttribute('x'));
      final ty = parseFloatWithUnits(node.getAttribute('y'));

      transform.translate(tx, ty);
    }

    if (node.hasAttribute('transform')) {
      final transformsTexts = node.getAttribute('transform').split(')');

      for (int tIndex = transformsTexts.length - 1; tIndex >= 0; tIndex--) {
        final transformText = transformsTexts[tIndex].trim();

        if (transformText == '') continue;

        final openParPos = transformText.indexOf('(');
        final closeParPos = transformText.length;

        if (openParPos > 0 && openParPos < closeParPos) {
          final transformType = substr(transformText, 0, openParPos);

          final floatStr = substr(
              transformText, openParPos + 1, closeParPos - openParPos - 1);

          final array = parseFloats(floatStr);

          currentTransform.identity();

          switch (transformType) {
            case 'translate':
              if (array.isNotEmpty) {
                final tx = array[0];
                double ty = tx;

                if (array.length >= 2) {
                  ty = array[1];
                }

                currentTransform.translate(tx, ty);
              }

              break;

            case 'rotate':
              if (array.isNotEmpty) {
                double angle = 0;
                double cx = 0;
                double cy = 0;

                // Angle
                angle = -array[0] * math.pi / 180.0;

                if (array.length >= 3) {
                  // Center x, y
                  cx = array[1];
                  cy = array[2];
                }

                // Rotate around center (cx, cy)
                tempTransform1.identity().translate(-cx, -cy);
                tempTransform2.identity().rotate(angle);
                tempTransform3.multiply2(tempTransform2, tempTransform1);
                tempTransform1.identity().translate(cx, cy);
                currentTransform.multiply2(tempTransform1, tempTransform3);
              }

              break;

            case 'scale':
              if (array.isNotEmpty) {
                final scaleX = array[0];
                double scaleY = scaleX;

                if (array.length >= 2) {
                  scaleY = array[1];
                }

                currentTransform.scaleXY(scaleX, scaleY);
              }

              break;

            case 'skewX':
              if (array.length == 1) {
                currentTransform.setValues(1, math.tan(array[0] * math.pi / 180), 0, 0, 1, 0, 0, 0, 1);
              }

              break;

            case 'skewY':
              if (array.length == 1) {
                currentTransform.setValues(1, 0, 0, math.tan(array[0] * math.pi / 180), 1, 0, 0, 0, 1);
              }

              break;

            case 'matrix':
              if (array.length == 6) {
                currentTransform.setValues(array[0], array[2], array[4], array[1],array[3], array[5], 0, 0, 1);
              }

              break;
          }
        }

        transform.premultiply(currentTransform);
      }
    }

    return transform;
  }

  // Transforms

  Matrix3? getNodeTransform(xmld.XmlElement node) {
    if (!(node.hasAttribute('transform') ||
        (node.name.local == 'use' && (node.hasAttribute('x') || node.hasAttribute('y'))))) {
      return Matrix3.identity();
    }

    final transform = parseNodeTransform(node);

    if (transformStack.isNotEmpty) {
      transform.premultiply(transformStack[transformStack.length - 1]);
    }

    currentTransform.setFrom(transform);
    transformStack.add(transform);

    return transform;
  }

  void parseCSSStylesheet(node) {
    if (node.sheet == null ||
        node.sheet.cssRules == null ||
        node.sheet.cssRules.length == 0) {
      return;
    }

    for (int i = 0; i < node.sheet.cssRules.length; i++) {
      final stylesheet = node.sheet.cssRules[i];

      if (stylesheet.type != 1) continue;

      RegExp reg = RegExp(r",", multiLine: true);
      final selectorList =
          stylesheet.selectorText.split(reg).map((i) => i.trim()).toList();

      // final selectorList = stylesheet.selectorText
      // 	.split( /,/gm )
      // 	.filter( Boolean )
      // 	.map( i => i.trim() );

      for (int j = 0; j < selectorList.length; j++) {
        final sj = selectorList[j];

        if (stylesheets[sj] == null) {
          stylesheets[sj] = {};
        }
        stylesheets[sj].addAll(stylesheet.style);
        // stylesheets[ selectorList[ j ] ] = Object.assign(
        // 	stylesheets[ selectorList[ j ] ] || {},
        // 	stylesheet.style
        // );

      }
    }
  }

  Map<String, dynamic> parseStyle(node, style) {
    // style = Object.assign( {}, style );
    // clone style
    Map<String, dynamic> style2 = <String, dynamic>{};
    style2.addAll(style);

    final stylesheetStyles = {};

    if (node.hasAttribute('class')) {
      final reg = RegExp(r"\s");
      final classSelectors = node
          .getAttribute('class')
          .split(reg)
          // .filter( Boolean )
          .map((i) => i.trim())
          .toList();

      for (int i = 0; i < classSelectors.length; i++) {
        // stylesheetStyles = Object.assign( stylesheetStyles, stylesheets[ '.' + classSelectors[ i ] ] );
        stylesheetStyles.addAll(stylesheets['.${classSelectors[i]}'] ?? {});
      }
    }

    if (node.hasAttribute('id')) {
      // stylesheetStyles = Object.assign( stylesheetStyles, stylesheets[ '#' + node.getAttribute( 'id' ) ] );

      stylesheetStyles.addAll(stylesheets['#${node.getAttribute('id')}'] ?? {});
    }

    void addStyle(svgName, jsName, [adjustFunction]) {
      adjustFunction ??= (v) {
        if (v.startsWith('url')) {
          console.info('SVGLoader: url access in attributes is not implemented.');
        }

        return v;
      };

      if (node.hasAttribute(svgName)) {
        style2[jsName] = adjustFunction(node.getAttribute(svgName));
      }
      if (stylesheetStyles[svgName] != null) {
        style2[jsName] = adjustFunction(stylesheetStyles[svgName]);
      }

      if (node.style != null) {
        final style = node.style;
        final value = style.getPropertyValue(svgName);
        if (value != "") {
          style2[jsName] = adjustFunction(value);
        }
      }
    }

    num clamp(v) {
      return math.max<num>(0, math.min(1, parseFloatWithUnits(v)));
    }

    num positive(v) {
      return math.max<num>(0, parseFloatWithUnits(v));
    }

    addStyle('fill', 'fill');
    addStyle('fill-opacity', 'fillOpacity', clamp);
    addStyle('fill-rule', 'fillRule');
    addStyle('opacity', 'opacity', clamp);
    addStyle('stroke', 'stroke');
    addStyle('stroke-opacity', 'strokeOpacity', clamp);
    addStyle('stroke-width', 'strokeWidth', positive);
    addStyle('stroke-linejoin', 'strokeLineJoin');
    addStyle('stroke-linecap', 'strokeLineCap');
    addStyle('stroke-miterlimit', 'strokeMiterLimit', positive);
    addStyle('visibility', 'visibility');

    return style2;
  }

  // http://www.w3.org/TR/SVG11/implnote.html#PathElementImplementationNotes

  getReflection(a, b) {
    return a - (b - a);
  }

  double svgAngle(ux, uy, vx, vy) {
    final dot = ux * vx + uy * vy;
    final len = math.sqrt(ux * ux + uy * uy) * math.sqrt(vx * vx + vy * vy);
    double ang = math.acos(math.max(
        -1,
        math.min(
            1,
            dot /
                len))); // floating point precision, slightly over values appear
    if ((ux * vy - uy * vx) < 0) ang = -ang;
    return ang;
  }

  /**
		 * https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes
		 * https://mortoray.com/2017/02/16/rendering-an-svg-elliptical-arc-as-bezier-curves/ Appendix: Endpoint to center arc conversion
		 * From
		 * rx ry x-axis-rotation large-arc-flag sweep-flag x y
		 * To
		 * aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation
		 */

  void parseArcCommand(path, rx, ry, xAxisRotation, largeArcFlag, sweepFlag, start, end) {
    if (rx == 0 || ry == 0) {
      // draw a line if either of the radii == 0
      path.lineTo(end.x, end.y);
      return;
    }

    xAxisRotation = xAxisRotation * math.pi / 180;

    // Ensure radii are positive
    rx = rx.abs();
    ry = ry.abs();

    // Compute (x1', y1')
    final dx2 = (start.x - end.x) / 2.0;
    final dy2 = (start.y - end.y) / 2.0;
    final x1p = math.cos(xAxisRotation) * dx2 + math.sin(xAxisRotation) * dy2;
    final y1p = -math.sin(xAxisRotation) * dx2 + math.cos(xAxisRotation) * dy2;

    // Compute (cx', cy')
    double rxs = rx * rx;
    double rys = ry * ry;
    final x1ps = x1p * x1p;
    final y1ps = y1p * y1p;

    // Ensure radii are large enough
    final cr = x1ps / rxs + y1ps / rys;

    if (cr > 1) {
      // scale up rx,ry equally so cr == 1
      final s = math.sqrt(cr);
      rx = s * rx;
      ry = s * ry;
      rxs = rx * rx;
      rys = ry * ry;
    }

    final dq = (rxs * y1ps + rys * x1ps);
    final pq = (rxs * rys - dq) / dq;
    double q = math.sqrt(math.max(0, pq));
    if (largeArcFlag == sweepFlag) q = -q;
    final cxp = q * rx * y1p / ry;
    final cyp = -q * ry * x1p / rx;

    // Step 3: Compute (cx, cy) from (cx', cy')
    final cx = math.cos(xAxisRotation) * cxp -
        math.sin(xAxisRotation) * cyp +
        (start.x + end.x) / 2;
    final cy = math.sin(xAxisRotation) * cxp +
        math.cos(xAxisRotation) * cyp +
        (start.y + end.y) / 2;

    // Step 4: Compute θ1 and Δθ
    final theta = svgAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
    final delta = svgAngle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx,
            (-y1p - cyp) / ry) %
        (math.pi * 2);

    path.currentPath.absellipse(
        cx, cy, rx, ry, theta, theta + delta, sweepFlag == 0, xAxisRotation);
  }

  ShapePath parsePath(String d) {
    final path = ShapePath();

    final point = Vector2();
    final control = Vector2();

    final firstPoint = Vector2();
    bool isFirstPoint = true;
    bool doSetFirstPoint = false;

    final reg = RegExp(r"[a-df-z][^a-df-z]*", caseSensitive: false);
    final commands = reg.allMatches(d);

    // final commands = d.match( /[a-df-z][^a-df-z]*/ig );

    for (final item in commands) {
      final command = item.group(0)!;

      final type = command.substring(0, 1);
      final data = substr(command, 1).trim();

      if (isFirstPoint == true) {
        doSetFirstPoint = true;
        isFirstPoint = false;
      }

      switch (type) {
        case 'M':
          List<double> numbers = parseFloats(data);
          for (int j = 0, jl = numbers.length; j < jl; j += 2) {
            point.x = numbers[j + 0];
            point.y = numbers[j + 1];
            control.x = point.x;
            control.y = point.y;

            if (j == 0) {
              path.moveTo(point.x, point.y);
            } else {
              path.lineTo(point.x, point.y);
            }

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'H':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j++) {
            point.x = numbers[j];
            control.x = point.x;
            control.y = point.y;
            path.lineTo(point.x, point.y);

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'V':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j++) {
            point.y = numbers[j];
            control.x = point.x;
            control.y = point.y;
            path.lineTo(point.x, point.y);

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'L':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 2) {
            point.x = numbers[j + 0];
            point.y = numbers[j + 1];
            control.x = point.x;
            control.y = point.y;
            path.lineTo(point.x, point.y);

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'C':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 6) {
            path.bezierCurveTo(numbers[j + 0], numbers[j + 1], numbers[j + 2],
                numbers[j + 3], numbers[j + 4], numbers[j + 5]);
            control.x = numbers[j + 2];
            control.y = numbers[j + 3];
            point.x = numbers[j + 4];
            point.y = numbers[j + 5];

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'S':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 4) {
            path.bezierCurveTo(
                getReflection(point.x, control.x),
                getReflection(point.y, control.y),
                numbers[j + 0],
                numbers[j + 1],
                numbers[j + 2],
                numbers[j + 3]);
            control.x = numbers[j + 0];
            control.y = numbers[j + 1];
            point.x = numbers[j + 2];
            point.y = numbers[j + 3];

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'Q':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 4) {
            path.quadraticCurveTo(
                numbers[j + 0], numbers[j + 1], numbers[j + 2], numbers[j + 3]);
            control.x = numbers[j + 0];
            control.y = numbers[j + 1];
            point.x = numbers[j + 2];
            point.y = numbers[j + 3];

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'T':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 2) {
            final rx = getReflection(point.x, control.x);
            final ry = getReflection(point.y, control.y);
            path.quadraticCurveTo(rx, ry, numbers[j + 0], numbers[j + 1]);
            control.x = rx;
            control.y = ry;
            point.x = numbers[j + 0];
            point.y = numbers[j + 1];

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'A':
          final numbers = parseFloats(data, [3, 4], 7);

          for (int j = 0, jl = numbers.length; j < jl; j += 7) {
            // skip command if start point == end point
            if (numbers[j + 5] == point.x && numbers[j + 6] == point.y) {
              continue;
            }

            final start = point.clone();
            point.x = numbers[j + 5];
            point.y = numbers[j + 6];
            control.x = point.x;
            control.y = point.y;
            parseArcCommand(path, numbers[j], numbers[j + 1], numbers[j + 2],
                numbers[j + 3], numbers[j + 4], start, point);

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'm':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 2) {
            point.x += numbers[j + 0];
            point.y += numbers[j + 1];
            control.x = point.x;
            control.y = point.y;

            if (j == 0) {
              path.moveTo(point.x, point.y);
            } else {
              path.lineTo(point.x, point.y);
            }

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'h':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j++) {
            point.x += numbers[j];
            control.x = point.x;
            control.y = point.y;
            path.lineTo(point.x, point.y);

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'v':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j++) {
            point.y += numbers[j];
            control.x = point.x;
            control.y = point.y;
            path.lineTo(point.x, point.y);

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'l':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 2) {
            point.x += numbers[j + 0];
            point.y += numbers[j + 1];
            control.x = point.x;
            control.y = point.y;
            path.lineTo(point.x, point.y);

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'c':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 6) {
            path.bezierCurveTo(
                point.x + numbers[j + 0],
                point.y + numbers[j + 1],
                point.x + numbers[j + 2],
                point.y + numbers[j + 3],
                point.x + numbers[j + 4],
                point.y + numbers[j + 5]);
            control.x = point.x + numbers[j + 2];
            control.y = point.y + numbers[j + 3];
            point.x += numbers[j + 4];
            point.y += numbers[j + 5];

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 's':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 4) {
            path.bezierCurveTo(
                getReflection(point.x, control.x),
                getReflection(point.y, control.y),
                point.x + numbers[j + 0],
                point.y + numbers[j + 1],
                point.x + numbers[j + 2],
                point.y + numbers[j + 3]);
            control.x = point.x + numbers[j + 0];
            control.y = point.y + numbers[j + 1];
            point.x += numbers[j + 2];
            point.y += numbers[j + 3];

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'q':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 4) {
            path.quadraticCurveTo(
                point.x + numbers[j + 0],
                point.y + numbers[j + 1],
                point.x + numbers[j + 2],
                point.y + numbers[j + 3]);
            control.x = point.x + numbers[j + 0];
            control.y = point.y + numbers[j + 1];
            point.x += numbers[j + 2];
            point.y += numbers[j + 3];

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 't':
          final numbers = parseFloats(data);

          for (int j = 0, jl = numbers.length; j < jl; j += 2) {
            final rx = getReflection(point.x, control.x);
            final ry = getReflection(point.y, control.y);
            path.quadraticCurveTo(
                rx, ry, point.x + numbers[j + 0], point.y + numbers[j + 1]);
            control.x = rx;
            control.y = ry;
            point.x = point.x + numbers[j + 0];
            point.y = point.y + numbers[j + 1];

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'a':
          final numbers = parseFloats(data, [3, 4], 7);

          for (int j = 0, jl = numbers.length; j < jl; j += 7) {
            // skip command if no displacement
            if (numbers[j + 5] == 0 && numbers[j + 6] == 0) continue;

            final start = point.clone();
            point.x += numbers[j + 5];
            point.y += numbers[j + 6];
            control.x = point.x;
            control.y = point.y;
            parseArcCommand(path, numbers[j], numbers[j + 1], numbers[j + 2],
                numbers[j + 3], numbers[j + 4], start, point);

            if (j == 0 && doSetFirstPoint == true) firstPoint.setFrom(point);
          }

          break;

        case 'Z':
        case 'z':
          path.currentPath.autoClose = true;

          if (path.currentPath.curves.isNotEmpty) {
            // Reset point to beginning of Path
            point.setFrom(firstPoint);
            path.currentPath.currentPoint.setFrom(point);
            isFirstPoint = true;
          }
          break;
        default:
          console.warning("SvgLoader.parsePathNode command is not support ...\nConnamd: $command");
      }

      // Console.log( type, parseFloats( data ), parseFloats( data ).length  )

      doSetFirstPoint = false;
    }

    return path;
  }

  ShapePath parsePathNode(node) {
    final d = node.getAttribute('d');
    return parsePath(d);
  }

  /*
		* According to https://www.w3.org/TR/SVG/shapes.html#RectElementRXAttribute
		* rounded corner should be rendered to elliptical arc, but bezier curve does the job well enough
		*/
  ShapePath parseRectNode(node) {
    final x = parseFloatWithUnits(node.getAttribute('x') ?? '0');
    final y = parseFloatWithUnits(node.getAttribute('y') ?? '0');
    final rx = parseFloatWithUnits(node.getAttribute('rx') ?? '0');
    final ry = parseFloatWithUnits(node.getAttribute('ry') ?? '0');
    final w = parseFloatWithUnits(node.getAttribute('width'));
    final h = parseFloatWithUnits(node.getAttribute('height'));

    final path = ShapePath();
    path.moveTo(x + 2 * rx, y);
    path.lineTo(x + w - 2 * rx, y);
    if (rx != 0 || ry != 0) {
      path.bezierCurveTo(x + w, y, x + w, y, x + w, y + 2 * ry);
    }
    path.lineTo(x + w, y + h - 2 * ry);
    if (rx != 0 || ry != 0) {
      path.bezierCurveTo(x + w, y + h, x + w, y + h, x + w - 2 * rx, y + h);
    }
    path.lineTo(x + 2 * rx, y + h);

    if (rx != 0 || ry != 0) {
      path.bezierCurveTo(x, y + h, x, y + h, x, y + h - 2 * ry);
    }

    path.lineTo(x, y + 2 * ry);

    if (rx != 0 || ry != 0) {
      path.bezierCurveTo(x, y, x, y, x + 2 * rx, y);
    }

    return path;
  }

  ShapePath parsePolygonNode(node) {
    console.info("SVGLoader: parsePolygonNode todo test.");
    // final regex = /(-?[\d\.?]+)[,|\s](-?[\d\.?]+)/g;
    final regex = RegExp(r"(-?[\d\.?]+)[,|\s](-?[\d\.?]+)");
    final path = ShapePath();
    int index = 0;

    // Function iterator = (match, a, b) {
    //   final x = parseFloatWithUnits(a);
    //   final y = parseFloatWithUnits(b);

    //   if (index == 0) {
    //     path.moveTo(x, y);
    //   } else {
    //     path.lineTo(x, y);
    //   }

    //   index++;
    // };
    // node.getAttribute('points').replace(regex, iterator);

    String points = node.getAttribute('points');
    final matches = regex.allMatches(points);

    for (final match in matches) {
      final a = match.group(1);
      final b = match.group(2);

      final x = parseFloatWithUnits(a);
      final y = parseFloatWithUnits(b);

      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      index++;
    }

    path.currentPath.autoClose = true;

    return path;
  }

  ShapePath parsePolylineNode(node) {
    console.info("SVGLoader: parsePolylineNode todo.");

    // final regex = /(-?[\d\.?]+)[,|\s](-?[\d\.?]+)/g;
    final regex = RegExp(r"(-?[\d\.?]+)[,|\s](-?[\d\.?]+)");

    final path = ShapePath();

    int index = 0;

    iterator(match, a, b) {
      final x = parseFloatWithUnits(a);
      final y = parseFloatWithUnits(b);

      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      index++;
    }

    node.getAttribute('points').replace(regex, iterator);

    path.currentPath.autoClose = false;

    return path;
  }

  ShapePath parseCircleNode(node) {
    final x = parseFloatWithUnits(node.getAttribute('cx'));
    final y = parseFloatWithUnits(node.getAttribute('cy'));
    final r = parseFloatWithUnits(node.getAttribute('r'));

    final subpath = Path(null);
    subpath.absarc(x, y, r, 0, math.pi * 2, null);

    final path = ShapePath();
    path.subPaths.add(subpath);

    return path;
  }

  ShapePath parseEllipseNode(node) {
    final x = parseFloatWithUnits(node.getAttribute('cx'));
    final y = parseFloatWithUnits(node.getAttribute('cy'));
    final rx = parseFloatWithUnits(node.getAttribute('rx'));
    final ry = parseFloatWithUnits(node.getAttribute('ry'));

    final subpath = Path(null);
    subpath.absellipse(x, y, rx, ry, 0, math.pi * 2, null, null);

    final path = ShapePath();
    path.subPaths.add(subpath);

    return path;
  }

  ShapePath parseLineNode(node) {
    final x1 = parseFloatWithUnits(node.getAttribute('x1'));
    final y1 = parseFloatWithUnits(node.getAttribute('y1'));
    final x2 = parseFloatWithUnits(node.getAttribute('x2'));
    final y2 = parseFloatWithUnits(node.getAttribute('y2'));

    final path = ShapePath();
    path.moveTo(x1, y1);
    path.lineTo(x2, y2);
    path.currentPath.autoClose = false;

    return path;
  }

  bool isTransformRotated(Matrix3 m) {
    return m.storage[1] != 0 || m.storage[3] != 0;
  }

  double getTransformScaleX(Matrix3 m) {
    final te = m.storage;
    return math.sqrt(te[0] * te[0] + te[1] * te[1]);
  }

  double getTransformScaleY(Matrix3 m) {
    final te = m.storage;
    return math.sqrt(te[3] * te[3] + te[4] * te[4]);
  }

  void transformPath(path, Matrix3 m) {
    transfVec2(v2) {
      tempV3.setValues(v2.x, v2.y, 1).applyMatrix3(m);

      v2.setValues(tempV3.x, tempV3.y);
    }

    final isRotated = isTransformRotated(m);

    final subPaths = path.subPaths;

    for (int i = 0, n = subPaths.length; i < n; i++) {
      final subPath = subPaths[i];
      final curves = subPath.curves;

      for (int j = 0; j < curves.length; j++) {
        final curve = curves[j];

        if (curve is LineCurve) {
          transfVec2(curve.v1);
          transfVec2(curve.v2);
        } 
        else if (curve.isCubicBezierCurve) {
          transfVec2(curve.v0);
          transfVec2(curve.v1);
          transfVec2(curve.v2);
          transfVec2(curve.v3);
        } 
        else if (curve.isQuadraticBezierCurve) {
          transfVec2(curve.v0);
          transfVec2(curve.v1);
          transfVec2(curve.v2);
        } 
        else if (curve.isEllipseCurve) {
          if (isRotated) {
            console.info('SVGLoader: Elliptic arc or ellipse rotation or skewing is not implemented.');
          }

          tempV2.setValues(curve.aX, curve.aY);
          transfVec2(tempV2);
          curve.aX = tempV2.x;
          curve.aY = tempV2.y;

          curve.xRadius *= getTransformScaleX(m);
          curve.yRadius *= getTransformScaleY(m);
        }
      }
    }
  }

  void parseNode(xmld.XmlElement? node, style) {
    if (node == null) return;
    print(node.name.local);

    final transform = getNodeTransform(node);
    bool traverseChildNodes = true;

    dynamic path;
    print(node.name.local);
    switch (node.name.local) {
      case 'svg':
        break;

      case 'style':
        parseCSSStylesheet(node);
        break;

      case 'g':
        style = parseStyle(node, style);
        break;

      case 'path':
        style = parseStyle(node, style);
        // if (node.hasAttribute('d')) {
        //   path = parsePathNode(node);
        // }
        break;

      case 'rect':
        style = parseStyle(node, style);
        path = parseRectNode(node);
        break;

      case 'polygon':
        style = parseStyle(node, style);
        path = parsePolygonNode(node);
        break;

      case 'polyline':
        style = parseStyle(node, style);
        path = parsePolylineNode(node);
        break;

      case 'circle':
        style = parseStyle(node, style);
        path = parseCircleNode(node);
        break;

      case 'ellipse':
        style = parseStyle(node, style);
        path = parseEllipseNode(node);
        break;

      case 'line':
        style = parseStyle(node, style);
        path = parseLineNode(node);
        break;

      case 'defs':
        traverseChildNodes = false;
        break;

      case 'use':
        style = parseStyle(node, style);
        // final usedNodeId = node.href.baseVal.substring(1);
        // final usedNode = node.viewportElement.getElementById(usedNodeId);
        // if (usedNode != null) {
        //   parseNode(usedNode, style);
        // } 
        // else {
        //   console.info("SVGLoader: 'use node' references non-existent node id: $usedNodeId");
        // }

        break;

      default:
      // Console.log( node );

    }

    if (path != null) {
      if (style["fill"] != null && style["fill"] != 'none') {
        (path.color as Color).setStyle(style["fill"]);
      }

      transformPath(path, currentTransform);

      paths.add(path);

      path.userData = {"node": node, "style": style};
    }

    if (traverseChildNodes) {
      final nodes = node.childElements;
      nodes.forEach((action){
        parseNode(action, style);
      });
    }

    if (transform != null) {
      if(transformStack.isNotEmpty){
      transformStack.removeLast();

      if (transformStack.isNotEmpty) {
        currentTransform.setFrom(transformStack[transformStack.length - 1]);
      } 
      else {
        currentTransform.identity();
      }
      }
    }
  }

  String substr(String str, int start, [int? length]) {
    if (start < 0) {
      start = str.length + start;
    }
    if (start < 0) {
      start = 0;
    }
    if (start > str.length) {
      start = str.length;
    }
    final end = length == null
        ? str.length
        : start + length > str.length
            ? str.length
            : start + length;
    return str.substring(start, end);
  }

  static Map<String,dynamic> getStrokeStyle(width, color, lineJoin, lineCap, miterLimit) {
    // Param width: Stroke width
    // Param color: As returned by THREE.Color.getStyle()
    // Param lineJoin: One of "round", "bevel", "miter" or "miter-limit"
    // Param lineCap: One of "round", "square" or "butt"
    // Param miterLimit: Maximum join length, in multiples of the "width" parameter (join is truncated if it exceeds that distance)
    // Returns style object

    width = width ?? 1;
    color = color ?? '#000';
    lineJoin = lineJoin ?? 'miter';
    lineCap = lineCap ?? 'butt';
    miterLimit = miterLimit ?? 4;

    return {
      "strokeColor": color,
      "strokeWidth": width,
      "strokeLineJoin": lineJoin,
      "strokeLineCap": lineCap,
      "strokeMiterLimit": miterLimit
    };
  }
}
