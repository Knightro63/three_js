import 'package:flutter/material.dart' hide Material;
import 'package:three_js/three_js.dart';
import 'package:three_js_line/three_js_line.dart';

enum DrawType{none,line,arc,circle,boxCenter,boxCorner}

class Sketch{
  Sketch(Object3D plane){
    meshPlane = Mesh(
      PlaneGeometry(10,10),
      MeshBasicMaterial.fromMap({
        'color':0xffffff, 
        'side': DoubleSide, 
        'transparent': true, 
        'opacity': 0
      })
    )
    ..name = 'SketchPlane'
    ..position.setFrom(plane.position)
    ..rotation.setFromRotationMatrix(plane.matrix);

    // final Float32BufferAttribute att = meshPlane.geometry!.getAttributeFromString('position');
    // Vector3 a = Vector3().fromBuffer(att, 0);
    // Vector3 b = Vector3().fromBuffer(att, 3);
    // Vector3 c = Vector3().fromBuffer(att, 6);
    // this.plane = Plane().setFromCoplanarPoints(a, b, c);
  }

  // late Plane plane;
  late Mesh meshPlane;
  Group render = Group();
  List<Object3D> points = [];
  List<Object3D> line = [];
  List<Object3D> toDispose = [];

  void dispose(){
    meshPlane.dispose();
    render.dispose();
    minorDispose();
  }

  void minorDispose(){
    for(final t in toDispose){
      t.dispose();
    }
    toDispose = [];
  }
}

class Draw with EventDispatcher{
  Group drawScene = Group();
  Camera camera;
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;
  DrawType _drawType = DrawType.none;
  DrawType get drawType => _drawType;

  late Object3D origin;
  List<Object3D> _hovered = [];
  final _pointer = Vector2.zero();
  final Raycaster _raycaster = Raycaster();
  List<Intersection> _intersections = [];

  bool _clicking = false;
  bool _newLine = false;
  bool _newLineDidStart = false;

  Sketch? sketch;
  
  Draw(
    this.camera, 
    this.origin, 
    this.listenableKey
  ){
    drawScene.add(origin);
    domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.addEventListener(PeripheralType.pointerHover, onPointerMove);
    hide();
  }

  void hide(){
    drawScene.visible = false;
  }
  void show(){
    drawScene.visible = true;
  }

  void _setupOrigin(){
    origin.visible = false;
    origin.scale.scale(0.25);
    origin.material?.emissive = Color.fromHex32(0xffffff);
    origin.material?.opacity = 1.0;
  }

  void dispose(){
    domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.removeEventListener(PeripheralType.pointerHover, onPointerMove);
  }

  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as RenderBox;
    final size = box.size;
    _pointer.x = ((event.clientX) / size.width * 2 - 1);
    _pointer.y = (-(event.clientY) / size.height * 2 + 1);
  }

  void startSketch(DrawType drawType){
    _drawType = drawType;
    _newLine = true;
    _newLineDidStart = false;
  }
  void endSketch(){
    _drawType = DrawType.none;
    _newLine = false;
    _newLineDidStart = false;
    sketch?.toDispose.add(sketch!.points.last);
    sketch?.toDispose.add(sketch!.line.last);
    sketch?.render.remove(sketch!.points.last);
    sketch?.render.remove(sketch!.line.last);
    sketch?.points.remove(sketch!.points.last);
    sketch?.line.remove(sketch!.line.last);
  }

  void setHighlight(Object3D? object){
    if(object?.name == 'o'){
      origin.visible = true;
    }

    if(object != null){
      object.material?.opacity = 1.0;
      _hovered.add(object);
    }
    
  }
  void clearHighlight(){
    origin.visible = false;
    for(final o in _hovered){
      o.material?.opacity = 0.5;
    }
    _hovered = [];
  }

  List<Intersection> _getAllIntersections(WebPointerEvent event){
    updatePointer(event);
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObjects([sketch!.meshPlane,origin]+sketch!.points,false);
  }
  List<Intersection> _getIntersections(){
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObject(sketch!.meshPlane,false);
  }
  void onPointerMove(WebPointerEvent event) {
    if(sketch != null){
      final intersections = _getAllIntersections(event);
      
      if(intersections.length > 1 && 
        intersections[1].object?.name != 'SketchPlane' && 
        _newLine
      ){
        setHighlight(intersections[1].object);
      }
      else if(intersections.isNotEmpty && 
        intersections[0].object?.name == 'o'
      ){
        setHighlight(intersections[0].object);
      }
      else{
        clearHighlight();
      }

      if(_clicking && _newLine && sketch!.points.isNotEmpty){
        if(intersections.isNotEmpty){
          final intersect = intersections[0];
          sketch!.points.last.position.setFrom(intersect.point!);
          _updateLine(intersect.point!);
        }
      }
    }
  }
  void _updateLine(Vector3 point){
    switch (drawType) {
      case DrawType.line:
        final n = sketch!.points.length-1;
        final v = sketch!.points[n-1].position.clone();
        sketch!.line.last.geometry?.setFromPoints([v, point.clone()]);
        //(sketch!.line.last as Line2).computeLineDistances();
        break;
      default:
    }
  }
  void onPointerDown(WebPointerEvent event) {
    if(sketch != null){
      if(event.button == 0){
        _clicking = true;
        final intersections = _getIntersections();
        Vector3? point;
        if(intersections.isNotEmpty){
          for(final i in _hovered){
            if(i.name == 'o'){
              point = origin.position;
              break;
            }
            if(i.name == 'point'){
              point = i.position;
              break;
            }
          }

          point ??= intersections[0].point!;

          switch (drawType) {
            case DrawType.line:
              drawLine(point);
              break;
            default:
          }
        }
      }
      else{
        _clicking = false;
      }
    }
  }
  void drawLine(Vector3 mousePosition){
    if(_newLine && !_newLineDidStart){
      addPoint(mousePosition);
      addLine(mousePosition);
      addPoint(mousePosition);
      _newLineDidStart = true;
    }
    else{
      sketch!.points.last.position.setFrom(mousePosition);
      _updateLine(mousePosition);
      addLine(mousePosition);
      addPoint(mousePosition);
    }
  }
  void addPoint(Vector3 mousePosition){
    sketch?.points.add(
      Mesh(
        SphereGeometry(0.01,4,4),
        MeshBasicMaterial.fromMap({
          'color': 0x06A7E2,
          'transparent': true,
          'opacity': 0.5
        })
      )
      ..name = 'point'
      ..position.x = mousePosition.x
      ..position.y = mousePosition.y
      ..position.z = mousePosition.z
    );

    sketch?.render.add(sketch?.points.last);
  }
  void addLine(Vector3 mousePosition,[bool construction = false]){
    final geometry = BufferGeometry();
    geometry.setAttributeFromString(
      'position',
      Float32BufferAttribute.fromList(mousePosition.storage+mousePosition.storage,3)
    );
    final matLine = LineBasicMaterial.fromMap( {
      'color': construction?0xffff00:0x06A7E2,
    })
    ..scale = 2
    ..dashSize = 0.0001
    ..gapSize = 0.0001;

    sketch?.line.add(
      Line( geometry, matLine )
      ..computeLineDistances()
      ..userData['construction'] = construction
    );

    sketch?.render.add(sketch?.line.last);
  }
  void addFatLine(Vector3 mousePosition,[bool construction = false]){
    final geometry = LineGeometry();
    geometry.setPositions(Float32Array.fromList(mousePosition.storage+mousePosition.storage));
    final matLine = LineMaterial.fromMap( {
      'color': 0x06A7E2,
      'linewidth': 5, // in world units with size attenuation, pixels otherwise
    })
    ..worldUnits = true;

    sketch?.line.add(
      Line2( geometry, matLine )
      ..userData['construction'] = construction
      ..computeLineDistances()
    );

    sketch?.render.add(sketch?.line.last);
  }
  void start(Sketch sketch){
    show();
    _setupOrigin();
    this.sketch = sketch;

    drawScene.add(sketch.meshPlane);
    drawScene.add(sketch.render);
  }
  void finish(){
    _clicking = false;
    if(_drawType != DrawType.none){
      endSketch();
    }
    
    origin.material?.emissive = Color.fromHex32(0x000000);
    origin.material?.opacity = 0.5;
    origin.scale.scale(4);
    origin.visible = true;

    drawScene.remove(sketch!.meshPlane);
    drawScene.remove(sketch!.render);

    sketch = null;
    hide();
  }
  void cancel(){
    finish();
  }
}