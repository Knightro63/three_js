import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_objects/three_js_objects.dart';

class WebglLightprobeCubeCamera extends StatefulWidget {
  final String fileName;
  const WebglLightprobeCubeCamera({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglLightprobeCubeCamera> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        useSourceTexture: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    threeJs.dispose();
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
    threeJs.scene = three.Scene();

    // threeJs.camera
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 0, 0, 30 );

    final cubeRenderTarget = three.WebGLCubeRenderTarget( 256 );
    final cubeCamera = three.CubeCamera( 1, 1000, cubeRenderTarget );

    // controls
    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    //controls.addEventListener( 'change', render );
    controls.minDistance = 10;
    controls.maxDistance = 50;
    controls.enablePan = false;

    // probe
    final lightProbe = three.LightProbe();
    //threeJs.scene.add( lightProbe );

    // envmap
    List<String> genCubeUrls( prefix, postfix ) {
      return [
        prefix + 'px' + postfix, prefix + 'nx' + postfix,
        prefix + 'py' + postfix, prefix + 'ny' + postfix,
        prefix + 'pz' + postfix, prefix + 'nz' + postfix
      ];
    };

    final urls = genCubeUrls( 'assets/textures/cube/pisa/', '.png' );

    three.CubeTextureLoader().fromAssetList(urls).then(( cubeTexture ) {
      threeJs.scene.background = cubeTexture;
      cubeCamera.update( threeJs.renderer!, threeJs.scene );
      lightProbe.copy( LightProbeGenerator.fromCubeRenderTarget( threeJs.renderer!, cubeRenderTarget ) );
      threeJs.scene.add( LightProbeHelper( lightProbe, 5 ) );
    });

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
