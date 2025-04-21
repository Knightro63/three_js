import 'dart:async';
import '../src/statistics.dart';
import 'package:flutter/material.dart' hide Matrix4;
import 'package:three_js/three_js.dart' as three;

class MultiViews extends StatefulWidget {
  const MultiViews({super.key});
  @override
  createState() => _MyAppState();
}

class _MyAppState extends State<MultiViews> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const MultiViews1(),
          Container(height: 2, color: Colors.red,),
          const MultiViews2()
        ],
      )
    );
  }
}

class MultiViews1 extends StatefulWidget {
  const MultiViews1({super.key});
  @override
  createState() => _MultiViews1State();
}
class _MultiViews1State extends State<MultiViews1> {
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
      settings: three.Settings(
        useOpenGL: useOpenGL
      ),
      size: const Size(300,300),
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 100);

    // scene
    threeJs.scene = three.Scene();

    three.AmbientLight ambientLight = three.AmbientLight(0xffffff, 0.9);
    threeJs.scene.add(ambientLight);

    three.PointLight pointLight = three.PointLight(0xffffff, 0.8);

    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    three.BoxGeometry geometry = three.BoxGeometry(20, 20, 20);
    three.MeshBasicMaterial material = three.MeshBasicMaterial.fromMap({"color": 0xff0000});

    final object = three.Mesh(geometry, material);
    threeJs.scene.add(object);

    threeJs.addAnimationEvent((dt){
      object.rotation.x = object.rotation.x + 0.01;
    });
  }
}

class MultiViews2 extends StatefulWidget {
  const MultiViews2({super.key});
  @override
  createState() => _MultiViews2State();
}
class _MultiViews2State extends State<MultiViews2> {
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
      settings: three.Settings(
        useOpenGL: useOpenGL
      ),
      size: const Size(300,300),
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
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
  three.AnimationMixer? mixer;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 100);


    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color(1, 1, 0);

    three.AmbientLight ambientLight = three.AmbientLight(0xffffff, 0.9);
    threeJs.scene.add(ambientLight);

    three.PointLight pointLight = three.PointLight(0xffffff, 0.8);
    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);
    threeJs.camera.lookAt(threeJs.scene.position);

    three.BoxGeometry geometry = three.BoxGeometry(10, 10, 20);
    three.MeshBasicMaterial material = three.MeshBasicMaterial();

    object = three.Mesh(geometry, material);
    threeJs.scene.add(object);
    threeJs.addAnimationEvent((dt){
      object.rotation.y = object.rotation.y + 0.02;
      object.rotation.x = object.rotation.x + 0.01;
      mixer?.update(dt);
    });
  }
}
