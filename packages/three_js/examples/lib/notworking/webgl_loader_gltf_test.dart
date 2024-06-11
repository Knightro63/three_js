import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderGltfTest extends StatefulWidget {
  final String fileName;
  const WebglLoaderGltfTest({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderGltfTest> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      // postProcessor: ([dt]){
      //   threeJs.renderer!.clear(true, true, true);
      // },
      settings: three.Settings(
        clearAlpha: 0,
        clearColor: 0xffffff
      ),
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    controls.dispose();
    three.loading.clear();
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

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.25, 20);
    threeJs.camera.position.setValues(-1.8, 0.6, 2.7);
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    // threeJs.scene

    threeJs.scene = three.Scene();

    var ambientLight = three.AmbientLight(0xcccccc, 0.4);
    threeJs.scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffff, 0.8);

    pointLight.position.setValues(0, 0, 18);

    threeJs.scene.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    final _loader = three.RGBELoader();
    _loader.setPath('assets/textures/equirectangular/');
    final _hdrTexture = await _loader.fromAsset('royal_esplanade_1k.hdr');

    _hdrTexture?.mapping = three.EquirectangularReflectionMapping;

    // print("_hdrTexture 1: ${_hdrTexture} ");
    // print("_hdrTexture 2: ${_hdrTexture.image} ");
    // print("_hdrTexture 3: ${_hdrTexture.image.data} ");
    // print("_hdrTexture 3: ${_hdrTexture.image.data.toDartList()} ");

    threeJs.scene.background = _hdrTexture;
    threeJs.scene.environment = _hdrTexture;

    var textureLoader = three.TextureLoader();
    final texture = (await textureLoader.fromAsset('assets/textures/uv_grid_directx.jpg'))!;

    texture.magFilter = three.LinearFilter;
    texture.minFilter = three.LinearMipmapLinearFilter;
    texture.generateMipmaps = true;
    texture.needsUpdate = true;

    // var loader = three.GLTFLoader( null ).setPath( 'assets/models/gltf/DamagedHelmet/glTF/' );
    final loader = three.GLTFLoader().setPath('assets/models/gltf/test/');
    final result = await loader.fromAsset('animate7.gltf');

    threeJs.scene.add(result!.scene);
  }
}
