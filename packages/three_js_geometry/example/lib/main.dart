import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart' as tmath;
import 'package:three_js_geometry/three_js_geometry.dart';
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
      home: const WebglGeometries(),
    );
  }
}


class WebglGeometries extends StatefulWidget {
  const WebglGeometries({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglGeometries> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,      settings: three.Settings(
        localClippingEnabled: true,
      )
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

  int startTime = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2000);
    threeJs.camera.position.y = 400;

    threeJs.scene = three.Scene();

    three.Mesh object;

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    final material = three.MeshPhongMaterial.fromMap({"side": tmath.DoubleSide});

    //

    object = three.Mesh(three.SphereGeometry(75, 20, 10), material);
    object.position.setValues(-300, 0, 200);
    threeJs.scene.add(object);

    object = three.Mesh(IcosahedronGeometry(75, 1), material);
    object.position.setValues(-100, 0, 200);
    threeJs.scene.add(object);

    object = three.Mesh(OctahedronGeometry(75, 2), material);
    object.position.setValues(100, 0, 200);
    threeJs.scene.add(object);

    object = three.Mesh(TetrahedronGeometry(75, 0), material);
    object.position.setValues(300, 0, 200);
    threeJs.scene.add(object);

    //

    object = three.Mesh(three.PlaneGeometry(100, 100, 4, 4), material);
    object.position.setValues(-300, 0, 0);
    threeJs.scene.add(object);

    object = three.Mesh(three.BoxGeometry(100, 100, 100, 4, 4, 4), material);
    object.position.setValues(-100, 0, 0);
    threeJs.scene.add(object);

    object = three.Mesh(
        CircleGeometry(
            radius: 50,
            segments: 20,
            thetaStart: 0,
            thetaLength: math.pi * 2),
        material);
    object.position.setValues(100, 0, 0);
    threeJs.scene.add(object);

    object = three.Mesh(RingGeometry(10, 50, 20, 5, 0, math.pi * 2), material);
    object.position.setValues(300, 0, 0);
    threeJs.scene.add(object);

    //

    object = three.Mesh(CylinderGeometry(25, 75, 100, 40, 5), material);
    object.position.setValues(-300, 0, -200);
    threeJs.scene.add(object);

    List<tmath.Vector2> points = [];

    for (int i = 0; i < 50; i++) {
      points.add(tmath.Vector2(
          math.sin(i * 0.2) * math.sin(i * 0.1) * 15 + 50,
          (i - 5) * 2));
    }

    object = three.Mesh(LatheGeometry(points, segments: 20), material);
    object.position.setValues(-100, 0, -200);
    threeJs.scene.add(object);

    object = three.Mesh(TorusGeometry(50, 20, 20, 20), material);
    object.position.setValues(100, 0, -200);
    threeJs.scene.add(object);

    object = three.Mesh(TorusKnotGeometry(50, 10, 50, 20), material);
    object.position.setValues(300, 0, -200);
    threeJs.scene.add(object);

    startTime = DateTime.now().millisecondsSinceEpoch;

    threeJs.addAnimationEvent((dt){
      final timer = DateTime.now().millisecondsSinceEpoch * 0.0001;

      threeJs.camera.position.x = math.cos(timer) * 800;
      threeJs.camera.position.z = math.sin(timer) * 800;
      threeJs.camera.lookAt(threeJs.scene.position);

      threeJs.scene.traverse((object) {
        if (object is three.Mesh) {
          object.rotation.x = timer * 5;
          object.rotation.y = timer * 2.5;
        }
      });
    });
  }
}
