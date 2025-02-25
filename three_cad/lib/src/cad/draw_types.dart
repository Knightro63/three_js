import 'package:three_js/three_js.dart';
import 'dart:math' as math;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_line/three_js_line.dart';

enum DrawType{
  none,point,line,arc,circle,spline,boxCenter,box2Point;
  
  static Group createSpline(Vector3 position){
    final g = Group();
    final geometry = BufferGeometry();
    geometry.setAttributeFromString('position',Float32BufferAttribute( Float32Array( 200 * 3 ), 3 ) );
    final line = Line(
      geometry, 
      LineBasicMaterial.fromMap( {
        'color': 0x06A7E2,
        'transparent': true,
        'opacity': 0.5
      })
    )..name = 'line';

    g.add(line);
    g.add(creatPoint(position));
    g.add(creatPoint(position));

    updateSplineOutline(line, [position,position]);

    return g;
  }
  static void updateSplineOutline(Line mesh, List<Vector3> positions){
    final point = Vector3();
    CatmullRomCurve3 curve = CatmullRomCurve3( points:positions );
    curve.curveType = 'catmullrom';
    curve.closed = false;
    curve.tension = 0.8;

    final splineMesh = mesh;
    final position = splineMesh.geometry!.attributes['position'];

    for (int i = 0; i < 200; i ++ ) {
      final t = i / ( 200 - 1 );
      curve.getPoint( t, point );
      position.setXYZ( i, point.x, point.y, point.z );
    }

    position.needsUpdate = true;
  }
  static Group createCircle(Vector3 position){
    Group objects = Group()..name = 'circle';
    objects.add(creatPoint(position));

    final edges = EdgesGeometry( CircleGeometry(radius: 1, segments: 64),math.pi/8 ); 
    final line = 
    LineSegments(edges, LineBasicMaterial.fromMap({'color': 0x06A7E2}))
    ..scale.scale(0)
    ..position.x = position.x
    ..position.y = position.y
    ..position.z = position.z;

    objects.add(line);
    return objects;
  }
  
  static Group createBoxCenter(Vector3 position){
    Group objects = Group()..name = 'boxCenter';
    objects.add(creatPoint(Vector3(-1,1,0)));
    objects.add(create2PointLine(Vector3(-1,1,0),Vector3(1,1,0)));
    objects.add(creatPoint(Vector3(1,1,0)));
    objects.add(create2PointLine(Vector3(1,1,0),Vector3(1,-1,0)));
    objects.add(creatPoint(Vector3(1,-1,0)));
    objects.add(create2PointLine(Vector3(1,-1,0),Vector3(-1,-1,0)));
    objects.add(creatPoint(Vector3(-1,-1,0)));
    objects.add(create2PointLine(Vector3(-1,-1,0),Vector3(-1,1,0)));

    objects.add(create2PointLine(Vector3(-1,1,0),Vector3(1,-1,0),true));
    objects.add(create2PointLine(Vector3(1,1,0),Vector3(-1,-1,0),true));
    objects.add(creatPoint(Vector3(0,0,0)));
    return objects    
      ..scale.scale(0)
      ..position.x = position.x
      ..position.y = position.y
      ..position.z = position.z;
  }

  static Group createBox2Point(Vector3 position){
    Group objects = Group()..name = 'box2Point';
    objects.add(creatPoint(Vector3(1,0,0)));
    objects.add(create2PointLine(Vector3(1,0,0),Vector3(1,1,0)));
    objects.add(creatPoint(Vector3(1,1,0)));
    objects.add(create2PointLine(Vector3(1,1,0),Vector3(0,1,0)));
    objects.add(creatPoint(Vector3(0,1,0)));
    objects.add(create2PointLine(Vector3(0,1,0),Vector3(0,0,0)));
    objects.add(creatPoint(Vector3(0,0,0)));
    objects.add(create2PointLine(Vector3(0,0,0),Vector3(1,0,0)));

    return objects    
      ..scale.scale(0)
      ..position.x = position.x
      ..position.y = position.y
      ..position.z = position.z;
  }

  static Object3D creatPoint(Vector3 position, [int? color]){
    return Points(
        BufferGeometry()..setAttributeFromString(
          'position',
          Float32BufferAttribute.fromList([0,0,0],3)
        ),
        PointsMaterial.fromMap({
          'color': color ?? 0x06A7E2,
          'size': 7.5, 
          'transparent': color == null? true : false,
          'opacity': color == null?0.5:1
        })
      )
      ..name = 'point'
      ..position.x = position.x
      ..position.y = position.y
      ..position.z = position.z;
  }
  static Line2 createFatLine(Vector3 mousePosition,[bool construction = false]){
    final geometry = LineGeometry();
    geometry.setPositions(Float32Array.fromList(mousePosition.storage+mousePosition.storage));
    final matLine = LineMaterial.fromMap( {
      'color': 0x06A7E2,
      'linewidth': 5, // in world units with size attenuation, pixels otherwise
    })
    ..worldUnits = true;


    return Line2( geometry, matLine )
    ..name = 'line'
    ..userData['construction'] = construction
    ..computeLineDistances();
  }
  static Line createLine(Vector3 position,[bool construction = false]){
    final geometry = BufferGeometry();
    geometry.setAttributeFromString(
      'position',
      Float32BufferAttribute.fromList(position.storage+position.storage,3)
    );
    final matLine = LineBasicMaterial.fromMap( {
      'color': construction?0xffff00:0x06A7E2,
      'transparent': true,
      'opacity': 0.5
    })
    ..scale = 2
    ..dashSize = 0.0001
    ..gapSize = 0.0001;

    return Line( geometry, matLine )
    ..name = 'line'
    ..computeLineDistances()
    ..userData['construction'] = construction;
  }
  static Line create2PointLine(Vector3 position1,Vector3 position2,[bool construction = false]){
    final geometry = BufferGeometry();
    geometry.setAttributeFromString(
      'position',
      Float32BufferAttribute.fromList(position1.storage+position2.storage,3)
    );
    final matLine = LineBasicMaterial.fromMap( {
      'color': construction?0xffff00:0x06A7E2,
      'transparent': true,
      'opacity': 0.5
    })
    ..scale = 2
    ..dashSize = 0.0001
    ..gapSize = 0.0001;

    return Line( geometry, matLine )
    ..name = 'line'
    ..computeLineDistances()
    ..userData['construction'] = construction;
  }
}