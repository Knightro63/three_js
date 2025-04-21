import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_objects/sky/sky.dart';

class WebglShaderSky extends StatefulWidget {
  const WebglShaderSky({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglShaderSky> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late Gui panel;

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
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 0.5,
        useOpenGL: useOpenGL
      )
    );
    super.initState();
  }
  
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
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
              child: panel.render(context)
            )
          )
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late final Sky sky;
  final three.Vector3 sun = three.Vector3();

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 100, 2000000 );
    threeJs.camera.position.setValues( 0, 100, 2000 );

    threeJs.scene = three.Scene();

    final helper = GridHelper( 10000, 2, 0xffffff, 0xffffff );
    threeJs.scene.add( helper );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    //controls.maxPolarAngle = Math.PI / 2;
    controls.enableZoom = false;
    controls.enablePan = false;

    threeJs.addAnimationEvent((dt){
      controls.update();
    });

    initSky();
  }

	initSky() {
    // Add Sky
    sky = Sky.create();
    sky.scale.setScalar( 450000 );
    threeJs.scene.add( sky );

    /// GUI

    final Map<String,dynamic>effectController = {
      'turbidity': 10.0,
      'rayleigh': 3.0,
      'mieCo': 0.005,
      'mieDir': 0.7,
      'elevation': 2.0,
      'azimuth': 180.0,
      'exposure': threeJs.renderer?.toneMappingExposure
    };

    void guiChanged(r) {
      final uniforms = sky.material!.uniforms;
      uniforms[ 'turbidity' ]['value'] = effectController['turbidity'];
      uniforms[ 'rayleigh' ]['value'] = effectController['rayleigh'];
      uniforms[ 'mieCoefficient' ]['value'] = effectController['mieCo'];
      uniforms[ 'mieDirectionalG' ]['value'] = effectController['mieDir'];

      final phi = three.MathUtils.degToRad( 90 - effectController['elevation'] as double );
      final theta = three.MathUtils.degToRad( effectController['azimuth'] );

      sun.setFromSphericalCoords( 1, phi, theta );

      uniforms['sunPosition']['value'].setFrom( sun );

      threeJs.renderer?.toneMappingExposure = effectController['exposure'];
    }

    final gui = panel.addFolder('GUI')..open();

    gui.addSlider( effectController, 'turbidity', 0.0, 20.0, 0.1 ).onChange( guiChanged );
    gui.addSlider( effectController, 'rayleigh', 0.0, 4, 0.001 ).onChange( guiChanged );
    gui.addSlider( effectController, 'mieCo', 0.0, 0.1, 0.001 ).onChange( guiChanged );
    gui.addSlider( effectController, 'mieDir', 0.0, 1, 0.001 ).onChange( guiChanged );
    gui.addSlider( effectController, 'elevation', 0, 90, 0.1 ).onChange( guiChanged );
    gui.addSlider( effectController, 'azimuth', - 180, 180, 0.1 ).onChange( guiChanged );
    gui.addSlider( effectController, 'exposure', 0, 1, 0.0001 ).onChange( guiChanged );

    guiChanged('');
	}
}
