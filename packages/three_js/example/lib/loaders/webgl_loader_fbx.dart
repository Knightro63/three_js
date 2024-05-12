import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglLoaderFbx extends StatefulWidget {
  final String fileName;
  const WebglLoaderFbx({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderFbx> {
 late Demo demo;

  @override
  void initState() {
    demo = Demo(
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: DemoSettings(
        renderOptions: {
          "minFilter": three.LinearFilter,
          "magFilter": three.LinearFilter,
          "format": three.RGBAFormat,
          "samples": 4
        }
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    demo.dispose();
    controls.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  late three.Mesh mesh;
  three.AnimationMixer? mixer;
  late three.OrbitControls controls;

  Future<void> setup() async {
    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xcccccc);
    //demo.scene.fog = three.FogExp2(three.Color.fromHex32(0xcccccc), 0.002);

    demo.camera = three.PerspectiveCamera(60, demo.width / demo.height, 1, 2000);
    demo.camera.position.setValues( 100, 200, 300 );

    // controls

    controls = three.OrbitControls(demo.camera, demo.globalKey);

    controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 100;
    controls.maxDistance = 500;

    controls.maxPolarAngle = math.pi / 2;

    final hemiLight = three.HemisphereLight( 0xffffff, 0x444444 );
    hemiLight.position.setValues( 0, 200, 0 );
    demo.scene.add( hemiLight );

    final dirLight = three.DirectionalLight( 0xffffff );
    dirLight.position.setValues( 0, 200, 100 );
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 180;
    dirLight.shadow!.camera!.bottom = - 100;
    dirLight.shadow!.camera!.left = - 120;
    dirLight.shadow!.camera!.right = 120;
    dirLight.shadow!.camera!.near = 6;
    dirLight.shadow!.camera!.far = 400;
    demo.scene.add( dirLight );

    // scene.add( new three.CameraHelper( dirLight.shadow!.camera ) );

    // ground
    // final mesh = new three.Mesh( new three.PlaneGeometry( 2000, 2000 ), new three.MeshPhongMaterial( { "color": 0x999999, "depthWrite": false } ) );
    // mesh.rotation.x = - math.pi / 2;
    // mesh.receiveShadow = true;
    // scene.add( mesh );

    final grid = GridHelper( 2000, 20, three.Color(), three.Color());
    grid.material?.opacity = 0.2;
    grid.material?.transparent = true;
    demo.scene.add( grid );

    final textureLoader = three.TextureLoader();
    textureLoader.flipY = true;
    //final diffueTexture = await textureLoader.loadAsync("assets/models/fbx/model_tex_u1_v1_diffuse.jpg", null);
    //final normalTexture = await textureLoader.loadAsync("assets/models/fbx/model_tex_u1_v1_normal.jpg", null);

    // model
    final loader = three.FBXLoader(width: demo.width.toInt(), height: demo.height.toInt());
    final object = await loader.fromAsset( 'assets/models/fbx/SambaDancing.fbx');
    mixer = three.AnimationMixer(object!);

    final action = mixer!.clipAction( object.animations[ 1 ] );
    action!.play();

    object.traverse( ( child ) {
      if ( child is three.Mesh ) {
        child.castShadow = true;
        child.receiveShadow = true;
      }
    } );

    demo.scene.add( object );

    demo.addAnimationEvent((dt){
      controls.update();
      mixer?.update(dt);
    });
  }
}
