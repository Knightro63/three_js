import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_exporters/three_js_exporters.dart';
import 'package:three_js_geometry/three_js_geometry.dart';

class MiscExporterOBJ extends StatefulWidget {
  const MiscExporterOBJ({super.key});
  @override
  createState() => _State();
}

class _State extends State<MiscExporterOBJ> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late Gui gui;

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
        useOpenGL: useOpenGL
      )
    );
    gui = Gui((){setState(() {});});
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
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: gui.render()
            )
          )  
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late final three.Mesh mesh;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 0,0,4 );

    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight( 0xffffff );
    threeJs.scene.add( ambientLight );

    final directionalLight = three.DirectionalLight( 0xffffff, 1 );
    directionalLight.position.setValues( 0, 1,1 );
    threeJs.scene.add( directionalLight );

    final geometry = three.BoxGeometry();
    final material = three.MeshPhongMaterial.fromMap( { 'color': 0x00ff00 } );

    mesh = three.Mesh( geometry, material );
    mesh.castShadow = true;
    mesh.position.y = 0.5;
    threeJs.scene.add( mesh );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enablePan = false;

    final Map<String,dynamic> params = {
      'addTriangle': true,
      'addCube': true,
      'addCylinder': true,
      'addMultiple': true,
      'addTransformed': true,
      'addPoints': true,
      'exportToObj': true
    };


    final folder1 = gui.addFolder('Geometry Selection')..open();

    folder1.addButton( params, 'addTriangle' ).onChange(( val ) {
      addTriangle();
    });
    folder1.addButton( params, 'addCube' ).onChange(( val ) {
      addCube();
    });
    folder1.addButton( params, 'addCylinder' ).onChange(( val ) {
      addCylinder();
    });
    folder1.addButton( params, 'addMultiple' ).onChange(( val ) {
      addMultiple();
    });
    folder1.addButton( params, 'addTransformed' ).onChange(( val ) {
      addTransformed();
    });
    folder1.addButton( params, 'addPoints' ).onChange(( val ) {
      addPoints();
    });

    final folder2 = gui.addFolder('Export')..open();
    folder2.addButton( params, 'exportToObj' ).onChange(( val ) {
      exportToObj();
    });//.name( 'Export OBJ' );
  }

  void exportToObj() {
    OBJExporter.exportScene( 'object' ,threeJs.scene );
  }

  addGeometry( type ) {
    for (int i = 0; i < threeJs.scene.children.length; i ++ ) {
      final child = threeJs.scene.children[ i ];

      if ( child is three.Mesh || child is three.Points ) {
        child.geometry?.dispose();
        threeJs.scene.remove( child );
        i --;
      }
    }

    if ( type == 1 ) {
      final material = three.MeshLambertMaterial.fromMap( { 'color': 0x00cc00 } );
      final geometry = generateTriangleGeometry();

      threeJs.scene.add( three.Mesh( geometry, material ) );
    } 
    else if ( type == 2 ) {
      final material = three.MeshLambertMaterial.fromMap( { 'color': 0x00cc00 } );
      final geometry = three.BoxGeometry( 100, 100, 100 );
      threeJs.scene.add( three.Mesh( geometry, material ) );
    } 
    else if ( type == 3 ) {
      final material = three.MeshLambertMaterial.fromMap( { 'color': 0x00cc00 } );
      final geometry = CylinderGeometry( 50, 50, 100, 30, 1 );
      threeJs.scene.add( three.Mesh( geometry, material ) );
    } 
    else if ( type == 4 || type == 5 ) {
      final material = three.MeshLambertMaterial.fromMap( { 'color': 0x00cc00 } );
      final geometry = generateTriangleGeometry();

      final mesh = three.Mesh( geometry, material );
      mesh.position.x = - 200;
      threeJs.scene.add( mesh );

      final geometry2 = three.BoxGeometry( 100, 100, 100 );
      final mesh2 = three.Mesh( geometry2, material );
      threeJs.scene.add( mesh2 );

      final geometry3 = CylinderGeometry( 50, 50, 100, 30, 1 );
      final mesh3 = three.Mesh( geometry3, material );
      mesh3.position.x = 200;
      threeJs.scene.add( mesh3 );

      if ( type == 5 ) {
        mesh.rotation.y = math.pi / 4.0;
        mesh2.rotation.y = math.pi / 4.0;
        mesh3.rotation.y = math.pi / 4.0;
      }
    } 
    else if ( type == 6 ) {
      final List<double> points = [ 0, 0, 0, 100, 0, 0, 100, 100, 0, 0, 100, 0 ];
      final List<double> colors = [ 0.5, 0, 0, 0.5, 0, 0, 0, 0.5, 0, 0, 0.5, 0 ];

      final geometry = three.BufferGeometry();
      geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( points, 3 ) );
      geometry.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ) );

      final material = three.PointsMaterial.fromMap( { 'size': 10, 'vertexColors': true } );

      final pointCloud = three.Points( geometry, material );
      pointCloud.name = 'point cloud';
      threeJs.scene.add( pointCloud );
    }
  }

  void addTriangle() {
    addGeometry( 1 );
  }

  void addCube() {
    addGeometry( 2 );
  }

  void addCylinder() {
    addGeometry( 3 );
  }

  void addMultiple() {
    addGeometry( 4 );
  }

  void addTransformed() {
    addGeometry( 5 );
  }

  void addPoints() {
    addGeometry( 6 );
  }

  three.BufferGeometry generateTriangleGeometry() {
    final geometry = three.BufferGeometry();
    final List<double> vertices = [];

    vertices.addAll([ - 50, - 50, 0 ]);
    vertices.addAll([ 50, - 50, 0 ]);
    vertices.addAll([ 50, 50, 0 ]);

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( vertices, 3 ) );
    geometry.computeVertexNormals();

    return geometry;
  }
}
