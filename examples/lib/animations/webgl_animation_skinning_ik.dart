import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_transform_controls/three_js_transform_controls.dart';
import 'package:three_js_transform_controls/transform_controls.dart';

class WebglAnimationSkinningIK extends StatefulWidget {
  
  const WebglAnimationSkinningIK({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglAnimationSkinningIK> {
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

  late three.AnimationMixer mixer;
  late three.OrbitControls orbitControls;
  late TransformControls transformControls;
  late three.Object3D model;
  final v0 = three.Vector3();
  late final three.CubeCamera mirrorSphereCamera;

  late Map<String,dynamic> conf = {
    'followSphere': false,
    'turnHead': true,
    'ik_solver': true,
    'gizmo': true
  };

  final OOI ooi = OOI();
  late final three.CCDIKSolver ikSolver;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.FogExp2( 0xffffff, .17 );
    threeJs.scene.background = three.Color.fromHex32( 0xffffff );

    threeJs.camera = three.PerspectiveCamera( 55, threeJs.width / threeJs.height, 0.001, 5000 );
    threeJs.camera.position.setValues( 0.9728517749133652, 1.1044765132727201, 0.7316689528482836 );
    threeJs.camera.lookAt( threeJs.scene.position );

    final ambientLight = three.AmbientLight( 0xffffff, 8 ); // soft white light
    threeJs.scene.add( ambientLight );

    final gltfLoader = three.GLTFLoader();
    final gltf = await gltfLoader.fromAsset( 'assets/models/gltf/kira.glb' );
    gltf?.scene.traverse((n){
      if ( n.name == 'head' ) ooi.head = n;
      if ( n.name == 'lowerarm_l' ) ooi.lowerarm_l = n;
      if ( n.name == 'Upperarm_l' ) ooi.upperarm_l = n;
      if ( n.name == 'hand_l' ) ooi.hand_l = n;
      if ( n.name == 'target_hand_l' ) ooi.target_hand_l = n;

      if ( n.name == 'boule' ) ooi.sphere = n;
      if ( n.name == 'Kira_Shirt_left' ) ooi.kira = n as three.SkinnedMesh;
    } );
    threeJs.scene.add( gltf?.scene );

    final targetPosition = ooi.sphere!.position.clone(); // for orbit controls
    print(ooi.sphere!.position);
    ooi.hand_l!.attach( ooi.sphere!..position.add(three.Vector3(0.35,-0.18,0.75)) );

    // mirror sphere cube-camera
    final cubeRenderTarget = three.CubeRenderTarget( 1024 );
    mirrorSphereCamera = three.CubeCamera( 0.05, 50, cubeRenderTarget );
    threeJs.scene.add( mirrorSphereCamera );
    final mirrorSphereMaterial = three.MeshBasicMaterial.fromMap( { 'envMap': cubeRenderTarget.texture } );
    ooi.sphere!.material = mirrorSphereMaterial;

    ooi.kira!.add( ooi.kira!.skeleton!.bones[ 0 ] );
    final iks = [
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
    ikSolver = three.CCDIKSolver( ooi.kira!, iks );
    //final ccdikhelper = ikSolver.createHelper(0.01);
    final ccdikhelper = three.CCDIKHelper( ooi.kira!, iks, 0.01 );
    threeJs.scene.add( ccdikhelper );

    final gui = panel.addFolder('CCDIK');
    gui.addCheckBox( conf, 'followSphere' ).name = 'follow sphere';
    gui.addCheckBox( conf, 'turnHead' ).name = 'turn head';
    gui.addCheckBox( conf, 'ik_solver' ).name = 'IK auto update';
    gui.addFunction( 'update' )..name = 'IK manual update()'..onFinishChange((){
      updateIK();
    });
    gui.addButton(conf, 'gizmo' )..name = 'Gizmo'..onFinishChange((){
      transformControls.setMode( conf['gizmo']?GizmoType.translate:GizmoType.rotate);
    });
    gui.open();

    //
    orbitControls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    orbitControls.minDistance = 0.2;
    orbitControls.maxDistance = 1.5;
    orbitControls.enableDamping = true;
    orbitControls.target.setFrom( targetPosition );

    transformControls = TransformControls( threeJs.camera, threeJs.globalKey );
    transformControls.size = 0.75;
    transformControls.space = 'world';
    transformControls.attach( ooi.target_hand_l );
    threeJs.scene.add( transformControls);

    transformControls.addEventListener( 'dragging-changed', (event) {
      bool isDragging = event.value == true;
      orbitControls.enabled = !isDragging;
    });

    threeJs.addAnimationEvent(animate);
  }

  void animate(double dt) {
    if ( ooi.sphere != null) {
      ooi.sphere?.visible = false;
      ooi.sphere?.getWorldPosition( mirrorSphereCamera.position );
      mirrorSphereCamera.update( threeJs.renderer!, threeJs.scene );
      ooi.sphere?.visible = true;
    }

    if ( ooi.sphere != null && conf['followSphere'] == true) {
      ooi.sphere?.getWorldPosition( v0 );
      orbitControls.target.lerp( v0, 0.1 );
    }

    if ( ooi.head != null && ooi.sphere != null && conf['turnHead'] == true) {
      ooi.sphere?.getWorldPosition( v0 );
      ooi.head?.lookAt( v0 );
      ooi.head?.rotation.set( ooi.head!.rotation.x, ooi.head!.rotation.y + math.pi, ooi.head!.rotation.z );
    }

    if ( conf['ik_solver'] == true) {
      updateIK();
    }

    orbitControls.update();
  }

  void updateIK() {
    ikSolver.update();
    threeJs.scene.traverse( ( object ) {
      if ( object is three.SkinnedMesh ) object.computeBoundingSphere();
    } );
  }
}

class OOI{
  three.Object3D? head;
  three.Object3D? lowerarm_l;
  three.Object3D?  upperarm_l;
  three.Object3D?  hand_l;
  three.Object3D? target_hand_l;
  three.Object3D?  sphere;
  three.SkinnedMesh? kira;
}
