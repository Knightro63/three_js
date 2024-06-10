import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderUsdz extends StatefulWidget {
  final String fileName;
  const WebglLoaderUsdz({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderUsdz> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 2.0
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

  late final three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width/threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 0.75, - 1.5 );
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xffffff);

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 1;
    controls.maxDistance = 8;
    // controls.target.y = 15;

    final three.DataTexture rgbeLoader = await three.RGBELoader().setPath( 'assets/textures/equirectangular/' ).fromAsset('venice_sunset_1k.hdr');
    final three.Group usdzLoader = await three.USDZLoader().setPath( 'assets/models/usdz/' ).fromAsset('saeukkang.usdz');

    rgbeLoader.mapping = three.EquirectangularReflectionMapping;

    threeJs.scene.background = rgbeLoader;
    // threeJs.scene.backgroundBlurriness = 0.5;
    //threeJs.scene.environment = rgbeLoader;

    usdzLoader.position.y = 0.25;
    usdzLoader.position.z = - 0.25;
    threeJs.scene.add( usdzLoader );

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
