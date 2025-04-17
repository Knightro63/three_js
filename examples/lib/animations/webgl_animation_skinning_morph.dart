import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglAnimationSkinningMorph extends StatefulWidget {
  
  const WebglAnimationSkinningMorph({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglAnimationSkinningMorph> {
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
        useOpenGL: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    controls.dispose();
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

  late three.OrbitControls controls;

  Future<void> setup() async{
    late three.AnimationMixer mixer;
    late three.Object3D model;

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.1, 1000);
    threeJs.camera.position.setValues(-5, 5, 15);
    threeJs.camera.lookAt(three.Vector3(0, 5, 0));

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xffffff);
    threeJs.scene.fog = three.Fog(0xa0a0a0, 10, 50);

    final hemiLight = three.HemisphereLight(0xffffff, 0x444444);
    hemiLight.position.setValues(0, 20, 0);
    threeJs.scene.add(hemiLight);

    final dirLight = three.DirectionalLight(0xffffff);
    dirLight.position.setValues(0, 20, 10);

    threeJs.scene.add(dirLight);

    // threeJs.scene.add( three.CameraHelper( dirLight.shadow.camera ) );

    final mesh = three.Mesh(three.PlaneGeometry(2000, 2000), three.MeshPhongMaterial.fromMap({"color": 0x999999}));
    mesh.rotation.x = -math.pi / 2;
    threeJs.scene.add(mesh);

    final grid = GridHelper(200, 40, 0x000000, 0x000000);
    grid.material?.opacity = 0.2;
    grid.material?.transparent = true;
    threeJs.scene.add(grid);

    final loader = three.GLTFLoader().setPath('assets/models/gltf/RobotExpressive/');
    final result = await loader.fromAsset('RobotExpressive.gltf');

    model = result!.scene;
    threeJs.scene.add(model);

    model.traverse((object) {
      if (object is three.Mesh){
        object.castShadow = true;
        object.frustumCulled = false;
      }
    });

    final skeleton = SkeletonHelper(model);
    skeleton.visible = true;
    threeJs.scene.add(skeleton);

    final animations = result.animations!;

    mixer = three.AnimationMixer(model);

    final idleAction = mixer.clipAction(animations[0]);
    // final walkAction = mixer.clipAction(animations[2]);
    // final runAction = mixer.clipAction(animations[1]);

    // final actions = [ idleAction, walkAction, runAction ];
    idleAction!.play();

    threeJs.addAnimationEvent((delta){
      controls.update();
      mixer.update(delta);
    });
  }
}
