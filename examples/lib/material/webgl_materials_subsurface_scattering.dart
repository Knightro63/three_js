import 'dart:async';
import 'package:example/material/subsurface_scattering_shader.dart';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMaterialsSubsurfaceScattering extends StatefulWidget {
  const WebglMaterialsSubsurfaceScattering({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglMaterialsSubsurfaceScattering> {
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

  late final three.OrbitControls controls;
  three.Object3D? model;

  Future<void> setup() async {
    threeJs.camera =three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 5000 );
    threeJs.camera.position.setValues( 0.0, 300, 400 * 4 );

    threeJs.scene =three.Scene();

    // Lights

    threeJs.scene.add(three.AmbientLight( 0xc1c1c1 ) );

    final directionalLight =three.DirectionalLight( 0xffffff, 0.03 );
    directionalLight.position.setValues( 0.0, 0.5, 0.5 ).normalize();
    threeJs.scene.add( directionalLight );

    final pointLight1 =three.Mesh(three.SphereGeometry( 4, 8, 8 ),three.MeshBasicMaterial.fromMap( { 'color': 0xc1c1c1 } ) );
    pointLight1.add(three.PointLight( 0xc1c1c1, 4.0, 300, 0 ) );
    threeJs.scene.add( pointLight1 );
    pointLight1.position.x = 0;
    pointLight1.position.y = - 50;
    pointLight1.position.z = 350;

    final pointLight2 =three.Mesh(three.SphereGeometry( 4, 8, 8 ),three.MeshBasicMaterial.fromMap( { 'color': 0xc1c100 } ) );
    pointLight2.add(three.PointLight( 0xc1c100, 0.75, 500, 0 ) );
    threeJs.scene.add( pointLight2 );
    pointLight2.position.x = - 100;
    pointLight2.position.y = 20;
    pointLight2.position.z = - 260;

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 500;
    controls.maxDistance = 3000;

    await initMaterial();

    threeJs.addAnimationEvent((dt){
      controls.update();
      if ( model != null) model!.rotation.y = DateTime.now().millisecondsSinceEpoch / 5000;
    });
  }

  Future<void> initMaterial() async{
    final loader = three.TextureLoader();
    final imgTexture = await loader.fromAsset('assets/models/fbx/white.jpg' );
    imgTexture?.colorSpace = three.SRGBColorSpace;

    final thicknessTexture = loader.fromAsset( 'assets/models/fbx/bunny_thickness.jpg' );
    imgTexture?.wrapS = imgTexture.wrapT = three.RepeatWrapping;

    final shader = subsurfaceScatteringShader;
    final uniforms = three.UniformsUtils.clone( shader['uniforms'] );

    uniforms[ 'map' ]['value'] = imgTexture;

    uniforms[ 'diffuse' ]['value'] = three.Vector3( 1.0, 0.2, 0.2 );
    uniforms[ 'shininess' ]['value'] = 500;

    uniforms[ 'thicknessMap' ]['value'] = thicknessTexture;
    uniforms[ 'thicknessColor' ]['value'] = three.Vector3( 0.5, 0.3, 0.0 );
    uniforms[ 'thicknessDistortion' ]['value'] = 0.1;
    uniforms[ 'thicknessAmbient' ]['value'] = 0.4;
    uniforms[ 'thicknessAttenuation' ]['value'] = 0.8;
    uniforms[ 'thicknessPower' ]['value'] = 2.0;
    uniforms[ 'thicknessScale' ]['value'] = 0.1;

    final material = three.ShaderMaterial.fromMap( {
      'uniforms': uniforms,
      'vertexShader': shader['vertexShader'],
      'fragmentShader': shader['fragmentShader'],
      'lights': true
    } );

    // LOADER
    // final loaderFBX = three.FBXLoader();
    // loaderFBX.fromAsset( 'assets/models/fbx/stanford-bunny.fbx').then(( object ) {
    //   model = object?.children[ 0 ];
    //   model?.position.setValues( 0, 0, 10 );
    //   model?.scale.setScalar( 1 );
    //   model?.material = material;
    //   threeJs.scene.add( model );
    // });

    model = three.Mesh(three.BoxGeometry(500,500,500),material);//object?.children[ 0 ];
    model?.position.setValues( 0, 0, 10 );
    model?.scale.setScalar( 1 );
    threeJs.scene.add( model );
    initGUI( material.uniforms );
  }

  void initGUI( uniforms ) {

    final gui = panel.addFolder('Thickness Control')..open();//new GUI( { title: 'Thickness Control' } );

    final thicknessControls = {
      'distortion': uniforms[ 'thicknessDistortion' ]['value'],
      'ambient': uniforms[ 'thicknessAmbient' ]['value'],
      'attenuation': uniforms[ 'thicknessAttenuation' ]['value'],
      'power': uniforms[ 'thicknessPower' ]['value'],
      'scale': uniforms[ 'thicknessScale' ]['value']
    };

    gui.addSlider( thicknessControls, 'distortion',0.01,1)..step( 0.01 )..onChange( (v) {
      uniforms[ 'thicknessDistortion' ]['value'] = v;
      three.console.info( 'distortion' );
    });

    gui.addSlider( thicknessControls, 'ambient',0.01,5.0 )..step( 0.05 )..onChange( (v) {
      uniforms[ 'thicknessAmbient' ]['value'] = v;
    } );

    gui.addSlider( thicknessControls, 'attenuation',0.01,5 )..step( 0.05 )..onChange( (v) {
      uniforms[ 'thicknessAttenuation' ]['value'] = v;
    } );

    gui.addSlider( thicknessControls, 'power',0.01,16 )..step( 0.1 )..onChange( (v) {
      uniforms[ 'thicknessPower' ]['value'] = v;
    } );

    gui.addSlider( thicknessControls, 'scale',0.01,50 )..step( 0.1 )..onChange( (v) {
      uniforms[ 'thicknessScale' ]['value'] = v;
    } );
  }
}
