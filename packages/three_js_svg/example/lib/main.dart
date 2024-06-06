import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart' as tmath;
import 'package:three_js_svg/three_js_svg.dart';
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_curves/three_js_curves.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebglLoaderSvg(),
    );
  }
}

class WebglLoaderSvg extends StatefulWidget {
  const WebglLoaderSvg({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderSvg> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  late three.Mesh mesh;
  late three.Object3D object;
  late three.Texture texture;

  final guiData = {
    "currentURL": 'assets/tiger.svg',
    // "currentURL": 'assets/energy.svg',
    // "currentURL": 'assets/hexagon.svg',
    // "currentURL": 'assets/lineJoinsAndCaps.svg',
    // "currentURL": 'assets/multiple-css-classes.svg',
    // "currentURL": 'assets/threejs.svg',
    // "currentURL": 'assets/zero-radius.svg',
    "drawFillShapes": true,
    "drawStrokes": true,
    "fillShapesWireframe": false,
    "strokesWireframe": false
  };


  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(50, threeJs.width / threeJs.height, 1, 1000);
    threeJs.camera.position.setValues(0, 0, 200);

    loadSVG(guiData["currentURL"]);
  }

  void loadSVG(url) {
    threeJs.scene = three.Scene();
    threeJs.scene.background = tmath.Color.fromHex32(0xb0b0b0);

    final helper = GridHelper(160, 10);
    helper.rotation.x = math.pi / 2;
    threeJs.scene.add(helper);

    SVGLoader loader = SVGLoader();

    loader.fromAsset(url).then((data) {
      List<ShapePath> paths = data!.paths;

      three.Group group = three.Group();
      group.scale.scale(0.25);
      group.position.x = -25;
      group.position.y = 25;
      group.rotateZ(math.pi);
      group.rotateY(math.pi);
      //group.scale.y *= -1;

      for (int i = 0; i < paths.length; i++) {
        ShapePath path = paths[i];

        final fillColor = path.userData?["style"]["fill"];
        if (guiData["drawFillShapes"] == true &&
            fillColor != null &&
            fillColor != 'none') {
          three.MeshBasicMaterial material = three.MeshBasicMaterial.fromMap({
            "color": tmath.Color().setStyle(fillColor).convertSRGBToLinear(),
            "opacity": path.userData?["style"]["fillOpacity"],
            "transparent": true,
            "side": tmath.DoubleSide,
            "depthWrite": false,
            "wireframe": guiData["fillShapesWireframe"]
          });

          final shapes = SVGLoader.createShapes(path);

          for (int j = 0; j < shapes.length; j++) {
            final shape = shapes[j];

            ShapeGeometry geometry = ShapeGeometry([shape]);
            three.Mesh mesh = three.Mesh(geometry, material);

            group.add(mesh);
          }
        }

        final strokeColor = path.userData?["style"]["stroke"];

        if (guiData["drawStrokes"] == true &&
            strokeColor != null &&
            strokeColor != 'none') {
          three.MeshBasicMaterial material = three.MeshBasicMaterial.fromMap({
            "color": tmath.Color().setStyle(strokeColor).convertSRGBToLinear(),
            "opacity": path.userData?["style"]["strokeOpacity"],
            "transparent": true,
            "side": tmath.DoubleSide,
            "depthWrite": false,
            "wireframe": guiData["strokesWireframe"]
          });

          for (int j = 0, jl = path.subPaths.length; j < jl; j++) {
            Path subPath = path.subPaths[j];
            final geometry = SVGLoader.pointsToStroke(
                subPath.getPoints(), path.userData?["style"]);

            if (geometry != null) {
              final mesh = three.Mesh(geometry, material);

              group.add(mesh);
            }
          }
        }
      }

      threeJs.scene.add(group);
    });
  }
}