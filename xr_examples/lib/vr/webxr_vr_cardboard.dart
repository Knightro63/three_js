import 'dart:async';
import 'package:examples/src/files_json.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/three_js_xr.dart';

class WebXRVRCardboard extends StatefulWidget {
  const WebXRVRCardboard({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRVRCardboard> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: () async{setState(() {});},
      setup: setup,
      settings: three.Settings(
        xr: xrSetup
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
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          if(threeJs.mounted) VRButton(renderer: threeJs.renderer)
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  WebXRWorker xrSetup(three.AngleRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    (threeJs.renderer?.xr as WebXRWorker).setUpOptions(XROptions(
      width: threeJs.width,
      height: threeJs.height,
      dpr: threeJs.dpr,
    ));
    (threeJs.renderer?.xr as WebXRWorker).setReferenceSpaceType( 'local' );

    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.1, 20);
    if(!actualVR) threeJs.camera.position.z = 2.5;
    threeJs.camera.layers.enable( 1 );

    threeJs.scene.background = three.Color.fromHex32(0x000000);

    final ambientLight = three.AmbientLight(0xcccccc, 3);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    await loader('assets/cardboard/CubeRoom.obj', 'assets/cardboard/CubeRoom_BakedDiffuse.png');
    await loader('assets/cardboard/Icosahedron.obj', 'assets/cardboard/Icosahedron_Pink_BakedDiffuse.png');
    await loader('assets/cardboard/QuadSphere.obj', 'assets/cardboard/QuadSphere_Pink_BakedDiffuse.png');
    await loader('assets/cardboard/TriSphere.obj', 'assets/cardboard/TriSphere_Pink_BakedDiffuse.png');

    threeJs.customRenderer = (threeJs.renderer?.xr as WebXRWorker).render;
    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }

  Future<void> loader(String obj, String text) async{
    late three.Object3D object;
    late three.Texture texture;
    final textureLoader = three.TextureLoader(flipY: true);
    texture = (await textureLoader.fromAsset(text))!;

    texture.magFilter = three.LinearFilter;
    texture.minFilter = three.LinearMipmapLinearFilter;
    texture.generateMipmaps = true;
    texture.needsUpdate = true;
    texture.flipY = true; // this flipY is only for web

    final loader = three.OBJLoader();
    object = (await loader.fromAsset(obj))!;

    object.traverse((child) {
      if (child is three.Mesh) {
        child.material?.map = texture;
      }
    });

    object.position.y = - 2;
    threeJs.scene.add(object);
  }
}
