import 'dart:async';
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderGltf extends StatefulWidget {
  final String fileName;
  const WebglLoaderGltf({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderGltf> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup,
      rendererUpdate: (){
        demo.renderer!.clear(true, true, true);
      },
      settings: DemoSettings(
        clearAlpha: 0,
        clearColor: 0xffffff
      ),
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
    demo.scene = three.Scene();

    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 0.25, 20);
    demo.camera.position.setValues( - 0, 0, 2.7 );
    demo.camera.lookAt(demo.scene.position);

    controls = three.OrbitControls(demo.camera, demo.globalKey);

    three.RGBELoader rgbeLoader = three.RGBELoader();
    rgbeLoader.setPath('assets/textures/equirectangular/');
    final hdrTexture = await rgbeLoader.fromAsset('royal_esplanade_1k.hdr');
    hdrTexture?.mapping = three.EquirectangularReflectionMapping;

    demo.scene.background = hdrTexture;
    demo.scene.environment = hdrTexture;

    demo.scene.add( three.AmbientLight( 0xffffff ) );

    three.GLTFLoader loader = three.GLTFLoader()
        .setPath('assets/models/gltf/DamagedHelmet/glTF/');

    final result = await loader.fromAsset('DamagedHelmet.gltf');

    three.console.info(" gltf load sucess result: $result  ");

    final object = result!.scene;

    // final geometry = new three.PlaneGeometry(2, 2);
    // final material = new three.MeshBasicMaterial();

    // object.traverse( ( child ) {
    //   if ( child is three.Mesh ) {
    //     material.map = child.material.map;
    //   }
    // } );

    // final mesh = new three.Mesh(geometry, material);
    // scene.add(mesh);

    // object.traverse( ( child ) {
    //   if ( child.isMesh ) {
    // child.material.map = texture;
    //   }
    // } );

    demo.scene.add(object);
  
    demo.addAnimationEvent((dt){
      controls.update();
    });
  }
}
