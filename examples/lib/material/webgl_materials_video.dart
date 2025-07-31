import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_postprocessing/post/effect_composer.dart';
// import 'package:three_js_postprocessing/post/bloom_pass.dart';
// import 'package:three_js_postprocessing/post/outpass.dart';
import 'package:three_js_postprocessing/post/render_pass.dart';
import 'package:three_js_video_texture/three_js_video_texture.dart';

class WebglMaterialsVideo extends StatefulWidget {
  const WebglMaterialsVideo({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglMaterialsVideo> {
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
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        autoClear: false,
        //useSourceTexture: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    texture.dispose();
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
          Statistics(data: data)
        ],
      ) 
    );
  }

  final meshes = [];
  final materials = [];
  late final three.VideoTexture texture;
  double mouseX = 0;
  double mouseY = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.z = 500;

    threeJs.scene = three.Scene();

    final light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 0.5, 1, 1 ).normalize();
    threeJs.scene.add( light );

    texture = VideoTextureWorker.fromOptions(
      three.VideoTextureOptions(
        asset: 'assets/textures/sintel.mp4',
      )
    );
    texture.colorSpace = three.SRGBColorSpace;

    texture.play();
    // texture.video.addEventListener( 'play', () {
    //   //this.currentTime = 3;
    // } );
    int i, j, ox, oy;

    const xgrid = 20;
    const ygrid = 10;

    const ux = 1 / xgrid;
    const uy = 1 / ygrid;

    const xsize = 480 / xgrid;
    const ysize = 204 / ygrid;

    final parameters = { 'color': 0xffffff, 'map': texture };

    for ( i = 0; i < xgrid; i ++ ) {
      for ( j = 0; j < ygrid; j ++ ) {
        ox = i;
        oy = j;

        final geometry = three.BoxGeometry( xsize, ysize, xsize );

        changeUVs( geometry, ux, uy, ox, oy );

        materials.add(three.MeshLambertMaterial.fromMap( parameters ));

        final three.MeshLambertMaterial material = materials.last;

        material.userData['hue'] = i / xgrid;
        material.userData['saturation'] = 1 - j / ygrid;

        material.color.setHSL( material.userData['hue'], material.userData['saturation'], 0.5 );

        final mesh = three.Mesh( geometry, material );

        mesh.position.x = ( i - xgrid / 2 ) * xsize;
        mesh.position.y = ( j - ygrid / 2 ) * ysize;
        mesh.position.z = 0;

        mesh.scale.x = mesh.scale.y = mesh.scale.z = 1;

        threeJs.scene.add( mesh );

        mesh.userData['dx'] = 0.001 * ( 0.5 - math.Random().nextDouble() );
        mesh.userData['dy'] = 0.001 * ( 0.5 - math.Random().nextDouble() );

        meshes.add(mesh);
      }
    }

    threeJs.domElement.addEventListener(three.PeripheralType.pointermove, onDocumentMouseMove );

    final renderPass = RenderPass( threeJs.scene, threeJs.camera );
    // final bloomPass = BloomPass( 1.3 );
    // final outputPass = OutputPass();
    final composer = EffectComposer( threeJs.renderer!, threeJs.renderTarget );

    composer.addPass( renderPass );
    //composer.addPass( bloomPass );
    //composer.addPass( outputPass );

    int counter = 0;

    threeJs.postProcessor = ([dt]){
      final time = DateTime.now().millisecondsSinceEpoch * 0.00005;

      threeJs.camera.position.x += ( mouseX - threeJs.camera.position.x ) * 0.05;
      threeJs.camera.position.y += ( - mouseY - threeJs.camera.position.y ) * 0.05;

      threeJs.camera.lookAt( threeJs.scene.position );

      for (int i = 0; i < meshes.length; i ++ ) {
        final three.MeshLambertMaterial material = materials[ i ];
        final h = ( 360 * ( material.userData['hue'] + time ) % 360 ) / 360;
        material.color.setHSL( h, material.userData['saturation'], 0.5 );
      }

      if ( counter % 1000 > 200 ) {
        for (int i = 0; i < meshes.length; i ++ ) {
          final three.Mesh mesh = meshes[ i ];

          mesh.rotation.x += 10 * mesh.userData['dx'];
          mesh.rotation.y += 10 * mesh.userData['dy'];

          mesh.position.x -= 150 * mesh.userData['dx'];
          mesh.position.y += 150 * mesh.userData['dy'];
          mesh.position.z += 300 * mesh.userData['dx'];
        }
      }

      if ( counter % 1000 == 0 ) {
        for (int i = 0; i < meshes.length; i ++ ) {
          final three.Mesh mesh = meshes[ i ];
          mesh.userData['dx'] *= - 1;
          mesh.userData['dy'] *= - 1;
        }
      }

      counter ++;

      threeJs.renderer!.setRenderTarget(null);
      composer.render(dt);
      threeJs.renderer!.render(threeJs.scene, threeJs.camera);
    };
  }

  void onDocumentMouseMove( event ) {
    mouseX = ( event.clientX - threeJs.width/2 );
    mouseY = ( event.clientY - threeJs.height/2 ) * 0.3;
  }

  void changeUVs(three.BufferGeometry geometry, unitx, unity, offsetx, offsety ) {
    final uvs = geometry.attributes['uv'].array;
    for (int i = 0; i < uvs.length; i += 2 ) {
      uvs[ i ] = ( uvs[ i ] + offsetx ) * unitx;
      uvs[ i + 1 ] = ( uvs[ i + 1 ] + offsety ) * unity;
    }
  }
}