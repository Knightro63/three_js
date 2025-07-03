import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_svg/three_js_svg.dart';

class WebglLoaderSvg extends StatefulWidget {
  
  const WebglLoaderSvg({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderSvg> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data)
        ],
      ) 
    );
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
    threeJs.camera = three.PerspectiveCamera(50, threeJs.width / threeJs.height, 1, 1000);
    threeJs.camera.position.setValues(0, 0, 200);

    loadSVG(guiData["currentURL"]);
  }

  void loadSVG(url) {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xb0b0b0);

    final helper = GridHelper(160, 10);
    helper.rotation.x = math.pi / 2;
    threeJs.scene.add(helper);

    SVGLoader loader = SVGLoader();

    loader.fromAsset(url).then((data) {
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

      threeJs.scene.add(group);
    });
  }
}
