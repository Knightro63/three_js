import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglTonemapping extends StatefulWidget {
  const WebglTonemapping({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglTonemapping> {
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
    );
    super.initState();
  }
  @override
  void dispose() {
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
  late GuiWidget guiExposure;
  final Map<String,dynamic> params = {
    'exposure': 1.0,
    'toneMapping': 'AgX',
    'blurriness': 0.3,
    'intensity': 1.0,
  };

  final Map<String,dynamic> toneMappingOptions = {
    'None': three.NoToneMapping,
    'Linear': three.LinearToneMapping,
    'Reinhard': three.ReinhardToneMapping,
    'Cineon': three.CineonToneMapping,
    'ACESFilmic': three.ACESFilmicToneMapping,
    'AgX': three.AgXToneMapping,
    'Neutral': three.NeutralToneMapping,
    'Custom': three.CustomToneMapping
  };

  Future<void> setup() async {
    threeJs.renderer!.toneMapping = toneMappingOptions[ params['toneMapping'] ];
    threeJs.renderer!.toneMappingExposure = params['exposure'];

    // Set CustomToneMapping to Uncharted2
    // source: http://filmicworlds.com/blog/filmic-tonemapping-operators/

    three.shaderChunk['tonemapping_pars_fragment'] = three.shaderChunk['tonemapping_pars_fragment']!.replaceAll(
      'vec3 CustomToneMapping( vec3 color ) { return color; }',
      '''#define Uncharted2Helper( x ) max( ( ( x * ( 0.15 * x + 0.10 * 0.50 ) + 0.20 * 0.02 ) / ( x * ( 0.15 * x + 0.50 ) + 0.20 * 0.30 ) ) - 0.02 / 0.30, vec3( 0.0 ) )

      float toneMappingWhitePoint = 1.0;

      vec3 CustomToneMapping( vec3 color ) {
        color *= toneMappingExposure;
        return saturate( Uncharted2Helper( color ) / Uncharted2Helper( vec3( toneMappingWhitePoint ) ) );

      }'''
    );

    threeJs.scene = three.Scene();
    threeJs.scene.backgroundBlurriness = params['blurriness'];

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.25, 20 );
    threeJs.camera.position.setValues( - 1.8, 0.6, 2.7 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enableZoom = false;
    controls.enablePan = false;
    controls.target.setValues( 0, 0, - 0.2 );
    controls.update();

    final rgbeLoader = three.RGBELoader().setPath( 'assets/textures/equirectangular/' );
    final gltfLoader = three.GLTFLoader().setPath( 'assets/models/gltf/DamagedHelmet/glTF/' );

    final texture = await rgbeLoader.fromAsset( 'venice_sunset_1k.hdr' );
    final gltf = await gltfLoader.fromAsset( 'DamagedHelmet.gltf' );

    // environment

    texture.mapping = three.EquirectangularReflectionMapping;

    threeJs.scene.background = texture;
    threeJs.scene.environment = texture;

    // model
    final mesh = gltf?.scene.getObjectByName( 'node_damagedHelmet_-6514' );
    threeJs.scene.add( mesh );

    final toneMappingFolder = panel.addFolder( 'Tone Mapping' );

    toneMappingFolder.addDropDown( params, 'toneMapping', toneMappingOptions.keys.toList())..name = 'type'..onChange((_){
      updateGUI();
      threeJs.renderer?.toneMapping = toneMappingOptions[ params['toneMapping'] ];
    });

    guiExposure = toneMappingFolder.addSlider( params, 'exposure', 0, 2, 2/10)..onChange(( value ) {
      threeJs.renderer?.toneMappingExposure = value;
    });

    final backgroundFolder = panel.addFolder( 'Background' );

    backgroundFolder.addSlider( params, 'blurriness', 0, 1, 1/100 ).onChange(( value ) {
      threeJs.scene.backgroundBlurriness = value;
    });

    backgroundFolder.addSlider( params, 'intensity', 0, 1, 1/10 ).onChange(( value ) {
      threeJs.scene.backgroundIntensity = value;
    });

    updateGUI();
  }

  void updateGUI() {
    if ( params['toneMapping'] == 'None' ) {
      guiExposure.hide();
    } 
    else {
      guiExposure.show();
    }
  }
}
