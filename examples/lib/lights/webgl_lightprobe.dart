import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:example/src/statistics.dart';
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_objects/three_js_objects.dart';

class WebglLightprobe extends StatefulWidget {
  
  const WebglLightprobe({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLightprobe> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
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
        toneMapping: three.NoToneMapping,
        useOpenGL: useOpenGL
      )
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
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: panel.render()
            )
          )
        ],
      ) 
    );
  }

  late three.OrbitControls controls;
  late final three.Mesh mesh;
  final api = {
    'lightProbeIntensity': 1.0,
    'directionalLightIntensity': 0.6,
    'envMapIntensity': 1.0
  };
  Future<void> setup() async {
    threeJs.scene = three.Scene();

    // threeJs.camera
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 0, 0, 30 );

    // controls
    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    //controls.addEventListener( 'change', render );
    controls.minDistance = 10;
    controls.maxDistance = 50;
    controls.enablePan = false;

    // probe
    final lightProbe = three.LightProbe();
    threeJs.scene.add( lightProbe );

    final directionalLight = three.DirectionalLight( 0xffffff, api['directionalLightIntensity'] );
    directionalLight.position.setValues( 10, 10, 10 );
    threeJs.scene.add( directionalLight );

    // envmap
    List<String> genCubeUrls( prefix, postfix ) {
      return [
        prefix + 'px' + postfix, prefix + 'nx' + postfix,
        '${prefix}py$postfix', '${prefix}ny$postfix',
        prefix + 'pz' + postfix, prefix + 'nz' + postfix
      ];
    }

    final urls = genCubeUrls( 'assets/textures/cube/pisa/', '.png' );

    await three.CubeTextureLoader().fromAssetList(urls).then(( cubeTexture ) {
      threeJs.scene.background = cubeTexture;
      lightProbe.copy( LightProbeGenerator.fromCubeTexture( cubeTexture! ) );
      lightProbe.intensity = api['lightProbeIntensity']!;
      lightProbe.position.setValues( - 10, 0, 0 ); // position not used in scene lighting calculations (helper honors the position, however)

      final geometry = three.SphereGeometry( 5, 64, 32 );
      //const geometry = new THREE.TorusKnotGeometry( 4, 1.5, 256, 32, 2, 3 );

      final material = three.MeshStandardMaterial.fromMap( {
        'color': 0xffffff,
        'metalness': 0,
        'roughness': 0,
        'envMap': cubeTexture,
        'envMapIntensity': api['envMapIntensity'],
      } );

      // mesh
      mesh = three.Mesh( geometry, material );
      threeJs.scene.add( mesh );

      // helper
      final helper = LightProbeHelper( lightProbe, 1 );
      threeJs.scene.add( helper );
    });

    threeJs.addAnimationEvent((dt){
      controls.update();
    });

    final gui = panel.addFolder('Intensity')..open();

    gui.addSlider( api, 'lightProbeIntensity', 0, 1, 0.02 )
      ..name = 'probe'
      ..onChange((e) {
        lightProbe.intensity = api['lightProbeIntensity']!;
      } );

    gui.addSlider( api, 'directionalLightIntensity', 0, 1, 0.02 )
      ..name = 'direction'
      ..onChange((e) {
        directionalLight.intensity = api['directionalLightIntensity']!;
      } );

    gui.addSlider( api, 'envMapIntensity', 0, 1, 0.02 )
      ..name = 'envMap'
      ..onChange((e) {
        mesh.material?.envMapIntensity = api['envMapIntensity'];
      } );
  }
}
