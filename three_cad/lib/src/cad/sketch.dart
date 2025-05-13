import 'dart:math' as math;
import 'package:css/css.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_cad/src/cad/draw_types.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_circle.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_point.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_spline.dart';
import 'package:three_js/three_js.dart';
import 'package:three_js_line/three_js_line.dart';
import 'sketchTypes/sketch_line.dart';

extension on Color{
  mat.Color toFlutterColor(){
    return mat.Color(getHex());
  }

  Color darken([double amount = .1]) {
    return CSS.darken(toFlutterColor(),amount).toThreeColor();
  }

  Color lighten([double amount = .1]) {
    return CSS.lighten(toFlutterColor(),amount).toThreeColor();
  }
}

extension on mat.Color{
  Color toThreeColor(){
    return Color.fromHex64(toARGB32());
  }
}

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
  }

  late Mesh meshPlane;
  Group render = Group();
  List<Object3D> get sketches => render.children;
  List<Object3D> scale = [];
  List<Object3D> toDispose = [];

  bool newSketch = false;
  bool newSketchDidStart = false;
  DrawType drawType = DrawType.none;

  void dispose(){
    meshPlane.dispose();
    render.dispose();
    minorDispose();
  }

  List<Vector3> pointPositions(){
    List<Vector3> p = [];
    for(final o in sketches.last.children){
      if(o.name == 'point'){
        p.add(o.position);
      }
    }
    return p;
  }

  List<Object3D> get allSelectables => _allSelectables();

  List<Object3D> _allSelectables(){
    List<Object3D> o = [];
    for(final gr in sketches){
      if(gr is SketchPoint){
        o.add(gr);
      }
      else{
        for(final g in gr.children){
          if((g is Line || g is SketchPoint) && !ignore.contains(g)){
            o.add(g);
          }
        }
      }
    }
    return o;
  }
  List<Object3D> get ignore => _ignore();
  List<Object3D> _ignore(){
    final cp = sketches.last;
    if(sketches.isNotEmpty && newSketchDidStart){
      if(drawType == DrawType.point){
        return [cp];
      }
      if(DrawType.line == drawType || DrawType.circleCenter == drawType || drawType == DrawType.point || drawType == DrawType.point){
        return cp.children;
      }
      else if(DrawType.spline == drawType){
        return [cp.children.last];
      }
      else if(DrawType.box2Point == drawType){
        final len = sketches.length;
        return cp.children+
        sketches[len-2].children+
        sketches[len-3].children+
        sketches[len-4].children;
      }
     else if(DrawType.boxCenter == drawType){
        final len = sketches.length;
        return cp.children+
        sketches[len-2].children+
        sketches[len-3].children+
        sketches[len-4].children+
        sketches[len-5].children+
        sketches[len-6].children;
      }
    }

    return [];
  }
  void minorDispose(){
    for(final t in toDispose){
      t.dispose();
    }
    toDispose = [];
  }

  void remove(){

  }
  void removeLast(){
    toDispose.add(sketches.last);
    sketches.removeLast();
  }
  void removeCurrent(){
    sketches.removeLast();
  }
}

class Draw with EventDispatcher{
  double scale = 100;
  final mat.ThemeData theme;
  final mat.BuildContext context;
  Group drawScene = Group();
  Camera camera;
  late mat.GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;
  
  Constraints constraintType = Constraints.none;
  bool moveSketch = false;
  DrawType get drawType => sketch?.drawType ?? DrawType.none;
  set drawType(DrawType type){
    sketch?.drawType = type;
  }

  late Object3D origin;
  List<Object3D> _hovered = [];
  final _pointer = Vector2.zero();
  final Raycaster _raycaster = Raycaster()
      ..params['Points']['threshold'] = 0.05
      ..params['Line2'] = {'threshold':0.05}
      ..params['Line']['threshold'] = 0.04;

  Sketch? sketch;
  List<Object3D> selected = [];

  late void Function() update;
  
  Draw(
    this.camera, 
    Object3D origin, 
    this.listenableKey,
    this.theme,
    this.context,
    this.update
  ){
    final color = theme.brightness == mat.Brightness.light?0x000000:0xffffff;
    this.origin = DrawType.creatPoint(Vector3(),color)..name = 'o';
    origin.visible = false;
    drawScene.add(this.origin);
    domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.addEventListener(PeripheralType.pointerHover, onPointerHover);
    domElement.addEventListener(PeripheralType.pointermove, onPointerMove);
    domElement.addEventListener(PeripheralType.pointerup, onPointerUp);
    hide();
  }

  void hide(){
    for(int i = 0; i < (sketch?.sketches.length ?? 0);i++){
      if(sketch?.sketches[i].name == 'dimension'){
        sketch?.sketches[i].visible = false;
      }
    }
    drawScene.visible = false;
  }
  void show(){
    drawScene.visible = true;
  }

  void dispose(){
    domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);
    domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
    domElement.removeEventListener(PeripheralType.pointerHover, onPointerHover);
  }

  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as mat.RenderBox;
    final size = box.size;
    _pointer.x = ((event.clientX) / size.width * 2 - 1);
    _pointer.y = (-(event.clientY) / size.height * 2 + 1);
  }

  void startSketch(DrawType drawType){
    this.drawType = drawType;
    sketch?.newSketch = true;
    sketch?.newSketchDidStart = false;
    constraintType = Constraints.none;
    moveSketch = false;
  }
  void endSketch([bool cancel = false]){
    if(sketch?.newSketchDidStart == true){
      switch (drawType) {
        case DrawType.line:
          sketch?.toDispose.add(sketch!.sketches.last);
          sketch?.removeCurrent();
          break;
        case DrawType.point:
          sketch?.toDispose.add(sketch!.sketches.last);
          sketch?.removeCurrent();
          break;
        case DrawType.spline:
          sketch?.toDispose.add(sketch!.sketches.last);
          sketch?.removeCurrent();
          DrawType.updateSplineOutline(sketch!.sketches.last as dynamic, sketch!.pointPositions());
          break;
        default:
          if(cancel){
            sketch?.removeLast();
          }
      }
    }
    clearSelected();
    drawType = DrawType.none;
    sketch?.newSketch = false;
    sketch?.newSketchDidStart = false;
    update();
  }

  void checkSelected(){
    for(final o in selected){
      if(o.name == 'o'){
        origin.visible = true;
      }
      if(!selected.contains(o)){
        if(o.material?.userData['isHighlighted'] == null || o.material?.userData['isHighlighted'] == false){
          changeObjectColor(o);
        }
      }
    }
  }
  void clearSelected(){
    for(final o in selected){
      o.material?.userData['isHighlighted'] = false;
      o.material?.color = o.material?.userData['origionalColor'] ?? o.material?.color;
    }
    selected.clear();
  }
  void clearSelectedHighlight(Object3D o){
    o.material?.userData['isHighlighted'] = false;
    o.material?.color = o.material?.userData['origionalColor'] ?? o.material?.color;
    selected.remove(o);
  }
  void changeObjectColor(Object3D? newObject){
    Object3D? object = newObject;
    newObject?.material?.userData['isHighlighted'] = true;
    bool isDimension = newObject?.parent?.name == 'dimension';
    if(newObject is Line && newObject.children.isNotEmpty && newObject.children[0] is Line2){
      object = newObject.children[0];
      object.material?.linewidth =  4;
    }
    else if(object is Points){
      object.material?.size =  10;
    }
    else if(object is SketchPoint){
      object.scale.setFrom(Vector3(1.5,1.5,1.5));
    }

    object?.material?.userData['origionalColor'] = isDimension? object.material?.color:
    object.material?.color.getHex() == 0xffffff?Color.fromHex32(theme.secondaryHeaderColor.toARGB32()):object.material?.color;
    object?.material?.color = isDimension?Color.fromHex32(theme.secondaryHeaderColor.toARGB32()):object.material!.color.lighten(0.25);// = Color.fromHex32(0xffffff);
  }
  void checkHighLight(List<Intersection> inter){
    for(final i in inter){
      if(i.object?.name == 'o'){
        origin.visible = true;
        _hovered.add(i.object!);
      }
      else{
        if(i.object?.name != 'SketchPlane'){
          if(i.object?.material?.userData['isHighlighted'] == null || i.object?.material?.userData['isHighlighted'] == false){
            changeObjectColor(i.object);
            _hovered.add(i.object!);
          }
        }
      }
    }
  }
  void clearHighlight(){
    origin.visible = false;
    for(final o in _hovered){
      if(!selected.contains(o)){
        o.material?.userData['isHighlighted'] = false;
        if(o is Line && o.children.isNotEmpty && o.children[0] is Line2){
          o.children[0].material?.color = o.children[0].material?.userData['origionalColor'] ?? o.children[0].material?.color;
          o.children[0].material?.linewidth =  2;
        }
        else{
          o.material?.color = o.material?.userData['origionalColor'] ?? o.material?.color;
          if(o is Points){
            o.material?.size =  7.5;
          }
          if(o is SketchPoint){
            o.scale.setFrom(Vector3(1,1,1));
          }
        }
      }
    }
    _hovered = [];
  }

  List<Intersection> _getObjectIntersections(){
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObjects([origin]+sketch!.allSelectables,false);
  }
  List<Intersection> _getAllIntersections(WebPointerEvent event){
    updatePointer(event);
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObjects([sketch!.meshPlane,origin]+sketch!.allSelectables,false);
  }
  List<Intersection> _getIntersections(){
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObject(sketch!.meshPlane,false);
  }
  void onPointerHover(WebPointerEvent event) {
    if(sketch != null){
      final intersections = _getAllIntersections(event);
      clearHighlight();
      checkHighLight(intersections);
      checkSelected();

      if(intersections.isNotEmpty && sketch!.sketches.isNotEmpty){
        if(sketch?.newSketchDidStart == true){
          _updateDraw(intersections[0].point!);
        }
        else if(sketch!.sketches.isNotEmpty){
          _updateDraw(intersections[0].point!);
        }
      }
    }
  }
  void onPointerMove(WebPointerEvent event) {
    if(sketch != null){
      final intersections = _getAllIntersections(event);
      clearHighlight();
      checkHighLight(intersections);
      checkSelected();

      if(moveSketch && selected.isNotEmpty && intersections.isNotEmpty){
        _updateMove(selected[0],intersections[0].point!);
      }
    }
  }

  Vector3 getPointInBetweenByPerc(Vector3 p1, Vector3 p2, double percentage) {
    Vector3 dir = p2.clone().sub(p1);
    final len = dir.length;
    dir = dir.normalize().scale(len*percentage);
    return p1.clone().add(dir);
  }
  void _updateSketchScene(){
    if(sketch == null) return;
    for(final object in sketch!.sketches){
      if(object is SketchObjects){
        final constraints = object.getConstraints();
        for(final constraint in constraints){
          if(constraint.hasConstraint){
            object.updateConstraint();
          }
        }
        object.redraw();
      }
    }
  }
  // void _getConstraint(Object3D object){
  //   print(object);
  //   if(object is SketchPoint){// && object.parent ==  null){
  //     if(object.parent is SketchCircle){
  //       if((object.parent as SketchCircle).circleConstraint.concentricTo != null){
  //         selected[0] = (object.parent as SketchCircle).circleConstraint.concentricTo!;
  //       }
  //     }
  //   }
  //   else if(object is Line){
  //     if(object.parent is SketchCircle){
  //       if((object.parent as SketchCircle).circleConstraint.equalTo != null){
  //         selected[0] = (object.parent as SketchCircle).circleConstraint.equalTo!.getLine()!;
  //       }
  //     }
  //   }
  //   else if(object.parent is SketchCircle){

  //   }
  // }
  void _addConstraint(){
    switch (constraintType) {
      case Constraints.coincident:
        if(selected[0].parent is SketchCircle && selected[1].parent is SketchCircle){
          (selected[0].parent as SketchCircle).center.addConstraint(Constraints.coincident,(selected[1].parent as SketchCircle).center);
        }
        else if(selected[0].parent is SketchCircle && selected[1].parent is SketchPoint){
          (selected[0].parent as SketchCircle).center.addConstraint(Constraints.coincident,selected[1].parent);
        }
        else if(selected[0].parent is SketchPoint && selected[1].parent is SketchCircle){
          (selected[0].parent as SketchCircle).addConstraint(Constraints.coincident,(selected[1].parent as SketchCircle).center);
        }
      case Constraints.equal:
        if(selected[0].parent is SketchCircle && selected[1].parent is SketchCircle){
          (selected[0].parent as SketchCircle).addConstraint(Constraints.equal,selected[1].parent);//.circleConstraint.equalTo = selected[1].parent;
          (selected[0].parent as SketchCircle).updateConstraint();
          (selected[0].parent as SketchCircle).redraw();
        }
        // else if(selected[1].parent is! SketchCircle){
        //   clearSelectedHighlight(selected[1]);
        // }
        // else{
        //   (selected[0].parent as SketchCircle).addConstraint(Constraints.concentric,selected[1].parent);
        //   (selected[0].parent as SketchCircle).updateConstraint();
        //   (selected[0].parent as SketchCircle).redraw();
        //   (selected[1].parent as SketchCircle).redraw();
        //   clearSelected();
        // }
        break;
      case Constraints.concentric:
        if(selected[0].parent is! SketchCircle){
          clearSelectedHighlight(selected[0]);
        }
        else if(selected[1].parent is! SketchCircle){
          clearSelectedHighlight(selected[1]);
        }
        else{
          (selected[0].parent as SketchCircle).addConstraint(Constraints.concentric,selected[1].parent);
          (selected[0].parent as SketchCircle).updateConstraint();
          (selected[0].parent as SketchCircle).redraw();
          (selected[1].parent as SketchCircle).redraw();
        }
        break;
      case Constraints.midpoint:

        break;
      default:
    }

    if(selected.length >= 2){
      _updateSketchScene();
      clearSelected();
    }
  }
  void _updateDraw(Vector3 point){
    if(sketch?.newSketchDidStart == false) return;
    switch (drawType) {
      case DrawType.dimensions:
        break;
      case DrawType.point:
        sketch!.sketches.last.position.setFrom(point);
        break;
      case DrawType.line:
        (sketch!.sketches.last as SketchLine).updateLength(point);
        break;
      case DrawType.circleCenter:
        (sketch!.sketches.last as SketchCircle).updateDiameter(point);
        break;
      case DrawType.boxCenter:
        break;
      case DrawType.box2Point:
        final len = sketch!.sketches.length-1;
        (sketch!.sketches[len-3] as SketchLine).point1.position.setFrom(point);
        break;
      case DrawType.spline:
        sketch!.sketches.last.position.setFrom(point);
        break;
      default:
    }
    _updateSketchScene();
  }
  void _updateMove(Object3D object,Vector3 point){
    if(object is SketchPoint){// && object.parent ==  null){
      object.position.setFrom(point);
    }
    else if(object.parent is SketchCircle){
      (object.parent as SketchCircle).updateDiameter(point);
    }
    else if(object is SketchLine){
      object.updatePosition(point);
    }

    _updateSketchScene();
  }

  void onPointerUp(event){
    if(sketch != null){
      if(moveSketch){
        clearSelected();
      }
    }
  }
  void onPointerDown(WebPointerEvent event) {
    if(sketch != null){
      if(event.button == 0){
        final intersections = _getIntersections();
        final intersectObjects = _getObjectIntersections();
        bool isLine = false;
        bool isPoint = false;
        Object3D? parent;
        Object3D? didSelect;
        Vector3? point;
        if(intersections.isNotEmpty){
          for(final i in intersectObjects){
            final o = i.object!;
            if(o.name == 'o'){
              didSelect = o.parent;
              point = origin.position;
              break;
            }
            if(o.name == 'point'){
              point = o.position;
              didSelect = o;
              parent = o.parent;
              isPoint = true;
              break;
            }
            if(moveSketch && o.name == 'linePoint'){
              point = o.position;
              didSelect = o;
              parent = o.parent;
              isPoint = true;
              break;
            }
            if(o.name == 'line'){
              parent = o.parent;
              didSelect = o;
              point = i.point;
              isLine = true;
            }
          }

          point ??= intersections[0].point!;

          switch (drawType) {
            case DrawType.point:
              drawPoint(point);
              break;
            case DrawType.dimensions:
              if(isLine) drawDimension(point,parent, true);
              else if(isPoint) drawDimension(point,parent, false);
              else if(sketch?.newSketch == true && sketch?.newSketchDidStart == true) endSketch(); 
              break;
            case DrawType.line:
              drawLine(point);
              break;
            case DrawType.box2Point:
              drawBox2P(point);
              break;
            case DrawType.circleCenter:
              drawCircleCenter(point);
              break;
            case DrawType.boxCenter:
              drawBoxCenter(point);
              break;
            case DrawType.spline:
              drawSpline(point);
              break;
            default:
              if(didSelect != null && constraintType != Constraints.none){
                selected.add(didSelect);
                _addConstraint();
              }
              else if(moveSketch && didSelect != null){
                selected.add(didSelect);
                //_getConstraint(selected[0]);
              }
          }
        }
      }
    }
  }

  void drawBoxCenter(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.addAll(
        DrawType.createBoxCenter(camera,mousePosition, theme.secondaryHeaderColor.toARGB32())
      );
      sketch?.newSketchDidStart = true;
    }
    else{
      _updateDraw(mousePosition);
      endSketch();
    }
  }
  void drawSpline(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.add(DrawType.createSpline(mousePosition,theme.secondaryHeaderColor.toARGB32()));
      sketch?.newSketchDidStart = true;
    }
    else{
      sketch!.sketches.last.position.setFrom(mousePosition);
      _updateDraw(mousePosition);
      addPoint(mousePosition);
    }
  }
  void drawCircleCenter(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.add(DrawType.createCircleSpline(camera,mousePosition,theme.secondaryHeaderColor.toARGB32()));
      sketch?.newSketchDidStart = true;
    }
    else{
      _updateDraw(mousePosition);
      endSketch();
    }
  }

  void drawBox2P(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.addAll(DrawType.createBox2Point(camera,mousePosition, theme.secondaryHeaderColor.toARGB32()));
      sketch?.newSketchDidStart = true;
    }
    else{
      _updateDraw(mousePosition);
      endSketch();
    }
  }
  void drawDimension(Vector3 mousePosition, Object3D? select, bool fromLine){
    final color = theme.brightness == mat.Brightness.light?0x000000:0xffffff;
    if(fromLine && sketch?.newSketch == true && sketch?.newSketchDidStart == false && select?.name == 'circleSpline'){
      final g = SketchObjects()..name = 'dimension';
      //selected.userData['constraints'] = ;
      addPoint(mousePosition,color);
      addPoint(mousePosition,color);

      addLine(mousePosition,color);
      addLine(mousePosition,color);
      addLine(mousePosition,color);
      addLine(mousePosition,color);

      final p1 = select!.children.last.position;
      final position = select.children[0].geometry!.attributes['position'] as Float32BufferAttribute;
      final dist = p1.distanceTo(Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble()));

      addPlane('θ ${(dist*scale).toStringAsFixed(3)}',theme.brightness == mat.Brightness.light?0x00000000:0xffffffff).then((_){
        sketch?.sketches.add(g);
        sketch?.newSketchDidStart = true;

        selected.add(select);
        _updateDraw(mousePosition);
      });
    }
    else if(fromLine && sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      final g = SketchObjects()..name = 'dimension';
      addPoint(mousePosition,color);
      addPoint(mousePosition,color);

      addLine(mousePosition,color);
      addLine(mousePosition,color);
      addLine(mousePosition,color);

      addPlane('0.00',theme.brightness == mat.Brightness.light?0x00000000:0xffffffff).then((_){
        sketch?.sketches.add(g);
        sketch?.newSketchDidStart = true;

        selected.add(select!);
        _updateDraw(mousePosition);
      });
    }
  }
  void drawLine(Vector3 mousePosition){
    if(sketch?.newSketch ==true && sketch?.newSketchDidStart == false){
      addLine(mousePosition);
      sketch?.newSketchDidStart = true;
    }
    else{
      _updateDraw(mousePosition);
      final SketchLine l1 = sketch!.sketches.last as SketchLine;
      addLine(mousePosition);
      final SketchLine l2 = sketch!.sketches.last as SketchLine;

      l1.point2.addConstraint(Constraints.coincident,l2.point1);
    }
  }
  void drawPoint(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      final points = [
        DrawType.creatPoint(mousePosition, theme.secondaryHeaderColor.toARGB32()),
        DrawType.creatPoint(mousePosition, theme.secondaryHeaderColor.toARGB32())
      ];
      sketch?.sketches.addAll(points);
      sketch?.newSketchDidStart = true;
    }
    else{
      sketch!.sketches.last.position.setFrom(mousePosition);
      _updateDraw(mousePosition);
      addPoint(mousePosition);
    }
  }
  
  void addPoint(Vector3 mousePosition, [int? color]){
    sketch?.sketches.add(
      DrawType.creatPoint(mousePosition, color??theme.secondaryHeaderColor.toARGB32())
    );
  }
  void addLine(Vector3 mousePosition,[int? color]){
    sketch?.sketches.add(
      DrawType.createLine(camera,mousePosition, color??theme.secondaryHeaderColor.toARGB32())
    );
  }
  Future<void> addPlane(String value, int color) async{
    final texture = await FlutterTexture.fromWidget(
      context,
      mat.Transform.flip(
        //flipX: !kIsWeb?true:false,
        flipY: !kIsWeb?true:false,
        child: mat.Container(
          width: 250,
          height: 100,
          color: mat.Colors.transparent,
          alignment: mat.Alignment.topCenter,
          child: mat.Text(
            value,
            style: mat.TextStyle(
              fontSize: 36,
              color: mat.Color(0xffffffff)
            ),
          ),
        ),
      )
    );
    final geometry = PlaneGeometry(0.25,0.1);
    final material = MeshBasicMaterial.fromMap( {
      'map': texture,
      'side': DoubleSide,
      'transparent': true,
    } )
    ..depthWrite = true
    ..depthTest = false;

    final mesh = Mesh(geometry,material)..lookAt(camera.up);
    sketch?.scale.add(mesh);
    sketch?.sketches.last.add(mesh);
  }

  void start(Sketch sketch){
    show();
    this.sketch = sketch;

    drawScene.add(sketch.meshPlane);
    drawScene.add(sketch.render);
  }
  void finish(){
    if(drawType != DrawType.none){
      endSketch();
    }

    drawScene.remove(sketch!.meshPlane);
    drawScene.remove(sketch!.render);

    hide();
    sketch = null;
  }
  void updateScale(){
    final scale = 1.5;
    for(int i = 0; i < (sketch?.scale.length ?? 0); i++){
      sketch?.scale[i].scale.setValues(scale/camera.zoom, scale/camera.zoom, scale/camera.zoom);
    }
  }
  void cancel(){
    finish();
  }
}