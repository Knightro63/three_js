import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_svg/three_js_svg.dart';

class WebglLoaderSvg extends StatefulWidget {
  final String fileName;
  const WebglLoaderSvg({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderSvg> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  late three.Mesh mesh;
  late three.Object3D object;
  late three.Texture texture;

  final guiData = {
    "currentURL": 'assets/models/svg/tiger.svg',
    // "currentURL": 'assets/models/svg/energy.svg',
    // "currentURL": 'assets/models/svg/hexagon.svg',
    // "currentURL": 'assets/models/svg/lineJoinsAndCaps.svg',
    // "currentURL": 'assets/models/svg/multiple-css-classes.svg',
    // "currentURL": 'assets/models/svg/threejs.svg',
    // "currentURL": 'assets/models/svg/zero-radius.svg',
    "drawFillShapes": true,
    "drawStrokes": true,
    "fillShapesWireframe": false,
    "strokesWireframe": false
  };


  Future<void> setup() async {
    demo.camera = three.PerspectiveCamera(50, demo.width / demo.height, 1, 1000);
    demo.camera.position.setValues(0, 0, 200);

    loadSVG(guiData["currentURL"]);
  }

  void loadSVG(url) {
    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xb0b0b0);

    final helper = GridHelper(160, 10);
    helper.rotation.x = math.pi / 2;
    demo.scene.add(helper);

    SVGLoader loader = SVGLoader();

    loader.fromAsset(url).then((data) {
      print(data);
      List<three.ShapePath> paths = data!.paths;

      three.Group group = three.Group();
      group.scale.scale(0.25);
      group.position.x = -25;
      group.position.y = 25;
      group.rotateZ(math.pi);
      group.rotateY(math.pi);
      //group.scale.y *= -1;

      for (int i = 0; i < paths.length; i++) {
        three.ShapePath path = paths[i];

        final fillColor = path.userData?["style"]["fill"];
        if (guiData["drawFillShapes"] == true &&
            fillColor != null &&
            fillColor != 'none') {
          three.MeshBasicMaterial material = three.MeshBasicMaterial.fromMap({
            "color": three.Color().setStyle(fillColor).convertSRGBToLinear(),
            "opacity": path.userData?["style"]["fillOpacity"],
            "transparent": true,
            "side": three.DoubleSide,
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
            "color": three.Color().setStyle(strokeColor).convertSRGBToLinear(),
            "opacity": path.userData?["style"]["strokeOpacity"],
            "transparent": true,
            "side": three.DoubleSide,
            "depthWrite": false,
            "wireframe": guiData["strokesWireframe"]
          });

          for (int j = 0, jl = path.subPaths.length; j < jl; j++) {
            three.Path subPath = path.subPaths[j];
            final geometry = SVGLoader.pointsToStroke(
                subPath.getPoints(), path.userData?["style"]);

            if (geometry != null) {
              final mesh = three.Mesh(geometry, material);

              group.add(mesh);
            }
          }
        }
      }

      demo.scene.add(group);
    });
  }
}
