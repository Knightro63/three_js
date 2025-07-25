import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMaterialsPhysicalTransmissionAlpha extends StatefulWidget {
  const WebglMaterialsPhysicalTransmissionAlpha({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglMaterialsPhysicalTransmissionAlpha> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui pannel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    pannel = Gui((){setState(() {});});
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,      settings: three.Settings(
        enableShadowMap: true,

        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: params['exposure']
      )
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
              child: pannel.render(context)
            )
          )
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late final three.Mesh mesh;
  late final three.Material material;

  final Map<String,dynamic> params = {
    'color': 0xffffff,
    'transmission': 1.0,
    'opacity': 1.0,
    'metalness': 0.0,
    'roughness': 0.0,
    'ior': 1.5,
    'thickness': 0.01,
    'attenuationColor': 0xffffff,
    'attenuationDistance': 1.0,
    'specularIntensity': 1.0,
    'specularColor': 0xffffff,
    'envMapIntensity': 1.0,
    'lightIntensity': 1.0,
    'exposure': 1.0
  };

  Future<void> setup() async {
    threeJs.renderer?.toneMappingExposure = params['exposure'];
    threeJs.scene = three.Scene();
    threeJs.scene.add( three.AmbientLight( 0xffffff ) );

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.position.setValues( - 5, 0.5, 0 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 5;
    controls.maxDistance = 20;
    controls.target.y = 0.5;
    controls.update();

    final hl = three.RGBELoader().setPath( 'assets/textures/equirectangular/' );
    final hdrEquirect = await hl.fromAsset( 'royal_esplanade_1k.hdr');

    hdrEquirect.mapping = three.EquirectangularReflectionMapping;
    final gltf = await three.GLTFLoader().setPath( 'assets/models/gltf/' ).fromAsset( 'DragonAttenuation.glb');
    gltf!.scene.traverse(( child ) {
      if (child is three.Mesh && child.material is three.MeshPhysicalMaterial ) {
        mesh = child;
        material = mesh.material!;

        final color = three.Color();

        params['color'] = (color..setFrom( mesh.material!.color )).getHex();
        params['roughness'] = mesh.material!.roughness;
        params['metalness'] = mesh.material!.metalness;

        params['ior'] = mesh.material!.ior;
        params['specularIntensity'] = mesh.material!.specularIntensity;
        //params['emissiveIntensity'] = mesh.material!.emissiveIntensity;

        params['transmission'] = mesh.material!.transmission;
        params['thickness'] = mesh.material!.thickness;
        params['attenuationColor'] = (color..setFrom( mesh.material!.attenuationColor!)).getHex();
        params['attenuationDistance'] = mesh.material!.attenuationDistance;
      }
    } );

    threeJs.scene.add( gltf.scene );
    //threeJs.scene.background = hdrEquirect;
    threeJs.scene.environment = hdrEquirect;

    final gui = pannel.addFolder('GUI')..open();

    gui.addColor( params, 'color' ).onChange((e) {
      material.color.setFromHex32( params['color'] );
    } );

    gui.addSlider( params, 'transmission', 0, 1, 0.01 ).onChange((e) {
      material.transmission = params['transmission'];
    } );

    gui.addSlider( params, 'opacity', 0, 1, 0.01 ).onChange((e) {
      material.opacity = params['opacity'];
      final transparent = params['opacity'] < 1;
      if ( transparent != material.transparent ) {
        material.transparent = transparent;
        material.needsUpdate = true;
      }
    } );

    gui.addSlider( params, 'metalness', 0, 1, 0.01 ).onChange((e) {
      material.metalness = params['metalness'];
    } );

    gui.addSlider( params, 'roughness', 0, 1, 0.01 ).onChange((e) {
      material.roughness = params['roughness'];
    });

    gui.addSlider( params, 'ior', 1, 2, 0.01 ).onChange((e) {
      material.ior = params['ior'];
    } );

    gui.addSlider( params, 'thickness', 0, 5, 0.01 ).onChange((e) {
      material.thickness = params['thickness'];
    } );

    gui.addColor( params, 'attenuationColor' )
    ..name ='At Color'
    ..onChange((e) {
      material.attenuationColor?.setFromHex32( params['attenuationColor'] );
    } );

    gui.addSlider( params, 'attenuationDistance', 0, 1, 0.01 )
    ..name = 'At Distance'
    ..onChange((e) {
        material.attenuationDistance = params['attenuationDistance'];
      } );

    gui.addSlider( params, 'specularIntensity', 0, 1, 0.01 )
    ..name = 'specular'
    ..onChange((e) {
      material.specularIntensity = params['specularIntensity'];
    } );

    gui.addColor( params, 'specularColor' ).onChange((e) {
      material.specularColor!.setFromHex32( params['specularColor'] );
    } );

    gui.addSlider( params, 'envMapIntensity', 0, 1, 0.01 )
    ..name = 'envMap'
    ..onChange((e) {
      material.envMapIntensity = params['envMapIntensity'];
    } );

    gui.addSlider( params, 'exposure', 0, 1, 0.01 ).onChange((e) {
      threeJs.renderer?.toneMappingExposure = params['exposure'];
    } );
  }
}
