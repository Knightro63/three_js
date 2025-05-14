import 'package:three_js/three_js.dart';
import 'dart:math' as math;
import 'package:three_js_line/three_js_line.dart';

enum DrawType{
  none,
  dimensions,
  point,
  line,
  arc3Point,
  arcCenterPoint,
  circleCenter,
  spline,
  boxCenter,
  box2Point,
  circle2Point,
  box3Point,
  mirror,
  circularPatern,
  retangularPattern;
  
  static Group createSpline(Vector3 position, int color){
    final g = Group()..name = 'spline';
    // final geometry = BufferGeometry();
    // geometry.setAttributeFromString('position',Float32BufferAttribute( Float32Array( 200 * 3 ), 3 ) );
    // final line = Line(
    //   geometry, 
    //   LineBasicMaterial.fromMap( {
    //     'color': color,
    //   })
    // )..name = 'line';

    final line = createLine(position, color, 200);
    g.add(line);
    g.add(creatPoint(position,color));
    g.add(creatPoint(position,color));

    updateSplineOutline(line, [position,position]);

    return g;
  }
  static Group createCircleSpline(Vector3 position, int color){
    Group objects = Group()..name = 'circleSpline';
    // final geometry = BufferGeometry();
    // geometry.setAttributeFromString('position',Float32BufferAttribute( Float32Array( 64 * 3 ), 3 ) );

    // final line = Line(
    //   geometry, 
    //   LineBasicMaterial.fromMap( {
    //     'color': color,
    //   })
    // )..name = 'line';
    
    final line = createLine(position, color, 64);
    objects.add(line);
    objects.add(creatPoint(position,color));

    updateSplineOutline(line, [position,position,position,position], true, 64);
    
    return objects;
  } 
  static void updateSplineOutline(Line mesh, List<Vector3> positions,[bool closed = false, int numLines = 200]){
    final point = Vector3();
    CatmullRomCurve3 curve = CatmullRomCurve3( points:positions );
    curve.curveType = 'catmullrom';
    curve.closed = closed;
    curve.tension = 0.8;

    final position = mesh.geometry!.attributes['position'];
    

    for (int i = 0; i < numLines; i ++ ) {
      final t = i / ( numLines - 1 );
      curve.getPoint( t, point );
      (position as Float32BufferAttribute).setXYZ( i, point.x, point.y, point.z );
    }

    position.needsUpdate = true;

    (mesh.children[0].geometry! as LineGeometry).fromLine(mesh);

    mesh.geometry?.computeBoundingSphere();
    mesh.geometry?.computeBoundingBox();
  }
  // static Group createCircle(Vector3 position, Euler rotation){
  //   Group objects = Group()..name = 'circle';
  //   objects.add(creatPoint(position,0xff0000));

  //   Group line = Group()..name = 'circleLines';
  //   final int segments = 64;
  //   final double radius = 1;
  //   final double thetaStart = math.pi/8;
  //   final Vector3 vertex = Vector3();
  //   final previous = Vector3();
  //   final firstVector = Vector3();
    
  //   for (int s = 0, i = 3; s <= segments; s++, i += 3) {
  //     final segment = thetaStart + s / segments * math.pi * 2;
  //     vertex.x = radius * math.cos(segment);
  //     vertex.y = radius * math.sin(segment);
  //     if(s == 0){
  //       firstVector.setFrom(vertex);
  //       previous.setFrom(vertex);
  //     }
  //     if(s > 0 ){
  //       line.add(create2PointLine(previous,vertex,0xff0000));
  //       previous.setFrom(vertex);
  //     }
  //   };

  //   line..scale = Vector3()
  //   ..rotation.x = rotation.x
  //   ..rotation.y = rotation.y
  //   ..rotation.z = rotation.z
  //   ..position.x = position.x
  //   ..position.y = position.y
  //   ..position.z = position.z;

  //   objects.add(line);
    
  //   return objects;
  // }
  
  static Group createBoxCenter(Vector3 position, int color){
    Group objects = Group()..name = 'boxCenter';
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),color));
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),color));
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),color));
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),color));
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),0xffff00));
    objects.add(createLine(Vector3.copy(position),0xffff00));
    
    return objects;
  }

  static Group createBox2Point(Vector3 position, int color){
    Group objects = Group()..name = 'box2Point';
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),color));
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),color));
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),color));
    objects.add(creatPoint(Vector3.copy(position),color));
    objects.add(createLine(Vector3.copy(position),color));

    return objects;
  }

  static Object3D creatPoint(Vector3 position, int color,[String name = 'point']){
    return Mesh(
        SphereGeometry(0.015,8,8),
        MeshPhongMaterial.fromMap({
          'color': color,
          //'size': 7.5, 
          // 'transparent': color == null? true : false,
          // 'opacity': color == null?0.5:1
        })
      )
      ..name = name
      ..position.x = position.x
      ..position.y = position.y
      ..position.z = position.z;
  }

  static Object3D creatOldPoint(Vector3 position, int color,[String name = 'point']){
    return Points(
        BufferGeometry()..setAttributeFromString(
          'position',
          Float32BufferAttribute.fromList([0,0,0],3)
        ),
        PointsMaterial.fromMap({
          'color': color,
          'size': 7.5, 
          // 'transparent': color == null? true : false,
          // 'opacity': color == null?0.5:1
        })
      )
      ..name = name
      ..position.x = position.x
      ..position.y = position.y
      ..position.z = position.z;
  }

  static Line createLine(Vector3 position, int color, [int segments = 0]){
    final line = createSLine(position, color,segments);
    return line..addAll([createFatLine(position, color,line),creatPoint(position, color,'linePoint'),creatPoint(position, color,'linePoint')]);
  }

  static Line2 createFatLine(Vector3 position, int color, Line line){
    final geometry = LineGeometry().fromLine(line);
    final constructionLine = LineMaterial.fromMap( {
      'color': 0xffff00,
      'linewidth': 2,
    })
    ..worldUnits = false
    ..alphaToCoverage = true
    ..dashScale = 10
    ..dashed = true;
    
    final matLine = LineMaterial.fromMap( {
      'color': color,
      'linewidth': 2, // in world units with size attenuation, pixels otherwise
    })
    ..worldUnits = false;

    return Line2( geometry, color == 0xffff00?constructionLine:matLine)
    ..name = 'line2'
    ..userData['construction'] = color == 0xffff00
    ..computeLineDistances();
  }

  static Line createSLine(Vector3 position, int color, [int segments = 0]){
    final geometry = BufferGeometry();
    geometry.setAttributeFromString(
      'position',
      segments == 0?Float32BufferAttribute.fromList(position.storage+position.storage,3):Float32BufferAttribute( Float32Array( segments * 3 ), 3 )
    );
    final constructionLine = LineDashedMaterial.fromMap( {
      'color': 0xffff00,
      'transparent': true,
      'opacity': 0.5,
      'linewidth': 5,
      'gapSize': 1,
      'dashSize': 0.5
    });

    final matLine = LineBasicMaterial.fromMap( {
      'color': color,//construction?0xffff00:215910,
      'transparent': false,
      'visible': false,
      'linewidth': 5
    });

    return Line( geometry, matLine )
    ..name = 'line'
    ..computeLineDistances()
    ..userData['construction'] = color == 0xffff00;
  }
  // static Line create2PointLine(Vector3 position1,Vector3 position2,int color){
  //   final geometry = BufferGeometry();
  //   geometry.setAttributeFromString(
  //     'position',
  //     Float32BufferAttribute.fromList(position1.storage+position2.storage,3)
  //   );
  //   final constructionLine = LineDashedMaterial.fromMap( {
  //     'color': 0xffff00,
  //     'transparent': true,
  //     'opacity': 0.5,
  //     'linewidth': 5,
  //     'gapSize': 1,
  //     'dashSize': 3
  //   });

  //   final matLine = LineBasicMaterial.fromMap( {
  //     'color': color,//construction?0xffff00:215910,
  //     'transparent': false,
  //     'linewidth': 5
  //   });

  //   return Line( geometry, matLine )
  //   ..name = 'line'
  //   ..computeLineDistances()
  //   ..userData['construction'] = color == 0xffff00;
  // }
}