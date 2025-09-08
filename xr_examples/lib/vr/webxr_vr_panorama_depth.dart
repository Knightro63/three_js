import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/three_js_xr.dart';

class WebXRVRPanoramaDepth extends StatefulWidget {
  const WebXRVRPanoramaDepth({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRVRPanoramaDepth> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: () async{setState(() {});},
      setup: setup,
      settings: three.Settings(
        xr: xrSetup
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
          if(threeJs.mounted) VRButton(threeJs: threeJs)
        ],
      ) 
    );
  }

  late three.Mesh mesh; 
  late three.Material material;
  late three.BufferGeometry geometry;
  
  final position = three.Vector3();
  final tangent = three.Vector3();
  final lookAt = three.Vector3();

  double velocity = 0;
  double progress = 0;
  int prevTime = DateTime.now().millisecond;

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    (threeJs.renderer?.xr as WebXRWorker).setReferenceSpaceType( 'local' );
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x101010 );

    final light = three.AmbientLight( 0xffffff, 3 );
    threeJs.scene.add( light );

    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.layers.enable( 1 );

    // Create the panoramic sphere geometry
    final panoSphereGeo = three.SphereGeometry( 6, 256, 256 );

    // Create the panoramic sphere material
    final panoSphereMat = three.MeshStandardMaterial.fromMap( {
      'side': three.BackSide,
      'displacementScale': - 4.0
    } );

    // Create the panoramic sphere mesh
    final sphere = three.Mesh( panoSphereGeo, panoSphereMat );

    // Load and assign the texture and depth map
    final loader = three.TextureLoader();

    await loader.fromAsset( 'assets/textures/kandao3.jpg').then(( texture ) {
      texture?.colorSpace = three.SRGBColorSpace;
      texture?.minFilter = three.NearestFilter;
      texture?.generateMipmaps = false;
      sphere.material?.map = texture;
    });

    await loader.fromAsset( 'assets/textures/kandao3_depthmap.jpg').then( ( depth ) {
      depth?.minFilter = three.NearestFilter;
      depth?.generateMipmaps = false;
      sphere.material?.displacementMap = depth;
    });

    threeJs.scene.add( sphere );
    
    threeJs.addAnimationEvent((dt){
      if (threeJs.renderer?.xr.isPresenting == false ) {
        final time = threeJs.clock.getElapsedTime();
        sphere.rotation.y += 0.001;
        sphere.position.x = math.sin( time ) * 0.2;
        sphere.position.z = math.cos( time ) * 0.2;
      }
    });
  }
}
