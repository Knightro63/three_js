import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/three_js_xr.dart';
import 'package:oimo_physics/oimo_physics.dart' as oimo;
import 'package:vector_math/vector_math.dart' hide Colors;


extension on Vector3{
  three.Vector3 toVector3(){
    return three.Vector3(x,y,z);
  }
}

extension on three.Vector3{
  Vector3 toVector3(){
    return Vector3(x,y,z);
  }
}

class WebXRXRBallShooter extends StatefulWidget {
  const WebXRXRBallShooter({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRXRBallShooter> {
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
        xr: xrSetup,
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
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

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  final three.Raycaster raycaster = three.Raycaster();
  WebXRController? controller1;
  WebXRController? controller2;
  WebXRController? controllerGrip1;
  WebXRController? controllerGrip2;
  late three.OrbitControls controls;
  late three.Group group;
  late final three.LineSegments room;
  late final three.InstancedMesh spheres;

  List<three.Object3D?> intersected = [];
  final velocity = three.Vector3();
  int count = 0;
  late oimo.World physics;

  List<oimo.RigidBody> ballsRB = [];
  List<three.Object3D> balls = [];

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x505050 );

    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.1, 50 );
    threeJs.camera.position.setValues( 0, 1.6, 3 );

    room = three.LineSegments(
      three.BoxLineGeometry( 6, 6, 6, 10, 10, 10 ),
      three.LineBasicMaterial.fromMap( { 'color': 0x808080 } )
    );
    room.geometry?.translate( 0, 3, 0 );
    threeJs.scene.add( room );

    threeJs.scene.add( three.HemisphereLight( 0xbbbbbb, 0x888888, 0.3 ) );

    final light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 1, 1, 1 ).normalize();
    threeJs.scene.add( light );

    //
    final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.maxDistance = 10;
    controls.target.y = 1.6;
    controls.update();

    controller1 = (threeJs.renderer?.xr as WebXRWorker).getController( 0 );
    controller1?.addEventListener( 'selectstart', (event){controller1?.userData['isSelecting'] = true;} );
    controller1?.addEventListener( 'selectend', (event){controller1?.userData['isSelecting'] = false;} );
    controller1?.addEventListener( 'connected', ( event ) {
      controller1?.add( buildController( event.data ) );
    });
    controller1?.addEventListener( 'disconnected', () {
      controller1?.remove( controller1!.children[ 0 ] );
    });
    threeJs.scene.add( controller1 );

    controller2 = (threeJs.renderer?.xr as WebXRWorker).getController( 1 );
    controller2?.addEventListener( 'selectstart', (event){controller2?.userData['isSelecting'] = true;}  );
    controller2?.addEventListener( 'selectend', (event){controller2?.userData['isSelecting'] = false;} );
    controller2?.addEventListener( 'connected', ( event ) {
      controller2?.add( buildController( event.data ) );
    });
    controller2?.addEventListener( 'disconnected', () {
      controller2?.remove( controller2!.children[ 0 ] );
    });
    threeJs.scene.add( controller2 );

    // The XRControllerModelFactory will automatically fetch controller models
    // that match what the user is holding as closely as possible. The models
    // should be attached to the object returned from getControllerGrip in
    // order to match the orientation of the held device.

    final controllerModelFactory = XRControllerModelFactory();

    controllerGrip1 = (threeJs.renderer?.xr as WebXRWorker).getControllerGrip( 0 );
    controllerGrip1?.add( controllerModelFactory.createControllerModel( controllerGrip1! ) );
    threeJs.scene.add( controllerGrip1 );

    controllerGrip2 = (threeJs.renderer?.xr as WebXRWorker).getControllerGrip( 1 );
    controllerGrip2?.add( controllerModelFactory.createControllerModel( controllerGrip2! ) );
    threeJs.scene.add( controllerGrip2 );

    initPhysics();

    threeJs.addAnimationEvent((dt){
      animate();
    });
  }

  three.Object3D? buildController( data ) {
    three.BufferGeometry geometry;
    three.Material material;

    switch ( data.targetRayMode ) {
      case 'tracked-pointer':
        geometry = three.BufferGeometry();
        geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( [ 0, 0, 0, 0, 0, - 1 ], 3 ) );
        geometry.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( [ 0.5, 0.5, 0.5, 0, 0, 0 ], 3 ) );

        material = three.LineBasicMaterial.fromMap( { 'vertexColors': true, 'blending': three.AdditiveBlending } );

        return three.Line( geometry, material );
      case 'gaze':
        geometry = three.RingGeometry( 0.02, 0.04, 32 ).translate( 0, 0, - 1 );
        material = three.MeshBasicMaterial.fromMap( { 'opacity': 0.5, 'transparent': true } );
        return three.Mesh( geometry, material );
    }

    return null;
  }

  final matrix = three.Matrix4();
  final color = three.Color();

  void initPhysics(){
    physics = oimo.World(oimo.WorldConfigure(
      timeStep: 1 / 60, 
      iterations: 2, 
      broadPhaseType: oimo.BroadPhaseType.sweep, 
      scale: 1, 
      enableRandomizer: true, 
      gravity: Vector3(0, -9.8 * 3, 0),
    ));
    
    {
      // Floor
      final geometry = three.BoxGeometry( 6, 2, 6 );
      final material = three.MeshNormalMaterial.fromMap( { 'visible': false } );

      final floor = three.Mesh( geometry, material );
      floor.position.y = - 1;
      threeJs.scene.add( floor );

      final floorrb = oimo.RigidBody(
        type: oimo.RigidBodyType.static,
        shapes: [oimo.Box(oimo.ShapeConfig(geometry: oimo.Shapes.box),6,2,6)],
        position: Vector3(0, -1, 0),
        orientation: Quaternion.euler(0,0,0),
      );

      physics.addRigidBody(floorrb);

      // Walls
      final wallPX = three.Mesh( geometry, material );
      wallPX.position.setValues( 4, 3, 0 );
      wallPX.rotation.z = math.pi / 2;
      threeJs.scene.add( wallPX );

      final wall1rb = oimo.RigidBody(
        type: oimo.RigidBodyType.static,
        shapes: [oimo.Box(oimo.ShapeConfig(geometry: oimo.Shapes.box),6,2,6)],
        position: Vector3(4,3,0),
        orientation: Quaternion.euler(0,0,math.pi / 2),
      );

      physics.addRigidBody(wall1rb);

      final wallNX = three.Mesh( geometry, material );
      wallNX.position.setValues( - 4, 3, 0 );
      wallNX.rotation.z = math.pi / 2;
      threeJs.scene.add( wallNX );

      final wall2rb = oimo.RigidBody(
        type: oimo.RigidBodyType.static,
        shapes: [oimo.Box(oimo.ShapeConfig(geometry: oimo.Shapes.box),6,2,6)],
        position: Vector3(-4,3,0),
        orientation: Quaternion.euler(0,0,math.pi / 2),
      );

      physics.addRigidBody(wall2rb);

      final wallPZ = three.Mesh( geometry, material );
      wallPZ.position.setValues( 0, 3, 4 );
      wallPZ.rotation.x = math.pi / 2;
      threeJs.scene.add( wallPZ );

      final wall3rb = oimo.RigidBody(
        type: oimo.RigidBodyType.static,
        shapes: [oimo.Box(oimo.ShapeConfig(geometry: oimo.Shapes.box),6,2,6)],
        position: Vector3(0,3,4),
        orientation: Quaternion.euler(0,math.pi / 2,0),
      );

      physics.addRigidBody(wall3rb);

      final wallNZ = three.Mesh( geometry, material );
      wallNZ.position.setValues( 0, 3, - 4 );
      wallNZ.rotation.x = math.pi / 2;
      threeJs.scene.add( wallNZ );
      
      final wall4rb = oimo.RigidBody(
        type: oimo.RigidBodyType.static,
        shapes: [oimo.Box(oimo.ShapeConfig(geometry: oimo.Shapes.box),6,2,6)],
        position: Vector3(0,3,-4),
        orientation: Quaternion.euler(0,math.pi / 2,0),
      );

      physics.addRigidBody(wall4rb);
    }

    // Spheres
    final geometry = three.IcosahedronGeometry( 0.08, 3 );
    final material = three.MeshLambertMaterial();

    spheres = three.InstancedMesh( geometry, material, 200 );
    spheres.instanceMatrix!.setUsage( three.DynamicDrawUsage ); // will be updated every frame
    threeJs.scene.add( spheres );

    for (int i = 0; i < 200; i ++ ) {
      final x = math.Random().nextDouble() * 4 - 2;
      final y = math.Random().nextDouble() * 4;
      final z = math.Random().nextDouble() * 4 - 2;

      matrix.setPosition( x, y, z );
      spheres.setMatrixAt(i, matrix);
      spheres.setColorAt(i,color..setFromHex32( (0xffffff * math.Random().nextDouble()).toInt() ));

      final oimo.RigidBody sphereBody = oimo.RigidBody(
        type: oimo.RigidBodyType.dynamic,
        shapes: [
          oimo.Sphere(
            oimo.ShapeConfig(
              geometry: oimo.Shapes.sphere,
              restitution: 0.55,
              belongsTo: 1,
              collidesWith: 0xffffffff
            ),
            0.08,
          )
        ],
        position: Vector3(x,y,z),
        mass: 1.0
      );//
      physics.addRigidBody(sphereBody);
      ballsRB.add(sphereBody);
    }
  }

  void handleController(WebXRController controller ) {
    if ( controller.userData['isSelecting'] == true) {
      final body = ballsRB[count];

      velocity.x = ( math.Random().nextDouble() - 0.5 ) * 2;
      velocity.y = ( math.Random().nextDouble() - 0.5 ) * 2;
      velocity.z = ( math.Random().nextDouble() - 9 );
      velocity.applyQuaternion( controller.quaternion );

      body.position.setFrom(controller.position.toVector3());
      body.linearVelocity.setFrom(velocity.toVector3());
      body.angularVelocity.setFrom(body.initAngularVelocity);

      if ( ++ count == spheres.count ) count = 0;
    }
  }

  void updateVisuals(){
    for (int i = 0; i < ballsRB.length; i++) {
      final body = ballsRB[i];
      final m = three.Matrix4().setPositionFromVector3( body.position.toVector3());
      spheres.setMatrixAt( i, m );
      spheres.instanceMatrix?.needsUpdate = true;
    }
  }

  void animate() {
    physics.step();
    updateVisuals();
    handleController( controller1! );
    handleController( controller2! );
  }
}
