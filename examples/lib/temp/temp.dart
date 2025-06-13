import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatefulWidget{
  const MyApp({super.key,}) ;
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: initThree,
      settings: three.Settings(
        useOpenGL: true,
      )
    );
    super.initState();
  }

  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: threeJs.build()
          )
        )
      )
    );
  }

  Future initThree() async {
    three.Vector3 getVec3() {
      final random = Random();
      return three.Vector3(
      random.nextDouble() * 5 * (random.nextBool() ? 1.0 : -1.0),
      random.nextDouble() * 5 * (random.nextBool() ? 1.0 : -1.0),
      random.nextDouble() * 5 * (random.nextBool() ? 1.0 : -1.0),
      );
    }

    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera(50, threeJs.width / threeJs.height, 0.1, 1000);
    threeJs.camera.position.setFrom(three.Vector3(0, 2, 6));

    final geometry = three.BoxGeometry();
    final random = Random();
    for (var i = 0; i < 100; i++) {
      final mesh = three.Mesh(
        geometry,
        three.MeshBasicMaterial({
          three.MaterialProperty.color: three.Color(
            random.nextDouble(),
            random.nextDouble(),
            random.nextDouble(),
          ),
        }),
      );
      mesh.position.setFrom(getVec3());
      threeJs.scene.add(mesh);
    }
    three.OrbitControls(threeJs.camera, threeJs.globalKey);
  }
}
