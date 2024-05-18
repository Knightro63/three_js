import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglAnimationSkinningAdditiveBlending extends StatefulWidget {
  final String fileName;
  const WebglAnimationSkinningAdditiveBlending({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglAnimationSkinningAdditiveBlending> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        outputEncoding: three.sRGBEncoding
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    controls.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.AnimationMixer mixer;
  late three.OrbitControls controls;
  late three.Object3D model;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 100);
    threeJs.camera.position.setValues(-1, 3, 3);
    threeJs.camera.lookAt(three.Vector3(0, 1, 0));

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xa0a0a0);
    threeJs.scene.fog = three.Fog(0xa0a0a0, 10, 50);

    final hemiLight = three.HemisphereLight(0xffffff, 0x444444,2);
    hemiLight.position.setValues(0, 20, 0);
    threeJs.scene.add(hemiLight);

    final dirLight = three.DirectionalLight(0xffffff);
    dirLight.position.setValues(3, 10, 10);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 2;
    dirLight.shadow!.camera!.bottom = -2;
    dirLight.shadow!.camera!.left = -2;
    dirLight.shadow!.camera!.right = 2;
    dirLight.shadow!.camera!.near = 0.1;
    dirLight.shadow!.camera!.far = 40;
    threeJs.scene.add(dirLight);

    final mesh = three.Mesh(three.PlaneGeometry(100, 100),
        three.MeshPhongMaterial.fromMap({"color": 0x999999, "depthWrite": false}));
    mesh.rotation.x = -math.pi / 2;
    mesh.receiveShadow = true;
    threeJs.scene.add(mesh);

    final loader = three.GLTFLoader();
    final gltf = await loader.fromAsset('assets/models/gltf/Xbot.gltf');

    model = gltf!.scene;
    threeJs.scene.add(model);

    model.traverse((object) {
      if (object is three.Mesh) {
        object.castShadow = true;
      }
    });

    final skeleton = SkeletonHelper(model);
    skeleton.visible = true;
    threeJs.scene.add(skeleton);

    final animations = gltf.animations!;
    mixer = three.AnimationMixer(model);

    //final idleAction = mixer.clipAction(animations[0]);
    final walkAction = mixer.clipAction(animations[3]);
    //final runAction = mixer.clipAction(animations[1]);

    // final actions = [ idleAction, walkAction, runAction ];
    walkAction!.play();
    // activateAllActions();

    threeJs.addAnimationEvent((dt){
      controls.update();
      mixer.update(dt);
    });
  }
}
