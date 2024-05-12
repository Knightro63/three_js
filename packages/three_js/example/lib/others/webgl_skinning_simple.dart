import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglSkinningSimple extends StatefulWidget {
  final String fileName;
  const WebglSkinningSimple({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglSkinningSimple> {
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
    controls.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 1, 1000);
    demo.camera.position.setValues(18, 6, 18);

    controls = three.OrbitControls(demo.camera, demo.globalKey);

    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xa0a0a0);
    demo.scene.fog = three.Fog(three.Color.fromHex32(0xa0a0a0), 70, 100);

    // ground

    final geometry = three.PlaneGeometry(500, 500);
    final material =
        three.MeshPhongMaterial.fromMap({"color": 0x999999, "depthWrite": false});

    final ground = three.Mesh(geometry, material);
    ground.position.setValues(0, -5, 0);
    ground.rotation.x = -math.pi / 2;
    ground.receiveShadow = true;
    demo.scene.add(ground);

    final grid = GridHelper(500, 100, three.Color.fromHex32(0x000000), three.Color.fromHex32(0x000000));
    grid.position.y = -5;
    grid.material?.opacity = 0.2;
    grid.material?.transparent = true;
    demo.scene.add(grid);

    // lights

    final hemiLight = three.HemisphereLight(0xffffff, 0x444444, 0.6);
    hemiLight.position.setValues(0, 200, 0);
    demo.scene.add(hemiLight);

    final dirLight = three.DirectionalLight(0xffffff, 0.8);
    dirLight.position.setValues(0, 20, 10);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 18;
    dirLight.shadow!.camera!.bottom = -10;
    dirLight.shadow!.camera!.left = -12;
    dirLight.shadow!.camera!.right = 12;
    demo.scene.add(dirLight);

    demo.camera.lookAt(demo.scene.position);

    final loader = three.GLTFLoader().setPath('assets/models/gltf/');

    // final result = await loader.loadAsync( 'Parrot.gltf');
    final result = await loader.fromAsset('SimpleSkinning.gltf');

    three.console.info(" gltf load sucess result: $result  ");

    final object = result!.scene;

    object.traverse((child) {
      if (child is three.SkinnedMesh) child.castShadow = true;
    });

    final skeleton = SkeletonHelper(object);
    skeleton.visible = true;
    demo.scene.add(skeleton);

    final mixer = three.AnimationMixer(object);

    final clip = result.animations![0];
    if (clip != null) {
      final action = mixer.clipAction(clip);
      action?.play();
    }

    demo.scene.add(object);

    demo.addAnimationEvent((dt){
      mixer.update(dt);
      controls.update();
    });
  }
}
