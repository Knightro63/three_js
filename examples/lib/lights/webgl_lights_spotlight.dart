import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/spot_light_helper.dart';

class WebglLightsSpotlight extends StatefulWidget {
  
  const WebglLightsSpotlight({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLightsSpotlight> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui wg;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    wg = Gui((){setState(() {});});
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
        shadowMapType: three.PCFSoftShadowMap,
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 1
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
              child: wg.render(context)
            )
          )
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width/threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 7, 4, 1 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 2;
    controls.maxDistance = 10;
    controls.maxPolarAngle = math.pi / 2;
    controls.target.setValues( 0, 1, 0 );
    controls.update();

    final ambient = three.HemisphereLight( 0xffffff, 0x8d8d8d, 0.15 );
    threeJs.scene.add( ambient );

    final loader = three.TextureLoader().setPath( 'assets/textures/' );
    final filenames = [ 'disturb.jpg', 'colors.png', 'uv_grid_opengl.jpg' ];

    final Map<String,dynamic> textures = { 'none': null };

    for (int i = 0; i < filenames.length; i ++ ) {
      final filename = filenames[ i ];
      final texture = (await loader.fromAsset( filename ))!;
      texture.minFilter = three.LinearFilter;
      texture.magFilter = three.LinearFilter;
      texture.generateMipmaps = false;
      texture.colorSpace = three.SRGBColorSpace;

      textures[ filename ] = texture;
    }

    final spotLight = three.SpotLight( 0xffffff, 100);
    spotLight.position.setValues( 2.5, 5, 2.5 );
    spotLight.angle = math.pi / 6;
    spotLight.penumbra = 1;
    spotLight.decay = 2;
    spotLight.distance = 20;
    spotLight.map = textures[ 'disturb.jpg' ];

    spotLight.castShadow = true;
    spotLight.shadow?.mapSize.width = 1024;
    spotLight.shadow?.mapSize.height = 1024;
    spotLight.shadow?.camera?.near = 1;
    spotLight.shadow?.camera?.far = 10;
    spotLight.shadow?.focus = 1;
    spotLight.shadow?.bias = - 0.002;
    spotLight.shadow?.radius = 4;

    threeJs.scene.add( spotLight );

    final lightHelper = SpotLightHelper( spotLight );
    threeJs.scene.add( lightHelper );

    final plyGeometry = await three.PLYLoader().fromAsset( 'assets/models/ply/binary/Lucy100k.ply');
    plyGeometry?.scale( 0.0024, 0.0024, 0.0024 );
    plyGeometry?.computeVertexNormals();

    final mat= three.MeshPhongMaterial();

    final mesh1 = three.Mesh( plyGeometry, mat );
    mesh1.rotation.y = - math.pi / 2;
    mesh1.position.y = 0.8;
    mesh1.castShadow = true;
    mesh1.receiveShadow = true;
    threeJs.scene.add( mesh1 );
    
    final geometry = three.PlaneGeometry( 200, 200 );
    final material = three.MeshLambertMaterial.fromMap( { 'color': 0xbcbcbc } );

    final mesh = three.Mesh( geometry, material );
    mesh.position.setValues( 0, - 1, 0 );
    mesh.rotation.x = - math.pi / 2;
    mesh.receiveShadow = true;
    threeJs.scene.add( mesh );


    threeJs.addAnimationEvent((dt){
      final time = DateTime.now().millisecondsSinceEpoch / 3000;
      spotLight.position.x = math.cos( time ) * 2.5;
      spotLight.position.z = math.sin( time ) * 2.5;
      lightHelper.update();
    });

    final params = {
      'map': 'disturb.jpg',
      'color': spotLight.color!.getHex(),
      'intensity': spotLight.intensity,
      'distance': spotLight.distance,
      'angle': spotLight.angle,
      'penumbra': spotLight.penumbra,
      'decay': spotLight.decay,
      'focus': spotLight.shadow!.focus,
      'shadows': true
    };

    final gui = wg.addFolder('GUI')..open();

    gui.addDropDown( params, 'map', filenames ).onChange((val) {
      spotLight.map = textures[ val ];//val;
    });
    gui.addColor( params, 'color' ).onChange((val) {
      spotLight.color?.setFromHex32(val);
    } );
    gui.addSlider( params, 'intensity', 0, 500 )..step(1)..onChange((val) {
      spotLight.intensity = val;
    } );
    gui.addSlider( params, 'distance', 0, 20 )..step(1)..onChange((val) {
      spotLight.distance = val;
    } );
    gui.addSlider( params, 'angle', 0, math.pi / 3 )..step(0.1)..onChange((val) {
      spotLight.angle = val;
    } );
    gui.addSlider( params, 'penumbra', 0, 1 )..step(0.1)..onChange((val) {
      spotLight.penumbra = val;
    } );
    gui.addSlider( params, 'decay', 1, 2 )..step(0.1)..onChange((val) {
      spotLight.decay = val;
    } );
    gui.addSlider( params, 'focus', 0, 1 )..step(0.1)..onChange((val) {
      spotLight.shadow?.focus = val;
    } );
    gui.addButton( params, 'shadows' ).onChange((val) {
      threeJs.renderer?.shadowMap.enabled = val;
      threeJs.scene.traverse(( child ) {
        if (child.material != null) {
          child.material?.needsUpdate = true;
        }
      } );
    } );
  }
}
