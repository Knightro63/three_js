import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

extension on Vector4{
  Vector4 copyFromVector3(Vector3 v){
    x = v.x;
    y = v.y;
    z = v.z;
    w = 1;

    return this;
  }
  Vector3 toVector3(){
    return Vector3(x.toDouble(),y.toDouble(),z.toDouble());
  }
}
extension on Vector3{
  Vector3 crossFromVector4(Vector4 v, {Vector4? w}) {
    if (w != null) {
      //print('Vector3: .cross() now only accepts one argument. Use .crossVectors( a, b ) instead.');
      return cross2(v.toVector3(), w.toVector3());
    }

    return cross2(this, v.toVector3());
  }
  Vector4 toVector4(){
    return Vector4(x,y,z,1);
  }
}

class RenderableObject extends Object3D{
  RenderableObject({
    id = 0,
    this.object,
    this.z = 0,
    renderOrder = 0
  });

  num z;
  Object3D? object;
}
class RenderableFace extends RenderableObject{
  RenderableFace({
    int id = 0,
    RenderableVertex? v1,
    RenderableVertex? v2,
    RenderableVertex? v3,
    Vector3? normalModel,
    List<Vector3>? vertexNormalsModel,
    Color? color,
    material,
    List<Vector2>? uvs,
    num z = 0,
    this.vertexNormalsLength = 0,
    int renderOrder = 0,
  }){
    this.id = id;
    this.z = z;
    this.renderOrder = renderOrder;
    this.v1 = v1 ?? RenderableVertex();
    this.v2 = v2 ?? RenderableVertex();
    this.v3 = v3 ?? RenderableVertex();
    this.normalModel = normalModel ?? Vector3();
    this.color = color ?? Color();
    this.vertexNormalsModel = vertexNormalsModel ?? [Vector3(), Vector3(), Vector3()];
    this.uvs = uvs ?? [Vector2(), Vector2(), Vector2()];
  }

  late RenderableVertex v1;
  late RenderableVertex v2;
  late RenderableVertex v3;
  late Vector3 normalModel;
  late List<Vector3> vertexNormalsModel;
  int vertexNormalsLength;
  late Color color;
  //Material? material;
  late List<Vector2> uvs;
} 
class RenderableVertex extends RenderableObject{
  RenderableVertex({
    Vector3? position,
    Vector3? positionWorld,
    Vector4? positionScreen,
    bool visible = true,
  }){
    this.visible = visible;
    this.position = position ?? Vector3();
    this.positionWorld = positionWorld ?? Vector3();
    this.positionScreen = positionScreen ?? Vector4();
  }

  late Vector3 positionWorld;
  late Vector4 positionScreen;

  @override
  Object3D copy(Object3D source, [bool? recursive]){
    if(source is RenderableVertex){
      positionWorld.setFrom(source.positionWorld);
      positionScreen.setFrom(source.positionScreen);
    }
    return source;
  }
}
class RenderableLine extends RenderableObject{
  RenderableLine({
    int id = 0,
    RenderableVertex? v1,
    RenderableVertex? v2,
    List<Color>? vertexColors,
    Material? material,
    num z = 0,
    int renderOrder = 0,
  }){
    this.z = z;
    this.id = id;
    this.material = material;
    this.renderOrder = renderOrder;
    this.v1 = v1 ?? RenderableVertex();
    this.v2 = v2 ?? RenderableVertex();
    this.vertexColors = vertexColors ?? [Color(),Color()];
  }
  late RenderableVertex v1;
  late RenderableVertex v2;
  late List<Color> vertexColors;
}
class RenderableSprite extends RenderableObject{
  RenderableSprite({
    int id = 0,
    Object3D? object,
    this.x = 0,
    this.y = 0,
    num z = 0,
    Euler? rotation,
    Vector3? scale,
    Material? material,
    int renderOrder = 0,
  }){
    this.z = z;
    this.id = id;
    this.object = object;
    this.material = material;
    this.renderOrder = renderOrder;
    this.scale = scale ?? Vector3();
    this.rotation = rotation ?? Euler();
  }

  num x;
  num y;
}
class RenderData extends RenderableObject{
  List<RenderableObject> objects = [];
  List<Light> lights = [];
  List<RenderableObject> elements = [];
}

class Projector{
  //RenderList renderList = RenderList();
  final RenderData _renderData = RenderData();
  final Frustum _frustum = Frustum();
  late int _objectCount;
  final List<RenderableObject> _objectPool = [];
  int _objectPoolLength = 0;

  late RenderableObject _object;
  late RenderableVertex _vertex;
  late int _vertexCount;
  int _vertexPoolLength = 0;
  late RenderableFace _face;
  late int _faceCount;
  int _facePoolLength = 0;
  late RenderableLine _line;
  late int _lineCount;
  int _linePoolLength = 0;
  late RenderableSprite _sprite;
  late int _spriteCount;
  int _spritePoolLength = 0;
  Matrix4 _modelMatrix = Matrix4();

  final Vector3 _vector3 = Vector3();
  final Vector4 _vector4 = Vector4.identity();
  final BoundingBox _clipBox = BoundingBox( Vector3( - 1, - 1, - 1 ), Vector3( 1, 1, 1 ) );
  final BoundingBox _boundingBox = BoundingBox();
  final List<Vector3> _points3 = List.filled(3, Vector3());
  final Matrix4 _viewMatrix = Matrix4.identity();
  final Matrix4 _viewProjectionMatrix = Matrix4.identity();
  final Matrix4 _modelViewProjectionMatrix = Matrix4.identity();

  final List<RenderableVertex> _vertexPool = [];
  final List<RenderableFace> _facePool = [];
  final List<RenderableLine> _linePool = [];
  final List<RenderableSprite> _spritePool = []; //

  List<double> normals = [];
  List<double> colors = [];
  List<double> uvs = [];
  late Object3D object;

  Matrix3 normalMatrix = Matrix3.identity();
  
  void setObject(Object3D value){
    object = value;
    normalMatrix.getNormalMatrix(object.matrixWorld);
    normals = [];
    colors = [];
    uvs = [];
  }
  void projectVertex(RenderableVertex vertex){
    Vector3 position = vertex.position;
    Vector3 positionWorld = vertex.positionWorld;
    Vector4 positionScreen = vertex.positionScreen;
    positionWorld.setFrom(position).applyMatrix4( _modelMatrix );
    positionScreen.copyFromVector3( positionWorld ).applyMatrix4(_viewProjectionMatrix);
    double invW = 1 / positionScreen.w;
    positionScreen.x *= invW;
    positionScreen.y *= invW;
    positionScreen.z *= invW;
    vertex.visible = positionScreen.x >= - 1 && positionScreen.x <= 1 && positionScreen.y >= - 1 && positionScreen.y <= 1 && positionScreen.z >= - 1 && positionScreen.z <= 1;
  }
  void pushVertex(double x, double y,double z){
    _vertex = getNextVertexInPool();
    _vertex.position.setValues( x, y, z );
    projectVertex( _vertex );
  }

  bool checkTriangleVisibility(RenderableVertex v1, RenderableVertex v2, RenderableVertex v3) {
    if(v1.visible == true || v2.visible == true || v3.visible == true) return true;
    _points3[0] = v1.positionScreen.toVector3();
    _points3[1] = v2.positionScreen.toVector3();
    _points3[2] = v3.positionScreen.toVector3();
    return _clipBox.intersectsBox(_boundingBox.setFromPoints(_points3));
  }
  bool checkBackfaceCulling(RenderableVertex v1,RenderableVertex v2,RenderableVertex v3 ) {
    return 
      (v3.positionScreen.x - v1.positionScreen.x ) * 
      ( v2.positionScreen.y - v1.positionScreen.y ) - 
      ( v3.positionScreen.y - v1.positionScreen.y ) * 
      ( v2.positionScreen.x - v1.positionScreen.x ) < 0;
  }
  void pushLine(num a,num b) {
    RenderableVertex v1 = _vertexPool[ a.toInt() ];
    RenderableVertex v2 = _vertexPool[ b.toInt() ]; // Clip

    v1.positionScreen.copyFromVector3(v1.position).applyMatrix4( _modelViewProjectionMatrix );
    v2.positionScreen.copyFromVector3(v2.position).applyMatrix4( _modelViewProjectionMatrix );

    if (clipLine( v1.positionScreen, v2.positionScreen )){
      // Perform the perspective divide
      v1.positionScreen.scale( 1 / v1.positionScreen.w );
      v2.positionScreen.scale( 1 / v2.positionScreen.w );

      _line = getNextLineInPool();
      _line.id = object.id;
      _line.v1.copy( v1 );
      _line.v2.copy( v2 );
      _line.z = math.max( v1.positionScreen.z, v2.positionScreen.z );
      _line.renderOrder = object.renderOrder;
      _line.material = object.material;

      if(object.material?.vertexColors != null) {
        _line.vertexColors[0].copyFromArray( colors, (a * 3).toInt() );
        _line.vertexColors[1].copyFromArray( colors, (b * 3).toInt() );
      }
      _renderData.elements.add( _line );
    }
  }

  void pushTriangle(num a,num b,num c, Material material){
    RenderableVertex v1 = _vertexPool[ a.toInt() ];
    RenderableVertex v2 = _vertexPool[ b.toInt() ];
    RenderableVertex v3 = _vertexPool[ c.toInt() ];
    if(!checkTriangleVisibility( v1, v2, v3 )) return;

    if(material.side == DoubleSide || checkBackfaceCulling( v1, v2, v3 )){
      _face = getNextFaceInPool();
      _face.id = object.id;

      _face.v1.copy( v1 );
      _face.v2.copy( v2 );
      _face.v3.copy( v3 );

      _face.z = ( v1.positionScreen.z + v2.positionScreen.z + v3.positionScreen.z ) / 3;
      _face.renderOrder = object.renderOrder; // face normal

      _vector3.sub2( v3.position, v2.position );
      _vector4.sub2( v1.position.toVector4(), v2.position.toVector4());
      _vector3.crossFromVector4( _vector4 );

      _face.normalModel.setFrom( _vector3 );
      _face.normalModel.applyMatrix3( normalMatrix ).normalize();

      for(int i = 0; i < 3; i++){
        Vector3 normal = _face.vertexNormalsModel[i];
        normal.copyFromArray(normals);//arguments[i] * 3 
        normal.applyMatrix3(normalMatrix).normalize();
        Vector2 uv = _face.uvs[i];
        if(uvs.isNotEmpty){
          uv.copyFromArray(uvs);//arguments[i] * 2
        }
      }

      _face.vertexNormalsLength = 3;
      _face.material = material;

      if ( material.vertexColors ) {
        _face.color.copyFromArray( colors, (a * 3).toInt() );
      }
      _renderData.elements.add( _face );
    }
  }

  void projectObject(Object3D object){
    if (!object.visible) return;
    if (object is Light){
      _renderData.lights.add( object );
    } 
    else if (object is Mesh || object is Line || object is Points) {
      if(!object.material!.visible) return;
      if (object.frustumCulled && !_frustum.intersectsObject( object )) return;
      addObject( object );
    } 
    else if (object is Sprite ) {
      if(!object.material!.visible) return;
      if(object.frustumCulled && !_frustum.intersectsSprite(object)) return;
      addObject( object );
    }

    List<Object3D> children = object.children;
    if(children.isNotEmpty){
      for(int i = 0; i < children.length; i ++) {
        projectObject(children[i]);
      }
    }
  }
  void addObject(Object3D object){
    _object = getNextObjectInPool();
    _object.id = object.id;
    _object.object = object;

    _vector3.setFromMatrixPosition( object.matrixWorld );
    _vector3.applyMatrix4( _viewProjectionMatrix );

    _object.z = _vector3.z;
    _object.renderOrder = object.renderOrder;

    _renderData.objects.add(_object);
  }
  RenderData projectScene(Scene scene,Camera camera, sortObjects, sortElements){
    _faceCount = 0;
    _lineCount = 0;
    _spriteCount = 0;
    _renderData.elements.length = 0;
    if(scene.autoUpdate) scene.updateMatrixWorld();
    if(camera.parent == null) camera.updateMatrixWorld();

    _viewMatrix.setFrom( camera.matrixWorldInverse );
    _viewProjectionMatrix.multiply2( camera.projectionMatrix, _viewMatrix );
    _frustum.setFromMatrix( _viewProjectionMatrix ); //

    _objectCount = 0;
    _renderData.objects.length = 0;
    _renderData.lights.length = 0;
    projectObject(scene);

    if(sortObjects) {
      _renderData.objects.sort(painterSort);
    } 
    
    List<RenderableObject> objects = _renderData.objects;

    for(int o = 0; o < objects.length; o ++) {
      Object3D object = objects[o].object!;
      BufferGeometry? geometry = object.geometry;
      setObject(object);
      _modelMatrix = object.matrixWorld;
      _vertexCount = 0;

      if(object is Mesh){
        Material? material = object.material;
        bool isMultiMaterial = material is GroupMaterial;
        Map<String,dynamic> attributes = geometry!.attributes;
        List<Map<String, dynamic>> groups = geometry.groups;
        if (attributes['position'] == null) continue;
        NativeArray<double> positions = attributes['position'].array;
        for(int i = 0; i < positions.length; i += 3) {
          double x = positions[i];
          double y = positions[i + 1];
          double z = positions[i + 2];
          List<BufferAttribute>? morphTargets = geometry.morphAttributes['position'];

          if(morphTargets != null){
            bool morphTargetsRelative = geometry.morphTargetsRelative;
            List<num>? morphInfluences = object.morphTargetInfluences;

            for (int t = 0; t < morphTargets.length; t ++) {
              num influence = morphInfluences![t];
              if(influence == 0) continue;
              BufferAttribute? target = morphTargets[t];
              if (morphTargetsRelative) {
                x += target.getX( i ~/ 3 ) !* influence;
                y += target.getY( i ~/ 3 ) !* influence;
                z += target.getZ( i ~/ 3 ) !* influence;
              } 
              else {
                x += ( target.getX( i ~/ 3 ) !- positions[ i ] ) * influence;
                y += ( target.getY( i ~/ 3 ) !- positions[ i + 1 ] ) * influence;
                z += ( target.getZ( i ~/ 3 ) !- positions[ i + 2 ] ) * influence;
              }
            }
          }

          pushVertex( x, y, z );
        }

        if (attributes['normal'] != null){
          NativeArray<double> normals = attributes['normal'].array;
          this.normals += normals.toDartList();
          // for (int i = 0; i < normals.length; i += 3) {
          //   pushNormal(normals[i],normals[i+1], normals[i+2]);
          // }
        }
        if ( attributes['color'] != null){
          NativeArray<double> colors = attributes['color'].array;
          this.colors += colors.toDartList();
          // for(int i = 0; i < colors.length; i += 3 ) {
          //   pushColor( colors[ i ], colors[ i + 1 ], colors[ i + 2 ] );
          // }
        }
        if(attributes['uv'] != null ) {
          NativeArray<double> uvs = attributes['uv'].array;
          this.uvs += uvs.toDartList();
          // for (int i = 0; i < uvs.length; i += 2 ) {
          //   pushUv( uvs[i], uvs[i + 1]);
          // }
        }
        if ( geometry.index != null){
          NativeArray<num> indices = geometry.index!.array;
          if(groups.isNotEmpty){
            for(int g = 0; g < groups.length; g++) {
              Map<String, dynamic> group = groups[g];
              material = isMultiMaterial == true ? (object.material as GroupMaterial).children[group['materialIndex']] : object.material;
              if(material != null) continue;
              for (int i = group['start']; i < group['start'] + group['count']; i += 3 ) {
                pushTriangle( indices[ i ], indices[ i + 1 ], indices[ i + 2 ], material! );
              }
            }
          } 
          else {
            for (int i = 0; i < indices.length; i += 3 ) {
              pushTriangle( indices[ i ], indices[ i + 1 ], indices[ i + 2 ], material! );
            }
          }
        } 
        else {
          if(groups.isNotEmpty) {
            for (int g = 0; g < groups.length; g ++ ) {
              dynamic group = groups[g];
              material = isMultiMaterial == true ? (object.material as GroupMaterial).children[ group.materialIndex ] : object.material;
              if ( material == null ) continue;
              for (int i = group.start, l = group.start + group.count; i < l; i += 3 ) {
                pushTriangle( i, i + 1, i + 2, material );
              }
            }
          } 
          else {
            for (int i = 0, l = positions.length ~/ 3; i < l; i += 3 ) {
              pushTriangle( i, i + 1, i + 2, material! );
            }
          }
        }
      } 
      else if(object is Line) {
        _modelViewProjectionMatrix.multiply2( _viewProjectionMatrix, _modelMatrix );
        Map<String, dynamic> attributes = geometry!.attributes;

        if(attributes['position'] != null){
          NativeArray<num> positions = attributes['position'].array;
          for ( int i = 0, l = positions.length; i < l; i += 3 ) {
            pushVertex( positions[i].toDouble(), positions[i + 1].toDouble(), positions[i + 2].toDouble());
          }

          if (attributes['color'] != null ) {
            NativeArray<double> colors = attributes['color'].array;
            // for (int i = 0, l = colors.length; i < l; i += 3 ) {
            //   pushColor( colors[ i ].toDouble(), colors[ i + 1 ].toDouble(), colors[ i + 2 ].toDouble());
            // }
            this.colors += colors.toDartList();
          }

          if (geometry.index != null){
            NativeArray indices = geometry.index!.array;
            for (int i = 0, l = indices.length; i < l; i += 2 ) {
              pushLine( indices[i], indices[ i + 1 ] );
            }
          } else {
            int step = object is LineSegments ? 2 : 1;
            for (int i = 0, l = positions.length ~/ 3 - 1; i < l; i += step ) {
              pushLine( i, i + 1 );
            }
          }
        }
      } 
      else if(object is Points){
        _modelViewProjectionMatrix.multiply2( _viewProjectionMatrix, _modelMatrix );
        Map<String, dynamic> attributes = geometry!.attributes;
        if ( attributes['position'] != null ) {
          NativeArray<num> positions = attributes['position'].array;
          for ( int i = 0, l = positions.length; i < l; i += 3 ) {
            _vector4.setValues( positions[ i ].toDouble(), positions[ i + 1 ].toDouble(), positions[ i + 2 ].toDouble(), 1 );
            _vector4.applyMatrix4( _modelViewProjectionMatrix );
            pushPoint( _vector4, object, camera );
          }
        }
      } 
      else if(object is Sprite){
        object.modelViewMatrix.multiply2( camera.matrixWorldInverse, object.matrixWorld );
        _vector4.setValues( _modelMatrix.storage[ 12 ], _modelMatrix.storage[ 13 ], _modelMatrix.storage[ 14 ], 1 );
        _vector4.applyMatrix4( _viewProjectionMatrix );
        pushPoint( _vector4, object, camera );
      }
    }
    if(sortElements){
      _renderData.elements.sort(painterSort);
    }

    return _renderData;
  }
  void pushPoint(Vector4 newVector4, Object3D object, Camera camera) {
    double invW = 1 / newVector4.w;
    newVector4.z *= invW;
    if ( newVector4.z >= - 1 && newVector4.z <= 1 ) {
      _sprite = getNextSpriteInPool();
      _sprite.id = object.id;
      _sprite.x = newVector4.x * invW;
      _sprite.y = newVector4.y * invW;
      _sprite.z = newVector4.z;
      _sprite.renderOrder = object.renderOrder;
      _sprite.object = object;
      _sprite.rotation = object.rotation;
      _sprite.scale.x = object.scale.x * ( _sprite.x - ( newVector4.x + camera.projectionMatrix.storage[ 0 ] ) / ( newVector4.w + camera.projectionMatrix.storage[ 12 ] ) ).abs();
      _sprite.scale.y = object.scale.y * ( _sprite.y - ( newVector4.y + camera.projectionMatrix.storage[ 5 ] ) / ( newVector4.w + camera.projectionMatrix.storage[ 13 ] ) ).abs();
      _sprite.material = object.material;
      _renderData.elements.add( _sprite );
    }
  }

  RenderableObject getNextObjectInPool() {
    if ( _objectCount == _objectPoolLength ) {
      RenderableObject object = RenderableObject();
      _objectPool.add( object );
      _objectPoolLength ++;
      _objectCount ++;
      return object;
    }
    return _objectPool[ _objectCount ++ ];
  }
  RenderableVertex getNextVertexInPool() {
    if(_vertexCount == _vertexPoolLength){
      RenderableVertex vertex = RenderableVertex();
      _vertexPool.add(vertex);
      _vertexPoolLength ++;
      _vertexCount ++;
      return vertex;
    }
    return _vertexPool[_vertexCount++];
  }
  RenderableFace getNextFaceInPool() {
    if(_faceCount == _facePoolLength){
      RenderableFace face = RenderableFace();
      _facePool.add( face );
      _facePoolLength ++;
      _faceCount ++;
      return face;
    }
    return _facePool[ _faceCount ++ ];
  }
  RenderableLine getNextLineInPool() {
    if ( _lineCount == _linePoolLength ) {
      RenderableLine line = RenderableLine();
      _linePool.add( line );
      _linePoolLength ++;
      _lineCount ++;
      return line;
    }
    return _linePool[ _lineCount ++ ];
  }
  RenderableSprite getNextSpriteInPool() {
    if(_spriteCount == _spritePoolLength){
      RenderableSprite sprite = RenderableSprite();
      _spritePool.add(sprite);
      _spritePoolLength ++;
      _spriteCount ++;
      return sprite;
    }
    return _spritePool[_spriteCount++];
  }
  int painterSort(RenderableObject a, RenderableObject b ) {
    if (a.renderOrder != b.renderOrder) {
      return (a.renderOrder - b.renderOrder).toInt();
    } else if (a.z != b.z) {
      return (b.z - a.z).toInt();
    } else if (a.id != b.id) {
      return a.id - b.id;
    } else {
      return 0;
    }
  }
  bool clipLine(Vector4 s1,Vector4 s2 ) {
    double alpha1 = 0;
    double alpha2 = 1; // Calculate the boundary coordinate of each vertex for the near and far clip planes,
    // Z = -1 and Z = +1, respectively.

    num bc1near = s1.z + s1.w,
      bc2near = s2.z + s2.w,
      bc1far = - s1.z + s1.w,
      bc2far = - s2.z + s2.w;

    if ( bc1near >= 0 && bc2near >= 0 && bc1far >= 0 && bc2far >= 0 ) {
      // Both vertices lie entirely within all clip planes.
      return true;
    } else if ( bc1near < 0 && bc2near < 0 || bc1far < 0 && bc2far < 0 ) {
      // Both vertices lie entirely outside one of the clip planes.
      return false;
    } else {
      // The line segment spans at least one clip plane.
      if ( bc1near < 0 ) {
        // v1 lies outside the near plane, v2 inside
        alpha1 = math.max( alpha1, bc1near / ( bc1near - bc2near ) );
      } else if ( bc2near < 0 ) {
        // v2 lies outside the near plane, v1 inside
        alpha2 = math.min( alpha2, bc1near / ( bc1near - bc2near ) );
      }

      if ( bc1far < 0 ) {
        // v1 lies outside the far plane, v2 inside
        alpha1 = math.max( alpha1, bc1far / ( bc1far - bc2far ) );
      } else if ( bc2far < 0 ) {
        // v2 lies outside the far plane, v2 inside
        alpha2 = math.min( alpha2, bc1far / ( bc1far - bc2far ) );
      }

      if ( alpha2 < alpha1 ) {
        // The line segment spans two boundaries, but is outside both of them.
        // (This can't happen when we're only clipping against just near/far but good
        //  to leave the check here for future usage if other clip planes are added.)
        return false;

      } else {
        // Update the s1 and s2 vertices to match the clipped line segment.
        s1.lerp( s2, alpha1 );
        s2.lerp( s1, 1 - alpha2 );
        return true;
      }
    }
  }
}
