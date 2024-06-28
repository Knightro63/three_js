import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

class WebglAnimationSkinningIk extends StatefulWidget {
  final String fileName;
  const WebglAnimationSkinningIk({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglAnimationSkinningIk> {
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

  Future<void> setup() async {
    final conf = {
      'followSphere': false,
      'turnHead': true,
      'ik_solver': true,
      'update': updateIK
    };

    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.FogExp2( 0xffffff, .17 );
    threeJs.scene.background = three.Color.fromHex32( 0xffffff );

    threeJs.camera = three.PerspectiveCamera( 55, threeJs.width/threeJs.height, 0.001, 5000 );
    threeJs.camera.position.setValues( 0.9728517749133652, 1.1044765132727201, 0.7316689528482836 );
    threeJs.camera.lookAt( threeJs.scene.position );

    final ambientLight = three.AmbientLight( 0xffffff, 8 ); // soft white light
    threeJs.scene.add( ambientLight );

    final dracoLoader = DRACOLoader();
    dracoLoader.setDecoderPath( 'jsm/libs/draco/' );
    final gltfLoader = three.GLTFLoader();
    gltfLoader.setDRACOLoader( dracoLoader );

    final gltf = await gltfLoader.fromAsset( 'models/gltf/kira.glb' );
    gltf!.scene.traverse( (n) {

      if ( n.name == 'head' ) OOI.head = n;
      if ( n.name == 'lowerarm_l' ) OOI.lowerarm_l = n;
      if ( n.name == 'Upperarm_l' ) OOI.Upperarm_l = n;
      if ( n.name == 'hand_l' ) OOI.hand_l = n;
      if ( n.name == 'target_hand_l' ) OOI.target_hand_l = n;

      if ( n.name == 'boule' ) OOI.sphere = n;
      if ( n.name == 'Kira_Shirt_left' ) OOI.kira = n;

    } );
    threeJs.scene.add(gltf.scene);

    const targetPosition = OOI.sphere.position.clone(); // for orbit controls
    OOI.hand_l.attach( OOI.sphere );

    // mirror sphere cube-threeJs.camera
    final cubeRenderTarget = three.WebGLCubeRenderTarget( 1024 );
    mirrorSphereCamera = three.CubeCamera( 0.05, 50, cubeRenderTarget );
    threeJs.scene.add( mirrorSphereCamera );
    const mirrorSphereMaterial = three.MeshBasicMaterial( { envMap: cubeRenderTarget.texture } );
    OOI.sphere.material = mirrorSphereMaterial;

    OOI.kira.add( OOI.kira.skeleton.bones[ 0 ] );
    const iks = [
      {
        'target': 22, // "target_hand_l"
        'effector': 6, // "hand_l"
        'links': [
          {
            'index': 5, // "lowerarm_l"
            'rotationMin': three.Vector3( 1.2, - 1.8, - .4 ),
            'rotationMax': three.Vector3( 1.7, - 1.1, .3 )
          },
          {
            'index': 4, // "Upperarm_l"
            'rotationMin': three.Vector3( 0.1, - 0.7, - 1.8 ),
            'rotationMax': three.Vector3( 1.1, 0, - 1.4 )
          },
        ],
      }
    ];
    IKSolver = new CCDIKSolver( OOI.kira, iks );
    const ccdikhelper = new CCDIKHelper( OOI.kira, iks, 0.01 );
    threeJs.scene.add( ccdikhelper );
    //

    final orbitControls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    orbitControls.minDistance = 0.2;
    orbitControls.maxDistance = 1.5;
    orbitControls.enableDamping = true;
    orbitControls.target.setFrom( targetPosition );

    final transformControls = TransformControls( threeJs.camera, threeJs.globalKey );
    transformControls.size = 0.75;
    transformControls.showX = false;
    transformControls.space = 'world';
    transformControls.attach( OOI.target_hand_l );
    threeJs.scene.add( transformControls );

    // disable orbitControls while using transformControls
    transformControls.addEventListener( 'mouseDown', () => orbitControls.enabled = false );
    transformControls.addEventListener( 'mouseUp', () => orbitControls.enabled = true );
    
    void animate( ) {
      if ( OOI.sphere && mirrorSphereCamera ) {
        OOI.sphere.visible = false;
        OOI.sphere.getWorldPosition( mirrorSphereCamera.position );
        mirrorSphereCamera.update( renderer, threeJs.scene );
        OOI.sphere.visible = true;

      }

      if ( OOI.sphere && conf.followSphere ) {
        // orbitControls follows the sphere
        OOI.sphere.getWorldPosition( v0 );
        orbitControls.target.lerp( v0, 0.1 );
      }

      if ( OOI.head && OOI.sphere && conf.turnHead ) {
        // turn head
        OOI.sphere.getWorldPosition( v0 );
        OOI.head.lookAt( v0 );
        OOI.head.rotation.set( OOI.head.rotation.x, OOI.head.rotation.y + Math.PI, OOI.head.rotation.z );
      }

      if ( conf.ik_solver ) {
        updateIK();
      }

      orbitControls.update();
    }

    void updateIK() {
      if ( IKSolver ) IKSolver.update();
      threeJs.scene.traverse( function ( object ) {
        if ( object is three.SkinnedMesh ) object.computeBoundingSphere();
      } );
    }

    threeJs.addAnimationEvent((dt){
      animate();
    });

  }
}
