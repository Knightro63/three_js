import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'capsule.dart';

class OctreeData{
  OctreeData({
    required this.normal,
    this.point,
    required this.depth
  });

  Vector3? point;
  Vector3 normal;
  num depth;
}

class OctreeRay{
  OctreeRay({
    required this.distance,
    required this.position,
    required this.triangle
  });

  double distance; 
  Triangle triangle; 
  Vector3 position;
}

class Octree{
	Octree([BoundingBox? box]){
    this.box = box ?? BoundingBox();
		triangles = [];
		subTrees = [];
	}

  late List<Triangle> triangles;
  late BoundingBox box;
  BoundingBox? bounds;
  late List<Octree> subTrees;

	final Vector3 _v1 = Vector3();
	final Vector3 _v2 = Vector3();
	final Plane _plane = Plane();
	final Line3 _line1 = Line3();
	final Line3 _line2 = Line3();
	final BoundingSphere _sphere = BoundingSphere();
	final Capsule _capsule = Capsule();

  List<Triangle> getRayTriangles(Ray ray, List<Triangle> triangles) {
    for (int i = 0; i < subTrees.length; i ++ ) {
      Octree subTree = subTrees[i];
      if(!ray.intersectsBox(subTree.box)) continue;
      if(subTree.triangles.isNotEmpty){
        for(int j = 0; j < subTree.triangles.length; j ++ ) {
          if(triangles.contains(subTree.triangles[j])){ 
            triangles.add(subTree.triangles[j]);
          }
        }
      } 
      else {
        subTree.getRayTriangles( ray, triangles );
      }
    }

    return triangles;
  }
  List<Triangle> getSphereTriangles(BoundingSphere sphere, List<Triangle> triangles) {
    for (int i = 0; i < subTrees.length; i ++ ) {
      Octree subTree = subTrees[ i ];
      if (!sphere.intersectsBox(subTree.box)) continue;
      if ( subTree.triangles.isNotEmpty) {
        for (int j = 0; j < subTree.triangles.length; j ++ ) {
          if(!triangles.contains(subTree.triangles[j])){
            triangles.add( subTree.triangles[ j ] );
          } 
        }
      } 
      else {
        subTree.getSphereTriangles(sphere, triangles);
      }
    }

    return triangles;
  }
  List<Triangle> getCapsuleTriangles(Capsule capsule, List<Triangle> triangles){
    for (int i = 0; i < subTrees.length; i ++ ) {
      Octree subTree = subTrees[i];
      if(!capsule.intersectsBox(subTree.box)) continue;
      if(subTree.triangles.isNotEmpty){
        for(int j = 0; j < subTree.triangles.length; j ++ ) {
          if(!triangles.contains(subTree.triangles[j])){
            triangles.add( subTree.triangles[ j ] );
          }
        }
      } 
      else {
        subTree.getCapsuleTriangles( capsule, triangles );
      }
    }

    return triangles;
  }

  void addTriangle(Triangle triangle){
    bounds ??= BoundingBox();
    bounds!.min.x = math.min(math.min(bounds!.min.x, triangle.a.x), math.min(triangle.b.x, triangle.c.x ));
    bounds!.min.y = math.min(math.min(bounds!.min.y, triangle.a.y), math.min(triangle.b.y, triangle.c.y ));
    bounds!.min.z = math.min(math.min(bounds!.min.z, triangle.a.z), math.min(triangle.b.z, triangle.c.z ));
    
    bounds!.max.x = math.max(math.max(bounds!.max.x, triangle.a.x), math.max(triangle.b.x, triangle.c.x ));
    bounds!.max.y = math.max(math.max(bounds!.max.y, triangle.a.y), math.max(triangle.b.y, triangle.c.y ));
    bounds!.max.z = math.max(math.max(bounds!.max.z, triangle.a.z), math.max(triangle.b.z, triangle.c.z ));

    triangles.add(triangle);
  }
  void calcBox(){
    box = bounds!.clone();

    // offset small ammount to account for regular grid
    box.min.x -= 0.01;
    box.min.y -= 0.01;
    box.min.z -= 0.01;
  }
  void split(int level){
    List<Octree> subTrees = [];
    Vector3 halfsize = _v2.setFrom(box.max).sub(box.min).scale(0.5);

    for (int x = 0; x < 2; x ++ ) {
      for (int y = 0; y < 2; y ++ ) {
        for (int z = 0; z < 2; z ++ ) {
          BoundingBox box = BoundingBox();
          final Vector3 v = _v1.setValues(x.toDouble(), y.toDouble(), z.toDouble());
          box.min.setFrom(this.box.min).add(v.multiply(halfsize));
          box.max.setFrom(box.min).add(halfsize);
          subTrees.add(Octree(box));
        }
      }
    }

    while(triangles.isNotEmpty){
      Triangle triangle = triangles.removeLast();
      for (int i = 0; i < subTrees.length; i ++ ) {
        if(subTrees[i].box.intersectsTriangle(triangle)){
          subTrees[i].triangles.add(triangle);
        }
      }
    }

    for (int i = 0; i < subTrees.length; i ++ ) {
      int len = subTrees[i].triangles.length;
      if (len > 8 && level < 16) {
        subTrees[ i ].split( level + 1 );
      }
      if ( len != 0 ) {
        this.subTrees.add(subTrees[i]);
      }
    }
  }
  void build(){
    calcBox();
    split(0);
  }
  OctreeData? triangleCapsuleIntersect(Capsule capsule, Triangle triangle) {
    Vector3 point1, point2;
    Line3 line1, line2;

    triangle.getPlane( _plane );

    double d1 = _plane.distanceToPoint( capsule.start ) - capsule.radius;
    double d2 = _plane.distanceToPoint( capsule.end ) - capsule.radius;

    if(( d1 > 0 && d2 > 0 ) || ( d1 < - capsule.radius && d2 < - capsule.radius)){
      return null;
    }

    double delta = (d1/(d1.abs() + d2.abs())).abs();
    Vector3 intersectPoint = _v1.setFrom( capsule.start ).lerp( capsule.end, delta );

    if(triangle.containsPoint( intersectPoint)){
      return OctreeData(normal: _plane.normal.clone(), point: intersectPoint.clone(), depth: math.min( d1, d2).abs());
    }

    double r2 = capsule.radius * capsule.radius;

    line1 = _line1.setStartEnd( capsule.start, capsule.end );

    List<List<Vector3>> lines = [
      [ triangle.a, triangle.b ],
      [ triangle.b, triangle.c ],
      [ triangle.c, triangle.a ]
    ];

    for (int i = 0; i < lines.length; i++){
      line2 = _line2.setStartEnd( lines[ i ][ 0 ], lines[ i ][ 1 ] );

      List<Vector3> pt = capsule.lineLineMinimumPoints( line1, line2 );
      point1  = pt[0];
      point2 = pt[1];
      if ( point1.distanceToSquared( point2 ) < r2 ) {
        return OctreeData(normal: point1.clone().sub( point2 ).normalize(), point: point2.clone(), depth: capsule.radius - point1.distanceTo( point2 ));
      }
    }

    return null;
  }
  OctreeData? triangleSphereIntersect(BoundingSphere sphere, Triangle triangle ) {
    triangle.getPlane( _plane );

    if(!sphere.intersectsPlane( _plane )) return null;
    double depth = _plane.distanceToSphere( sphere ).abs();
    double r2 = sphere.radius * sphere.radius - depth * depth;

    Vector3 plainPoint = _plane.projectPoint( sphere.center, _v1 );

    if ( triangle.containsPoint( sphere.center ) ) {
      return OctreeData(normal: _plane.normal.clone(), point: plainPoint.clone(), depth: _plane.distanceToSphere(sphere).abs());
    }

    List<List<Vector3>> lines = [
      [ triangle.a, triangle.b ],
      [ triangle.b, triangle.c ],
      [ triangle.c, triangle.a ]
    ];

    for (int i = 0; i < lines.length; i ++ ) {
      _line1.setStartEnd( lines[ i ][ 0 ], lines[ i ][ 1 ] );
      _line1.closestPointToPoint( plainPoint, true, _v2 );

      double d = _v2.distanceToSquared( sphere.center );

      if ( d < r2 ) {
        return OctreeData(normal: sphere.center.clone().sub( _v2 ).normalize(), point: _v2.clone(), depth: sphere.radius - math.sqrt(d));
      }
    }

    return null;
  }
  OctreeData? sphereIntersect(BoundingSphere sphere){
    _sphere.setFrom(sphere);

    List<Triangle> triangles = getSphereTriangles(_sphere, []);
    bool hit = false;

    for(int i = 0; i < triangles.length; i ++ ) {
      OctreeData? result = triangleSphereIntersect(_sphere, triangles[i]);
      if(result != null) {
        hit = true;
        _sphere.center.add(result.normal.scale(result.depth));
      }
    }

    if(hit){
      Vector3 collisionVector = _sphere.center.clone().sub(sphere.center);
      num depth = collisionVector.length;
      return OctreeData(normal: collisionVector.normalize(), depth: depth);
    }

    return null;
  }
  OctreeData? capsuleIntersect(Capsule capsule){
    _capsule.copy(capsule);

    List<Triangle> triangles = getCapsuleTriangles(_capsule, []); 
    bool hit = false;
    for(int i = 0; i < triangles.length; i ++ ) {
      OctreeData? result = triangleCapsuleIntersect(_capsule, triangles[i]);
      if (result != null){
        hit = true;
        _capsule.translate(result.normal.scale(result.depth));
      }
    }

    if(hit){
      Vector3 collisionVector = _capsule.getCenter(Vector3()).sub( capsule.getCenter(_v1));
      double depth = collisionVector.length;
      return OctreeData(normal: collisionVector.normalize(), depth: depth);
    }

    return null;
  }
  void fromGraphNode(Object3D group){
    group.updateWorldMatrix(true, true);
    group.traverse((object){
      if(object is Mesh){
        Mesh obj = object;
        late BufferGeometry geometry;
        bool isTemp = false;

        if(obj.geometry!.index != null){
          isTemp = true;
          geometry = obj.geometry!.clone().toNonIndexed();
        } 
        else {
          geometry = obj.geometry!;
        }

			  BufferAttribute positionAttribute = geometry.getAttributeFromString('position');

				for(int i = 0; i < positionAttribute.count; i += 3) {
					Vector3 v1 = Vector3().fromBuffer(positionAttribute, i);
					Vector3 v2 = Vector3().fromBuffer(positionAttribute, i + 1);
					Vector3 v3 = Vector3().fromBuffer(positionAttribute, i + 2);

					v1.applyMatrix4(obj.matrixWorld);
					v2.applyMatrix4(obj.matrixWorld);
					v3.applyMatrix4(obj.matrixWorld);

					addTriangle(Triangle(v1, v2, v3));
				}

        if(isTemp){
          geometry.dispose();
        }
      }
    });

    build();
  }
  OctreeRay? rayIntersect(Ray ray) {
    if(ray.direction.length == 0) return null;

    List<Triangle> triangles = getRayTriangles(ray, []);
    late Triangle triangle; 
    late Vector3 position;
    double distance = 1e100;
    Vector3? result;

    for (int i = 0; i < triangles.length; i ++) {
      result = ray.intersectTriangle( triangles[i].a, triangles[i].b, triangles[i].c, true, _v1 );
      if(result != null){
        double newdistance = result.sub(ray.origin).length;

        if ( distance > newdistance ) {
          position = result.clone().add(ray.origin);
          distance = newdistance;
          triangle = triangles[i];
        }
      }
    }

    return distance < 1e100 ? OctreeRay(distance: distance, triangle: triangle, position: position) : null;
  }
}