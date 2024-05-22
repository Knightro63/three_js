import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/spot_light_helper.dart';

class WebglLightsSpotlight extends StatefulWidget {
  final String fileName;
  const WebglLightsSpotlight({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglLightsSpotlight> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
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
      //texture.colorSpace = three.SRGBColorSpace;

      textures[ filename ] = texture;
    }

    final spotLight = three.SpotLight( 0xffffff, 0.9 );
    spotLight.position.setValues( 2.5, 5, 2.5 );
    spotLight.angle = math.pi / 6;
    spotLight.penumbra = 1;
    spotLight.decay = 2;
    spotLight.distance = 0;
    spotLight.map = textures[ 'disturb.jpg' ];

    spotLight.castShadow = true;
    spotLight.shadow?.mapSize.width = 1024;
    spotLight.shadow?.mapSize.height = 1024;
    spotLight.shadow?.camera?.near = 1;
    spotLight.shadow?.camera?.far = 10;
    spotLight.shadow?.focus = 1;
    threeJs.scene.add( spotLight );

    final lightHelper = SpotLightHelper( spotLight );
    threeJs.scene.add( lightHelper );

    //

    final geometry = three.PlaneGeometry( 200, 200 );
    final material = three.MeshLambertMaterial.fromMap( { 'color': 0xbcbcbc } );

    final mesh = three.Mesh( geometry, material );
    mesh.position.setValues( 0, - 1, 0 );
    mesh.rotation.x = - math.pi / 2;
    mesh.receiveShadow = true;
    threeJs.scene.add( mesh );

    //

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

    threeJs.renderer?.shadowMap.type = three.PCFSoftShadowMap;
    threeJs.renderer?.toneMapping = three.ACESFilmicToneMapping;
    threeJs.renderer?.toneMappingExposure = 1;

    threeJs.addAnimationEvent((dt){
      final time = DateTime.now().millisecondsSinceEpoch / 3000;

      spotLight.position.x = math.cos( time ) * 2.5;
      spotLight.position.z = math.sin( time ) * 2.5;

      lightHelper.update();
    });
  }
}
