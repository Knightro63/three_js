import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglMaterialsBrowser extends StatefulWidget {
  final String fileName;
  const WebglMaterialsBrowser({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglMaterialsBrowser> {
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

  Future<void> setup() async {
    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 1, 2000);
    demo.camera.position.z = 250;

    // scene

    demo.scene = three.Scene();

    var ambientLight = three.AmbientLight(0xcccccc, 0.4);
    demo.scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffff, 0.8);
    demo.camera.add(pointLight);
    demo.scene.add(demo.camera);

    // texture
    var geometry = TorusKnotGeometry(10, 3, 200, 32).toNonIndexed();
    var material = three.MeshPhysicalMaterial.fromMap({"color": 0xff0abb, "roughness": 0});

    var object = three.Mesh(geometry, material);

    demo.scene.add(object);
  }
}
