import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglSkinningSimple extends StatefulWidget {
  
  const WebglSkinningSimple({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglSkinningSimple> {
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
      settings: three.Settings(
        useSourceTexture: true
      ),
      onSetupComplete: (){setState(() {});},
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
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

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 1000);
    threeJs.camera.position.setValues(18, 6, 18);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xa0a0a0);
    threeJs.scene.fog = three.Fog(0xa0a0a0, 70, 100);

    // ground

    final geometry = three.PlaneGeometry(500, 500);
    final material = three.MeshPhongMaterial.fromMap({"color": 0x999999, "depthWrite": false});

    final ground = three.Mesh(geometry, material);
    ground.position.setValues(0, -5, 0);
    ground.rotation.x = -math.pi / 2;
    ground.receiveShadow = true;
    threeJs.scene.add(ground);

    final grid = GridHelper(500, 100, 0x000000, 0x000000);
    grid.position.y = -5;
    grid.material?.opacity = 0.2;
    grid.material?.transparent = true;
    threeJs.scene.add(grid);

    final hemiLight = three.HemisphereLight(0xffffff, 0x444444, 0.6);
    hemiLight.position.setValues(0, 200, 0);
    threeJs.scene.add(hemiLight);

    final dirLight = three.DirectionalLight(0xffffff, 0.8);
    dirLight.position.setValues(0, 20, 10);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 18;
    dirLight.shadow!.camera!.bottom = -10;
    dirLight.shadow!.camera!.left = -12;
    dirLight.shadow!.camera!.right = 12;
    threeJs.scene.add(dirLight);

    threeJs.camera.lookAt(threeJs.scene.position);

    final loader = three.GLTFLoader().setPath('assets/models/gltf/');

    //final result = await loader.fromAsset( 'Parrot.gltf');
    final result = await loader.fromAsset('SimpleSkinning.gltf');

    three.console.info(" gltf load sucess result: $result  ");

    final object = result!.scene;

    object.traverse((child) {
      if (child is three.SkinnedMesh) child.castShadow = true;
    });

    final skeleton = SkeletonHelper(object);
    skeleton.visible = true;
    threeJs.scene.add(skeleton);

    final mixer = three.AnimationMixer(object);

    final clip = result.animations![0];
    if (clip != null) {
      final action = mixer.clipAction(clip);
      action?.play();
    }

    threeJs.scene.add(object);

    threeJs.addAnimationEvent((dt){
      mixer.update(dt);
      controls.update();
    });
  }
}
