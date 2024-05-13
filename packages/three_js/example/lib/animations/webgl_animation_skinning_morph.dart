import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglAnimationSkinningMorph extends StatefulWidget {
  final String fileName;
  const WebglAnimationSkinningMorph({super.key, required this.fileName});
  @override
  createState() => _State();
}

class _State extends State<WebglAnimationSkinningMorph> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    demo.dispose();
    controls.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  late three.OrbitControls controls;

  Future<void> setup() async{
    late three.AnimationMixer mixer;
    late three.Object3D model;

    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 0.1, 1000);
    demo.camera.position.setValues(-5, 5, 15);
    demo.camera.lookAt(three.Vector3(0, 5, 0));

    controls = three.OrbitControls(demo.camera, demo.globalKey);

    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xffffff);
    demo.scene.fog = three.Fog(three.Color.fromHex32(0xa0a0a0), 10, 50);

    final hemiLight = three.HemisphereLight(0xffffff, 0x444444);
    hemiLight.position.setValues(0, 20, 0);
    demo.scene.add(hemiLight);

    final dirLight = three.DirectionalLight(0xffffff);
    dirLight.position.setValues(0, 20, 10);

    demo.scene.add(dirLight);

    // scene.add( new three.CameraHelper( dirLight.shadow.camera ) );

    final mesh = three.Mesh(three.PlaneGeometry(2000, 2000), three.MeshPhongMaterial.fromMap({"color": 0x999999}));
    mesh.rotation.x = -math.pi / 2;
    demo.scene.add(mesh);

    final grid = GridHelper(200, 40, three.Color.fromHex32(0x000000), three.Color.fromHex32(0x000000));
    grid.material?.opacity = 0.2;
    grid.material?.transparent = true;
    demo.scene.add(grid);

    final loader = three.GLTFLoader().setPath('assets/models/gltf/RobotExpressive/');
    final result = await loader.fromAsset('RobotExpressive.gltf');

    model = result!.scene;
    demo.scene.add(model);

    model.traverse((object) {
      if (object is three.Mesh){
        object.castShadow = true;
        object.frustumCulled = false;
      }
    });

    final skeleton = SkeletonHelper(model);
    skeleton.visible = true;
    demo.scene.add(skeleton);

    final animations = result.animations!;

    mixer = three.AnimationMixer(model);

    final idleAction = mixer.clipAction(animations[0]);
    // final walkAction = mixer.clipAction(animations[2]);
    // final runAction = mixer.clipAction(animations[1]);

    // var actions = [ idleAction, walkAction, runAction ];
    idleAction!.play();

    demo.addAnimationEvent((delta){
      controls.update();
      mixer.update(delta);
    });
  }
}
