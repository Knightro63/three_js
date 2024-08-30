import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

class WebglGeometrySplineEditor extends StatefulWidget {
  const WebglGeometrySplineEditor({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglGeometrySplineEditor> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late final Gui gui;
  late final three.OrbitControls controls;

  @override
  void initState() {
    gui = Gui((){setState(() {});});
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
    controls.dispose();
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

  late final TransformControls transformControl;
  final List<three.Object3D> splineHelperObjects = [];
  int splinePointsLength = 4;
  final List<three.Vector3> positions = [];
  final point = three.Vector3();

  final raycaster = three.Raycaster();
  final pointer = three.Vector2();
  final onUpPosition = three.Vector2();
  final onDownPosition = three.Vector2();

  final geometry = three.BoxGeometry( 20, 20, 20 );

  final ARC_SEGMENTS = 200;

  final Map<String,three.CatmullRomCurve3> splines = {};
  late final Map<String,dynamic> params;

  Future<void> setup() async {
    params = {
      'uniform': true,
      'tension': 0.5,
      'centripetal': true,
      'chordal': true,
      'addPoint': addPoint,
      'removePoint': removePoint,
    };
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xf0f0f0 );

    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.setValues( 0, 250, 1000 );
    threeJs.scene.add( threeJs.camera );

    threeJs.scene.add( three.AmbientLight( 0xf0f0f0, 0.3 ) );
    final light = three.SpotLight( 0xffffff, 0.45 );
    light.position.setValues( 0, 1500, 200 );
    light.angle = math.pi * 0.2;
    light.decay = 0;
    threeJs.scene.add( light );

    final planeGeometry = three.PlaneGeometry( 2000, 2000 );
    planeGeometry.rotateX( - math.pi / 2 );
    final planeMaterial = three.ShadowMaterial.fromMap( { 'color': 0x000000, 'opacity': 0.2 } );

    final plane = three.Mesh( planeGeometry, planeMaterial );
    plane.position.y = - 200;
    plane.receiveShadow = true;
    threeJs.scene.add( plane );

    final helper = GridHelper( 2000, 100 );
    helper.position.y = - 199;
    helper.material?.opacity = 0.25;
    helper.material?.transparent = true;
    threeJs.scene.add( helper );

    
    final folder = gui.addFolder('GUI');
    folder.addButton( params, 'uniform' ).onFinishChange( render );
    folder.addSlider( params, 'tension', 0, 1 )..step( 0.01 )..onChange(( value ) {
      splines['uniform']?.tension = value;
      updateSplineOutline();
      render();
    } );
    folder.addButton( params, 'centripetal' ).onFinishChange( render );
    folder.addButton( params, 'chordal' ).onFinishChange( render );
    folder.addButton( params, 'addPoint' );
    folder.addButton( params, 'removePoint' );
    folder.open();

    // Controls
    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.damping = 0.2;
    controls.addEventListener( 'change', render );

    transformControl = TransformControls( threeJs.camera, threeJs.globalKey );
    transformControl.addEventListener( 'change', render );
    transformControl.addEventListener( 'dragging-changed', ( event ) {
      controls.enabled = ! event.value;
    } );
    threeJs.scene.add( transformControl );

    transformControl.addEventListener( 'objectChange',() {
      updateSplineOutline();
    } );

    threeJs.domElement.addEventListener( three.PeripheralType.pointerdown, onPointerDown );
    threeJs.domElement.addEventListener( three.PeripheralType.pointerup, onPointerUp );
    threeJs.domElement.addEventListener( three.PeripheralType.pointermove, onPointerMove );

    /*******
     * Curves
     *********/

    for (int i = 0; i < splinePointsLength; i ++ ) {
      addSplineObject( positions[ i ] );
    }

    positions.length = 0;

    for (int i = 0; i < splinePointsLength; i ++ ) {
      positions.add( splineHelperObjects[ i ].position );
    }

    final geometry = three.BufferGeometry();
    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute( three.Float32Array( ARC_SEGMENTS * 3 ), 3 ) );

    three.CatmullRomCurve3 curve = three.CatmullRomCurve3( points:positions );
    curve.curveType = 'catmullrom';
    curve.mesh = three.Line( geometry.clone(), three.LineBasicMaterial.fromMap( {
      'color': 0xff0000,
      'opacity': 0.35
    } ) );
    splines['uniform'] = curve;

    curve = three.CatmullRomCurve3( points: positions );
    curve.curveType = 'centripetal';
    curve.mesh = three.Line( geometry.clone(), three.LineBasicMaterial.fromMap( {
      'color': 0x00ff00,
      'opacity': 0.35
    } ) );
    splines['centripetal'] = curve;

    curve = three.CatmullRomCurve3( points:positions );
    curve.curveType = 'chordal';
    curve.mesh = three.Line( geometry.clone(), three.LineBasicMaterial.fromMap( {
      'color': 0x0000ff,
      'opacity': 0.35
    } ) );
    splines['chordal'] = curve;

    for ( final k in splines.keys ) {
      final spline = splines[ k ];
      threeJs.scene.add( spline.mesh );
    }

    load( [ three.Vector3( 289.76843686945404, 452.51481137238443, 56.10018915737797 ),
      three.Vector3( - 53.56300074753207, 171.49711742836848, - 14.495472686253045 ),
      three.Vector3( - 91.40118730204415, 176.4306956436485, - 6.958271935582161 ),
      three.Vector3( - 383.785318791128, 491.1365363371675, 47.869296953772746 ) ] );
  }

  three.Mesh addSplineObject([three.Vector3? position ]) {
    final material = three.MeshLambertMaterial.fromMap( { 'color': math.Random().nextDouble() * 0xffffff } );
    final object = three.Mesh( geometry, material );

    if ( position != null) {
      object.position.setFrom( position );
    } else {
      object.position.x = math.Random().nextDouble() * 1000 - 500;
      object.position.y = math.Random().nextDouble() * 600;
      object.position.z = math.Random().nextDouble() * 800 - 400;
    }

    object.castShadow = true;
    object.receiveShadow = true;
    threeJs.scene.add( object );
    splineHelperObjects.add( object );
    return object;
  }

  void addPoint() {
    splinePointsLength ++;
    positions.add( addSplineObject().position );
    updateSplineOutline();
    render();
  }

  void removePoint() {
    if ( splinePointsLength <= 4 ) {
      return;
    }

    final point = splineHelperObjects.removeLast();
    splinePointsLength --;
    positions.removeLast();

    if ( transformControl.object == point ) transformControl.detach();
    threeJs.scene.remove( point );

    updateSplineOutline();
    render();
  }

  void updateSplineOutline() {
    for ( final k in splines.keys) {
      final spline = splines[ k ];

      final splineMesh = spline.mesh;
      final position = splineMesh.geometry.attributes.position;

      for (int i = 0; i < ARC_SEGMENTS; i ++ ) {
        final t = i / ( ARC_SEGMENTS - 1 );
        spline?.getPoint( t, point );
        position.setXYZ( i, point.x, point.y, point.z );
      }

      position.needsUpdate = true;
    }
  }

  void load(List<three.Vector3> newPositions ) {
    while ( newPositions.length > positions.length ) {
      addPoint();
    }
    while ( newPositions.length < positions.length ) {
      removePoint();
    }

    for (int i = 0; i < positions.length; i ++ ) {
      positions[ i ].setFrom( newPositions[ i ] );
    }

    updateSplineOutline();
  }

  void render() {
    splines['uniform'].mesh.visible = params['uniform'];
    splines['centripetal'].mesh.visible = params['centripetal'];
    splines['chordal'].mesh.visible = params['chordal'];
    //renderer.render( scene, camera );
  }

  onPointerDown(three.WebPointerEvent event ) {
    onDownPosition.x = event.clientX;
    onDownPosition.y = event.clientY;
  }

  onPointerUp(three.WebPointerEvent event ) {
    onUpPosition.x = event.clientX;
    onUpPosition.y = event.clientY;

    if ( onDownPosition.distanceTo( onUpPosition ) == 0 ) {
      transformControl.detach();
      render();
    }
  }

  onPointerMove(three.WebPointerEvent event ) {
    pointer.x = ( event.clientX / threeJs.width ) * 2 - 1;
    pointer.y = - ( event.clientY / threeJs.height ) * 2 + 1;
    raycaster.setFromCamera( pointer, threeJs.camera );

    final intersects = raycaster.intersectObjects( splineHelperObjects, false );

    if ( intersects.isNotEmpty ) {
      final object = intersects[ 0 ].object;
      if ( object != transformControl.object ) {
        transformControl.attach( object );
      }
    }
  }
}
