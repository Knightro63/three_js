import 'dart:async';
import 'dart:math' as math;
import 'package:css/css.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Actions;
import 'package:flutter/services.dart';
import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_cad/src/cad/draw_types.dart';
import 'package:three_cad/src/cad/sketch.dart';
import 'package:three_cad/src/navigation/globals.dart';
import 'package:three_cad/src/navigation/nav_icons.dart';

import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_exporters/three_js_exporters.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

import '../src/navigation/gui.dart';
import '../src/cad/origin.dart';
import '../src/navigation/navigation.dart';

enum Actions{none,prepareSketec,sketch,extrude,revolve,sweep,}

class IntersectsInfo{
  IntersectsInfo(this.intersects,this.oInt);
  List<three.Intersection> intersects = [];
  List<int> oInt = [];
}

class UIScreen extends StatefulWidget {
  const UIScreen({Key? key}):super(key: key);
  @override
  _UIPageState createState() => _UIPageState();
}

class _UIPageState extends State<UIScreen> {
  LsiThemes theme = LsiThemes.dark;

  Gui gui = Gui();
  late Draw draw;
  bool resetNav = false;
  late three.ThreeJS threeJs;

  three.Raycaster raycaster = three.Raycaster();
  three.Vector2 mousePosition = three.Vector2.zero();
  three.Object3D? intersected;
  bool didClick = false;
  bool usingMouse = false;

  late TransformControls control;
  late three.OrbitControls orbit;
  late three.PerspectiveCamera cameraPersp;
  late three.OrthographicCamera cameraOrtho;

  three.Vector3 resetCamPos = three.Vector3(0,5, 0);
  bool holdingControl = false;
  three.Group mp = three.Group();
  Actions action = Actions.none;

  late final Origin origin;
  List<Sketch> _sketches = [];
  Sketch? selectedSketch;
  
  three.Group sketches = three.Group();
  three.Group bodies = three.Group();
  ViewHelper2? viewHelper;

  @override
  void initState(){
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose(){
    control.dispose();
    orbit.dispose();
    threeJs.dispose();
    draw.dispose();
    super.dispose();
  }
  void callBacks({required LSICallbacks call}){
    switch (call) {
      case LSICallbacks.updatedNav:
        setState(() {
          resetNav = !resetNav;
        });
        break;
      case LSICallbacks.clear:
        setState(() {
          resetNav = !resetNav;

        });
        break;
      case LSICallbacks.updateLevel:
        setState(() {

        });
        break;
      default:
    }
  }

  Future<void> setup() async{
    //threeJs.screenSize = Size(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height-150);
    const frustumSize = 1.0;
    final aspect = threeJs.width / threeJs.height;
    cameraPersp = three.PerspectiveCamera( 50, aspect, 0.1, 100 );
    cameraOrtho = three.OrthographicCamera( - frustumSize * aspect, frustumSize * aspect, frustumSize, - frustumSize, -1, 10000 );
    threeJs.camera = cameraOrtho;

    threeJs.camera.position.setFrom(resetCamPos);

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(CSS.darkTheme.canvasColor.value);

    final ambientLight = three.AmbientLight( 0xffffff, 0 );
    threeJs.scene.add( ambientLight );

    final light = three.DirectionalLight( 0xffffff, 0.5 );
    light.position = threeJs.camera.position;
    threeJs.scene.add( light );

    orbit = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    control = TransformControls(threeJs.camera, threeJs.globalKey);

    control.addEventListener( 'dragging-changed', (event) {
      orbit.enabled = ! event.value;
    });
    threeJs.scene.add( control );

    origin = Origin(
      threeJs.camera, 
      threeJs.globalKey,three.Vector2(0,25),
      0.5,
      (three.Object3D? object){
        if(object != null){
          initGui();
          setState(() {
            
          });
        }
      }
    );

    threeJs.scene.add(origin.childred);
    threeJs.scene.add(origin.grid);
    threeJs.scene.add(bodies);
    threeJs.scene.add(sketches);
    WidgetsBinding.instance.addPostFrameCallback((_){
      creteHelpers();
    });
    
    threeJs.domElement.addEventListener(
      three.PeripheralType.resize, 
      threeJs.onWindowResize
    );
    threeJs.domElement.addEventListener(three.PeripheralType.keydown,(event) {
      event as LogicalKeyboardKey;
      switch (event.keyLabel.toLowerCase()) {
        case 'meta left':
          holdingControl = true;
        case 'q':
          control.setSpace( control.space == 'local' ? 'world' : 'local' );
          break;
        case 'shift right':
        case 'shift left':
          control.setTranslationSnap( 1 );
          control.setRotationSnap( three.MathUtils.degToRad( 15 ) );
          control.setScaleSnap( 0.25 );
          break;
        case 'w':
          control.setMode(GizmoType.translate);
          break;
        case 'e':
          control.setMode(GizmoType.rotate);
          break;
        case 'r':
          control.setMode(GizmoType.scale);
          break;
        case 'c':
          if(holdingControl){

          }
          break;
        case 'v':
          if(holdingControl){

          }
          break;
        case '+':
        case '=':
          control.setSize( control.size + 0.1 );
          break;
        case '-':
        case '_':
          control.setSize( math.max( control.size - 0.1, 0.1 ) );
          break;
        case 'delete':
        case 'x':
          if(intersected != null){

          }
          break;
        case 'tab':
          if(intersected != null){

          }
          break;
        case 'y':
          break;
        case 'z':
          break;
        case ' ':
          break;
        case 'escape':
          draw.endSketch(true);
          break;
      }
    });
    threeJs.domElement.addEventListener(three.PeripheralType.keyup, (event) {
      event as LogicalKeyboardKey;
      switch ( event.keyLabel.toLowerCase() ) {
        case 'meta left':
          holdingControl = false;
        case 'shift right':
        case 'shift left':
          control.setTranslationSnap( null );
          control.setRotationSnap( null );
          control.setScaleSnap( null );
          break;
      }
    });
    threeJs.domElement.addEventListener(three.PeripheralType.pointerup, (details){
      orbit.enableZoom = true;
      planeSelected();
    });
    threeJs.domElement.addEventListener(three.PeripheralType.pointerdown, (details){
      orbit.enableZoom = false;
      planeSelected();
    });

    threeJs.addAnimationEvent((dt){
      origin.update();
      draw.updateScale();
      orbit.update();
      if (viewHelper != null && viewHelper!.animating ) {
        viewHelper!.update( dt );
        orbit.target.setFrom(origin.childred.children[0].position);
      }
    });

    draw = Draw(
      threeJs.camera,
      origin.childred.children[0].clone(),
      threeJs.globalKey,
      CSS.changeTheme(theme),
      context,
      (){
        setState(() {});
      }
    );
    threeJs.scene.add(draw.drawScene);

    initGui();
  }

  void planeSelected(){
    if(action == Actions.prepareSketec && origin.planeType != OriginTypes.none){
      if(origin.planeType == OriginTypes.xy){
        threeJs.camera.position.setValues(0,0,5);
      } 
      else if(origin.planeType == OriginTypes.xz){
        threeJs.camera.position.setValues(0,5,0);
      }
      else{
        threeJs.camera.position.setValues(5,0,0);
      }
      _sketches.add(Sketch(origin.selectedPlane!));
      drawSetup(origin.grid.position, _sketches.last);
      origin.gridHover(origin.planeType.name);
      origin.clearHighlight(origin.selectedPlane);
    }
  }

  void drawSetup(three.Vector3 position, Sketch sketch){
    orbit.target.setFrom(position);
    orbit.enableRotate = false;
    origin.lockGrid = true;
    origin.childred.visible = false;

    selectedSketch = sketch;
    draw.start(sketch);
    action = Actions.sketch;
  }

  void creteHelpers(){
    viewHelper = ViewHelper2(
      //size: 1.8,
      offsetType: OffsetType.topRight,
      offset: three.Vector2(5,-70),
      screenSize: const Size(120, 120), 
      listenableKey: threeJs.globalKey,
      camera: threeJs.camera,
      //threeJs: threeJs
    );

    threeJs.renderer?.autoClear = false;
    threeJs.postProcessor = ([double? dt]){
      threeJs.renderer?.render( threeJs.scene, threeJs.camera );
      viewHelper?.render(threeJs.renderer!);
    };
  }

  three.Vector2 convertPosition(three.Vector2 location){
    double x = (location.x / (threeJs.width-MediaQuery.of(context).size.width/6)) * 2 - 1;
    double y = -(location.y / (threeJs.height-20)) * 2 + 1;
    return three.Vector2(x,y);
  }

  IntersectsInfo getIntersections(List<three.Object3D> objects){
    IntersectsInfo ii = IntersectsInfo([], []);
    int i = 0;
    for(final o in objects){
      if(o is three.Group || o is three.AnimationObject || o.runtimeType == three.Object3D){
        final inter = getIntersections(o.children);
        ii.intersects.addAll(inter.intersects);
        ii.oInt.addAll(List.filled(inter.intersects.length, i));
      }
      else if(o is! three.Bone && o is! BoundingBoxHelper){
        final inter = raycaster.intersectObject(o, false);
        ii.intersects.addAll(inter);
        ii.oInt.addAll(List.filled(inter.length, i));
      }
      i++;
    }
    return ii;
  }
  void boxSelect(bool select){
    if(intersected == null) return;
    if(!select){
      control.detach();
      for(final o in intersected!.children){
        if(o is BoundingBoxHelper){
          o.visible = false;
        }
      }
    }
    else{
      for(final o in intersected!.children){
        if(o is BoundingBoxHelper){
          o.visible = true;
        }
      }
      control.attach( intersected );
    }
  }
  void checkIntersection(List<three.Object3D> objects) {
    IntersectsInfo ii = getIntersections(objects);
    raycaster.setFromCamera(convertPosition(mousePosition), threeJs.camera);
    if (ii.intersects.isNotEmpty ) {
      if(intersected != objects[ii.oInt[0]]) {
        if(intersected != null){
          boxSelect(false);
        }
        intersected = objects[ii.oInt[0]];
        boxSelect(true);
      }
    }
    else if(intersected != null){
      boxSelect(false);
      intersected = null;
    }

    if(didClick && intersected != null){

    }
    else if(didClick && ii.intersects.isEmpty){
      boxSelect(false);
      intersected = null;
    }

    didClick = false;
    setState(() {});
  }

  void initGui() {
    final newGui = Gui();
    final folder = newGui.addFolder('Origin',(){setState(() {});})..onVisibilityChange = (b){origin.childred.visible = b;};
    int i = 0;
    for(final o in origin.childred.children){
      late final IconData icon;
      if(i == 0){
        icon = Icons.adjust;
      }
      else if(i < 4){
        icon = Icons.line_axis;
      }
      else{
        icon = Icons.copy;
      }
      folder.add(o.name.toUpperCase(), icon, o.userData['selected'], o.visible)
        ..onSelected((b){
          o.userData['selected'] = b;
          origin.selectPlane(b?o.name:null);
        })
        ..onVisibilityChange((b){o.visible = b;});
      i++;
    }
    if(bodies.children.isNotEmpty){
      final bFolder = newGui.addFolder('Bodies',(){setState(() {});})..onVisibilityChange = (b){bodies.visible = b;};
      for(final o in bodies.children){
        bFolder.add(o.name, Icons.view_in_ar_rounded, o.userData['selected'], o.visible)
          ..onSelected((b){
            o.userData['selected'] = b;
          })
          ..onVisibilityChange((b){o.visible = b;});
      }
    }
    if(sketches.children.isNotEmpty){
      final sFolder = newGui.addFolder('Sketches',(){setState(() {});})..onVisibilityChange = (b){sketches.visible = b;};
      for(final o in _sketches){
        sFolder.add(o.render.name, Icons.draw_outlined, o.render.userData['selected'] ?? false, o.render.visible)
          ..onSelected((b){
            o.render.userData['selected'] = b;
          })
          ..onEdit((b){
            o.render.userData['selected'] = b;
            drawSetup(o.meshPlane.position, o);
          })
          ..onVisibilityChange((b){o.render.visible = b;});
      }
    }

    for(final fol in gui.folders.keys){
      if(gui.folders[fol]!.isOpen){
        newGui.folders[fol]!.open();
      } 
    }

    gui = newGui;
  }
  
  Widget selectionIcon(IconData icon, bool selected,void Function() onTap){
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (selected?CSS.changeTheme(theme).secondaryHeaderColor:CSS.changeTheme(theme).hintColor))
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: (selected?CSS.changeTheme(theme).secondaryHeaderColor:CSS.changeTheme(theme).hintColor)),
      ),
    );
  }
  Widget actionNav(){
    return Actions.sketch == action?sketchNav():Row(
      children: [
        SketchIcons(DrawType.none,action == Actions.prepareSketec,CSS.changeTheme(theme),
          (){
            setState(() {
              if(action == Actions.prepareSketec){
                action = Actions.none;
              }
              else{
                action = Actions.prepareSketec;
                origin.showGrid = true;
                planeSelected();
              }
            });
          },
        ),
        selectionIcon(Icons.unarchive_outlined,action == Actions.extrude,(){
            setState(() {
              if(action == Actions.extrude){
                action = Actions.none;
              }
              else{
                action = Actions.extrude;
                //origin.showGrid = true;
                //planeSelected();
              }
            });
          },
        ),
        selectionIcon(Icons.threesixty_outlined, action == Actions.extrude,(){
            setState(() {
              if(action == Actions.extrude){
                action = Actions.none;
              }
              else{
                action = Actions.extrude;
                //origin.showGrid = true;
                //planeSelected();
              }
            });
          },
        )
      ],
    );
  }
  void cancelSketch(bool cancel){
    draw.cancel();

    if(cancel){
      selectedSketch?.dispose();
      _sketches.remove(selectedSketch);
    }
    else{
      if(selectedSketch != null && selectedSketch!.render.children.isNotEmpty){
        selectedSketch?.render.userData['selected'] = false;
        selectedSketch?.render.name = 'Sketch ${_sketches.indexOf(selectedSketch!)}';
        selectedSketch?.minorDispose();
        sketches.add(selectedSketch?.render);
      }
      else{
        selectedSketch?.dispose();
        _sketches.remove(selectedSketch);
      }
    }

    action = Actions.none;
    orbit.enableRotate = true;
    origin.showGrid = false;
    origin.lockGrid = false;
    origin.childred.visible = true;
    initGui();
  }
  Widget sketchNav(){
    return Row(
      children: [
        SketchIcons(DrawType.point,draw.drawType == DrawType.point,CSS.changeTheme(theme),
          (){
            if(draw.drawType != DrawType.none){
              setState(() {
                draw.endSketch();
              });
            }
            else{
              setState(() {
                draw.startSketch(DrawType.point);
              });
            }
          },
        ),
        SketchIcons(DrawType.line,draw.drawType == DrawType.line,CSS.changeTheme(theme),
          (){
            if(draw.drawType != DrawType.none){
              setState(() {
                draw.endSketch();
              });
            }
            else{
              setState(() {
                draw.startSketch(DrawType.line);
              });
            }
          },
        ),
        SketchIcons(DrawType.box2Point,draw.drawType == DrawType.box2Point,CSS.changeTheme(theme),
          (){
            if(draw.drawType != DrawType.none){
              setState(() {
                draw.endSketch(true);
              });
            }
            else{
              setState(() {
                draw.startSketch(DrawType.box2Point);
              });
            }
          },
        ),
        SketchIcons(DrawType.circleCenter,draw.drawType == DrawType.circleCenter,CSS.changeTheme(theme),
          (){
            if(draw.drawType != DrawType.none){
              setState(() {
                draw.endSketch(true);
              });
            }
            else{
              setState(() {
                draw.startSketch(DrawType.circleCenter);
              });
            }
          }
        ),
        SketchIcons(DrawType.boxCenter,draw.drawType == DrawType.boxCenter,CSS.changeTheme(theme),
          (){
            if(draw.drawType != DrawType.none){
              setState(() {
                draw.endSketch(true);
              });
            }
            else{
              setState(() {
                draw.startSketch(DrawType.boxCenter);
              });
            }
          }
        ),
        SketchIcons(DrawType.spline,draw.drawType == DrawType.spline,CSS.changeTheme(theme),
          (){
            if(draw.drawType != DrawType.none){
              setState(() {
                draw.endSketch();
              });
            }
            else{
              setState(() {
                draw.startSketch(DrawType.spline);
              });
            }
          }
        ),
        SketchIcons(DrawType.arc3Point,draw.drawType == DrawType.arc3Point,CSS.changeTheme(theme),
          (){
            if(draw.drawType != DrawType.none){
              setState(() {
                draw.endSketch(true);
              });
            }
            else{
              setState(() {
                draw.startSketch(DrawType.arc3Point);
              });
            }
          }
        ),
        SketchIcons(DrawType.dimensions,draw.drawType == DrawType.dimensions,CSS.changeTheme(theme),
          (){
            if(draw.drawType != DrawType.none){
              setState(() {
                draw.endSketch(true);
              });
            }
            else{
              setState(() {
                draw.startSketch(DrawType.dimensions);
              });
            }
          }
        ),
        Container(
          color: CSS.changeTheme(theme).dividerColor,
          width: 2,
          height: 35,
        ),
        ConstraintIcons(Constraints.horizontal,draw.constraintType == Constraints.horizontal,CSS.changeTheme(theme),
          (){
            setState(() {
              if(draw.constraintType == Constraints.none){
                draw.constraintType = Constraints.horizontal;
                draw.endSketch(true);
              }
              else{
                draw.constraintType = Constraints.none;
              }
            });
          }
        ),
        ConstraintIcons(Constraints.equal,draw.constraintType == Constraints.equal,CSS.changeTheme(theme),(){
            setState(() {
              if(draw.constraintType == Constraints.none){
                draw.constraintType = Constraints.equal;
                draw.endSketch(true);
              }
              else{
                draw.constraintType = Constraints.none;
              }
            });
          }),
        ConstraintIcons(Constraints.coincident,draw.constraintType == Constraints.coincident,CSS.changeTheme(theme),(){
            setState(() {
              if(draw.constraintType == Constraints.none){
                draw.constraintType = Constraints.coincident;
                draw.endSketch(true);
              }
              else{
                draw.constraintType = Constraints.none;
              }
            });
          }),
        ConstraintIcons(Constraints.tangent,draw.constraintType == Constraints.tangent,CSS.changeTheme(theme),(){
            setState(() {
              if(draw.constraintType == Constraints.none){
                draw.constraintType = Constraints.tangent;
                draw.endSketch(true);
              }
              else{
                draw.constraintType = Constraints.none;
              }
            });
          }),
        ConstraintIcons(Constraints.concentric,draw.constraintType == Constraints.concentric,CSS.changeTheme(theme),(){
            setState(() {
              if(draw.constraintType == Constraints.none){
                draw.constraintType = Constraints.concentric;
                draw.endSketch(true);
              }
              else{
                draw.constraintType = Constraints.none;
              }
            });
          }),
        ConstraintIcons(Constraints.midpoint,draw.constraintType == Constraints.midpoint,CSS.changeTheme(theme),(){
            setState(() {
              if(draw.constraintType == Constraints.none){
                draw.constraintType = Constraints.midpoint;
                draw.endSketch(true);
              }
              else{
                draw.constraintType = Constraints.none;
              }
            });
          }),
        ConstraintIcons(Constraints.parallel,draw.constraintType == Constraints.parallel,CSS.changeTheme(theme),(){
            setState(() {
              if(draw.constraintType == Constraints.none){
                draw.constraintType = Constraints.parallel;
                draw.endSketch(true);
              }
              else{
                draw.constraintType = Constraints.none;
              }
            });
          }),
        ConstraintIcons(Constraints.perpendicular,draw.constraintType == Constraints.perpendicular,CSS.changeTheme(theme),(){
            setState(() {
              if(draw.constraintType == Constraints.none){
                draw.constraintType = Constraints.perpendicular;
                draw.endSketch(true);
              }
              else{
                draw.constraintType = Constraints.none;
              }
            });
          }),
        Container(
          color: CSS.changeTheme(theme).dividerColor,
          width: 2,
          height: 35,
        ),
        selectionIcon(Icons.open_with,draw.moveSketch,
          (){
            setState(() {
              if(!draw.moveSketch){
                draw.moveSketch = true;
                draw.constraintType = Constraints.none;
                draw.endSketch(true);
              }
              else{
                draw.moveSketch = false;
              }
            });
          },
        ),
        selectionIcon(Icons.check,false,
          (){
            setState(() {
              cancelSketch(false);
              initGui();
            });
          },
        ),
        selectionIcon(Icons.cancel,false,
          (){
            setState(() {
              cancelSketch(true);
            });
          },
        )
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    
    return MaterialApp( 
      theme: CSS.changeTheme(theme),
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child:Theme(
          data: CSS.changeTheme(theme),
          child:Scaffold(
            appBar: PreferredSize(
              preferredSize: Size(deviceWidth,50), 
              child:Navigation(
                height: 25,
                callback: callBacks,
                reset: resetNav,
                navData: [
                    NavItems(
                      name: 'File',
                      subItems:[ 
                        NavItems(
                          name: 'New',
                          icon: Icons.new_label_outlined,
                          function: (data){
                            callBacks(call: LSICallbacks.clear);
                          }
                        ),
                        NavItems(
                          name: 'Open',
                          icon: Icons.folder_open,
                          function: (data){
                            setState(() {
                              callBacks(call: LSICallbacks.clear);
                              GetFilePicker.pickFiles(['tce']).then((value)async{
                                if(value != null){
                                  for(int i = 0; i < value.files.length;i++){

                                  }
                                }
                              });
                            });
                          }
                        ),
                        NavItems(
                          name: 'Save',
                          icon: Icons.save,
                          function: (data){
                            callBacks(call: LSICallbacks.updatedNav);
                            setState(() {

                            });
                          }
                        ),
                        NavItems(
                          name: 'Save As',
                          icon: Icons.save_outlined,
                          function: (data){
                            setState(() {
                              callBacks(call: LSICallbacks.updatedNav);
                              if(!kIsWeb){
                                GetFilePicker.saveFile('untilted', 'tce').then((path){
                                  setState(() {

                                  });
                                });
                              }
                              else if(kIsWeb){
                              }
                            });
                          }
                        ),
                        NavItems(
                          name: 'Import',
                          icon: Icons.file_download_outlined,
                          subItems: [
                            NavItems(
                              name: 'obj',
                              icon: Icons.view_in_ar_rounded,
                              function: (data) async{
                                callBacks(call: LSICallbacks.updatedNav);
                                final manager = three.LoadingManager();
                                three.MaterialCreator? materials;
                                final objs = await GetFilePicker.pickFiles(['obj']);
                                final mtls = await GetFilePicker.pickFiles(['mtl']);
                                if(mtls != null){
                                  for(int i = 0; i < mtls.files.length;i++){
                                    final mtlLoader = three.MTLLoader(manager);
                                    final last = mtls.files[i].path!.split('/').last;
                                    mtlLoader.setPath(mtls.files[i].path!.replaceAll(last,''));
                                    materials = await mtlLoader.fromPath(last);
                                    await materials?.preload();
                                  }
                                }
                                if(objs != null){
                                  for(int i = 0; i < objs.files.length;i++){
                                    final loader = three.OBJLoader();
                                    loader.setMaterials(materials);
                                    final object = await loader.fromPath(objs.files[i].path!);
                                    final three.BoundingBox box = three.BoundingBox();
                                    box.setFromObject(object!);
                                    object.scale = three.Vector3(0.01,0.01,0.01);        
                                    BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                    object.name = objs.files[i].name.split('.').first;
                                    threeJs.scene.add(object.add(h));
                                  }
                                }
                                setState(() {});
                              },
                            ),
                            NavItems(
                              name: 'stl',
                              icon: Icons.view_in_ar_rounded,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                GetFilePicker.pickFiles(['stl']).then((value)async{
                                  if(value != null){
                                    for(int i = 0; i < value.files.length;i++){
                                      final object = await three.STLLoader().fromPath(value.files[i].path!);
                                      final three.BoundingBox box = three.BoundingBox();
                                      box.setFromObject(object!);
                                      BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                      object.name = value.files[i].name.split('.').first;
                                      threeJs.scene.add(object.add(h));
                                    }
                                  }
                                  setState(() {});
                                });
                              },
                            ),
                            NavItems(
                              name: 'ply',
                              icon: Icons.view_in_ar_rounded,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                GetFilePicker.pickFiles(['ply']).then((value)async{
                                  if(value != null){
                                    for(int i = 0; i < value.files.length;i++){
                                      final buffer = await three.PLYLoader().fromPath(value.files[i].path!);
                                      final object = three.Mesh(buffer,three.MeshPhongMaterial());
                                      final three.BoundingBox box = three.BoundingBox();
                                      box.setFromObject(object);
                                      object.scale = three.Vector3(0.01,0.01,0.01);
                                      BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                      object.name = value.files[i].name.split('.').first;
                                      threeJs.scene.add(object.add(h));
                                    }
                                  }
                                  setState(() {});
                                });
                              },
                            ),
                          ]
                        ),
                        NavItems(
                          name: 'Export',
                          icon: Icons.file_upload_outlined,
                          subItems: [
                            NavItems(
                              name: 'stl',
                              icon: Icons.file_copy_outlined,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                GetFilePicker.saveFile('untilted', 'json').then((path){

                                });
                              }
                            ),
                            NavItems(
                              name: 'obj',
                              icon: Icons.file_copy_outlined,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                GetFilePicker.saveFile('untilted', 'json').then((path){

                                });
                              }
                            ),
                            NavItems(
                              name: 'ply',
                              icon: Icons.file_copy_outlined,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                GetFilePicker.saveFile('untilted', 'json').then((path){

                                });
                              }
                            )
                          ]
                        ),
                        NavItems(
                          name: 'Quit',
                          icon: Icons.exit_to_app,
                          function: (data){
                            callBacks(call: LSICallbacks.updatedNav);
                            SystemNavigator.pop();
                          }
                        ),
                      ]
                    ),
                    NavItems(
                      name: 'View',
                      subItems:[
                        NavItems(
                          name: 'Reset Camera',
                          icon: Icons.camera_indoor_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            threeJs.camera.position.setValues(0,5,0);
                            orbit.target.setFrom(origin.childred.children[0].position);
                          }
                        ),
                        NavItems(
                          name: 'Front',
                          icon: Icons.camera_indoor_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            threeJs.camera.position.setValues(0,0,5);
                            orbit.target.setFrom(origin.childred.children[6].position);
                          }
                        ),
                        NavItems(
                          name: 'Back',
                          icon: Icons.camera_indoor_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            threeJs.camera.position.setValues(0,0,-5);
                            orbit.target.setFrom(origin.childred.children[6].position);
                          }
                        ),
                        NavItems(
                          name: 'Top',
                          icon: Icons.camera_indoor_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            threeJs.camera.position.setValues(0,5,0);
                            orbit.target.setFrom(origin.childred.children[4].position);
                          }
                        ),
                        NavItems(
                          name: 'Bottom',
                          icon: Icons.camera_indoor_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            threeJs.camera.position.setValues(0,-5,0);
                            orbit.target.setFrom(origin.childred.children[4].position);
                          }
                        ),
                        NavItems(
                          name: 'Right',
                          icon: Icons.camera_indoor_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            threeJs.camera.position.setValues(5,0,0);
                            orbit.target.setFrom(origin.childred.children[5].position);
                          }
                        ),
                        NavItems(
                          name: 'Left',
                          icon: Icons.camera_indoor_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            threeJs.camera.position.setValues(-5,0,0);
                            orbit.target.setFrom(origin.childred.children[5].position);
                          }
                        ),
                        NavItems(
                          name: 'Rotate Left',
                          icon: Icons.rotate_left_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            orbit.rotateLeft(math.pi * 0.5);
                          }
                        ),
                        NavItems(
                          name: 'Rotate Right',
                          icon: Icons.rotate_right_outlined,
                          function: (e){
                            callBacks(call: LSICallbacks.updatedNav);
                            orbit.rotateLeft(-math.pi * 0.5);
                          }
                        ),
                      ]
                    ),
                    NavItems(
                      name: 'Add',
                      subItems:[ 
                        NavItems(
                          name: 'Mesh',
                          icon: Icons.share,
                          subItems: [
                            NavItems(
                              name: 'Cube',
                              icon: Icons.view_in_ar_rounded,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                final object = three.Mesh(three.BoxGeometry(),three.MeshStandardMaterial.fromMap({'flatShading': true}));
                                final three.BoundingBox box = three.BoundingBox();
                                box.setFromObject(object);     
                                BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                object.receiveShadow = true;
                                object.name = 'Cube';
                                object.userData['selected'] = false;
                                bodies.add(object.add(h));
                                initGui();
                              },
                            ),
                            NavItems(
                              name: 'Sphere',
                              icon: Icons.view_in_ar_rounded,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                final object = three.Mesh(three.SphereGeometry(1,32,32),three.MeshStandardMaterial.fromMap({'flatShading': true}));
                                final three.BoundingBox box = three.BoundingBox();
                                box.setFromObject(object);     
                                BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                object.name = 'Sphere';
                                object.userData['selected'] = false;
                                bodies.add(object.add(h));
                                initGui();
                              },
                            ),
                            NavItems(
                              name: 'Cylinder',
                              icon: Icons.view_in_ar_rounded,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                final object = three.Mesh(CylinderGeometry(),three.MeshStandardMaterial.fromMap({'flatShading': true}));
                                final three.BoundingBox box = three.BoundingBox();
                                box.setFromObject(object);     
                                BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                object.name = 'Cylinder';
                                object.userData['selected'] = false;
                                bodies.add(object.add(h));
                                initGui();
                              },
                            ),
                            NavItems(
                              name: 'Torus',
                              icon: Icons.view_in_ar_rounded,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                final object = three.Mesh(TorusGeometry(1,0.4,32,16),three.MeshStandardMaterial.fromMap({'flatShading': true}));
                                final three.BoundingBox box = three.BoundingBox();
                                box.setFromObject(object);     
                                BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                object.name = 'Torus';
                                object.userData['selected'] = false;
                                bodies.add(object.add(h));
                                initGui();
                              },
                            ),
                          ]
                        ),   
                      ]
                    ),
                    NavItems(
                      name: 'Settings',
                      subItems:[
                        NavItems(
                          name: 'Theme',
                          icon: Icons.mode_standby,
                          subItems: [
                            NavItems(
                              name: 'Dark',
                              icon: Icons.dark_mode,
                              function: (e){
                                callBacks(call: LSICallbacks.updatedNav);
                                theme = LsiThemes.dark;
                                threeJs.scene.background = three.Color.fromHex32(CSS.darkTheme.canvasColor.value);
                              }
                            ),
                            NavItems(
                              name: 'Light',
                              icon: Icons.light_mode,
                              function: (e){
                                callBacks(call: LSICallbacks.updatedNav);
                                theme = LsiThemes.light;
                                threeJs.scene.background = three.Color.fromHex32(CSS.lightTheme.canvasColor.value);
                              }
                            ),
                            NavItems(
                              name: 'Pink',
                              icon: Icons.light_mode,
                              function: (e){
                                callBacks(call: LSICallbacks.updatedNav);
                                setState(() {
                                  theme = LsiThemes.pink;
                                  threeJs.scene.background = three.Color.fromHex32(CSS.pinkTheme.canvasColor.value);
                                });
                                callBacks(call: LSICallbacks.updatedNav);
                              }
                            ),
                            NavItems(
                              name: 'Mint',
                              icon: Icons.light_mode,
                              function: (e){
                                callBacks(call: LSICallbacks.updatedNav);
                                theme = LsiThemes.mint;
                                threeJs.scene.background = three.Color.fromHex32(CSS.mintTheme.canvasColor.value);
                              }
                            ),
                            NavItems(
                              name: 'Haloween',
                              icon: Icons.dark_mode,
                              function: (e){
                                callBacks(call: LSICallbacks.updatedNav);
                                theme = LsiThemes.halloween;
                                threeJs.scene.background = three.Color.fromHex32(CSS.hallowTheme.canvasColor.value);
                              }
                            ),
                            NavItems(
                              name: 'Limbitless',
                              icon: Icons.light_mode,
                              function: (e){
                                callBacks(call: LSICallbacks.updatedNav);
                                theme = LsiThemes.limbitless;
                                threeJs.scene.background = three.Color.fromHex32(CSS.lsiTheme.canvasColor.value);
                              }
                            ),
                          ],
                        ),
                      ]
                    ),
                  ]
                ),
            ),
            body: Column(
              children: [
                actionNav(),
                Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height-70,
                      child: threeJs.build(),
                    )
            
                    if(threeJs.mounted)Positioned(
                      top: 5,
                      left: 20,
                      child: SizedBox(
                        height: threeJs.height,
                        width: 130,
                        child: gui
                      )
                    ),
                    if(threeJs.mounted)Positioned(
                      top: 0,
                      right: 20,
                      child: Transform.rotate(
                        angle: math.pi-math.pi/4,
                        child: InkWell(
                          onTap: (){
                            orbit.rotateLeft(-math.pi * 0.5);
                          },
                          child: Icon(
                            Icons.switch_access_shortcut,
                            size: 40,
                            color: (Theme.of(context).brightness == Brightness.dark?Theme.of(context).primaryColorLight:Theme.of(context).primaryColorDark).withAlpha(200),)
                        )
                      )
                    ),
                    if(threeJs.mounted)Positioned(
                      top: 0,
                      right: 80,
                      child: Transform.rotate(
                        angle: math.pi/4,
                        child: Transform.flip(
                          flipY: true,
                          child: InkWell(
                            onTap: (){
                              orbit.rotateLeft(math.pi * 0.5);
                            },
                            child: Icon(
                              Icons.switch_access_shortcut,
                              size: 40,
                              color: (Theme.of(context).brightness == Brightness.dark?Theme.of(context).primaryColorLight:Theme.of(context).primaryColorDark).withAlpha(200),)
                          )
                        )
                      )
                    ),
                    if(threeJs.mounted)Positioned(
                      top: 80,
                      right: 20,
                      child: InkWell(
                        onTap: (){
                          threeJs.camera.position.setValues(0,5,0);
                          orbit.target.setFrom(origin.childred.children[0].position);
                        },
                        child: Icon(Icons.home,color: (Theme.of(context).brightness == Brightness.dark?Theme.of(context).primaryColorLight:Theme.of(context).primaryColorDark).withAlpha(200),)
                      )
                    ) 
                  ]
                )
              ]
            ),
          ),
        )
      )
    );
  }
}


class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalRange = 6});

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;

    //if (decimalRange != null) {
      String value = newValue.text;

      if (value.contains(".") &&
          value.substring(value.indexOf(".") + 1).length > decimalRange) {
        truncated = oldValue.text;
        newSelection = oldValue.selection;
      } else if (value == ".") {
        truncated = "0.";

        newSelection = newValue.selection.copyWith(
          baseOffset: math.min(truncated.length, truncated.length + 1),
          extentOffset: math.min(truncated.length, truncated.length + 1),
        );
      }

      return TextEditingValue(
        text: truncated,
        selection: newSelection,
        composing: TextRange.empty,
      );
    //}
    //return newValue;
  }
}