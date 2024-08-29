import 'dart:async';
import 'dart:math' as math;
import 'package:css/css.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_cad/src/navigation/globals.dart';

import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_exporters/three_js_exporters.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';
import 'src/cad/camera_control.dart';

import 'src/navigation/gui.dart';
import 'src/cad/origin.dart';
import 'src/navigation/navigation.dart';

class IntersectsInfo{
  IntersectsInfo(this.intersects,this.oInt);
  List<three.Intersection> intersects = [];
  List<int> oInt = [];
}

enum Actions{none,sketch,extrude,revolve,sweep,}

class UIScreen extends StatefulWidget {
  const UIScreen({Key? key}):super(key: key);
  @override
  _UIPageState createState() => _UIPageState();
}

class _UIPageState extends State<UIScreen> {
  LsiThemes theme = LsiThemes.dark;

  late Gui gui;
  int avoid = 6;
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
  three.Group helper = three.Group();

  three.Vector3 resetCamPos = three.Vector3(0,5, 0);
  bool holdingControl = false;
  three.Group mp = three.Group();
  Actions action = Actions.none;

  late final Origin origin;
  
  three.Group sketches = three.Group();
  three.Group bodies = three.Group();

  @override
  void initState(){
    gui = Gui((){setState(() {});});
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
          if(threeJs.scene.children.length > avoid){
            for(int i = avoid; i < threeJs.scene.children.length;i++){
              threeJs.scene.children[i].dispose();
            }
            threeJs.scene.children.length = avoid;
          }
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
    threeJs.screenSize = Size(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height-80);
    const frustumSize = 5.0;
    final aspect = threeJs.width / threeJs.height;
    cameraPersp = three.PerspectiveCamera( 50, aspect, 0.1, 100 );
    cameraOrtho = three.OrthographicCamera( - frustumSize * aspect, frustumSize * aspect, frustumSize, - frustumSize, 0.1, 10000 );
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
    orbit.update();

    control = TransformControls(threeJs.camera, threeJs.globalKey);

    control.addEventListener( 'dragging-changed', (event) {
      orbit.enabled = ! event.value;
    });
    creteHelpers();
    threeJs.scene.add( control );
    threeJs.scene.add(helper);

    origin = Origin(threeJs.camera, threeJs.globalKey,three.Vector2(0,25));
    threeJs.scene.add(origin.childred);
    threeJs.scene.add(origin.grid);

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
    threeJs.domElement.addEventListener(three.PeripheralType.pointerdown, (details){
      // mousePosition = three.Vector2(details.clientX, details.clientY);
      // if(threeJs.scene.children.length > avoid && !control.dragging){
      //   checkIntersection(threeJs.scene.children.sublist(avoid));
      // }
      planeSelected();
    });

    threeJs.addAnimationEvent((dt){
      origin.update();
      orbit.update();
    });

    initGui();
  }

  void planeSelected(){
    if(action == Actions.sketch && origin.planeType != OriginTypes.none){
      if(origin.planeType == OriginTypes.xy){
        threeJs.camera.position.setValues(0,0,5);
      } 
      else if(origin.planeType == OriginTypes.xz){
        threeJs.camera.position.setValues(0,5,0);
      }
      else{
        threeJs.camera.position.setValues(5,0,0);
      }
      orbit.target.setFrom(origin.grid.position);
      orbit.enableRotate = false;
      origin.lockGrid = true;
      origin.gridHover(origin.planeType.name);
      origin.clearHighlight(origin.selectedPlane);
      origin.childred.visible = false;
    }
  }

  void creteHelpers(){
    final cc = CameraControl(
      size: 1.8,
      offsetType: OffsetType.topRight,
      offset: three.Vector2(10, 10),
      screenSize: const Size(120, 120), 
      listenableKey: threeJs.globalKey,
      rotationCamera: threeJs.camera,
      threeJs: threeJs
    );

    threeJs.renderer?.autoClear = false;
    threeJs.postProcessor = ([double? dt]){
      threeJs.renderer!.render( threeJs.scene, threeJs.camera );
      cc.postProcessor();
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
    setState(() {

    });
  }

  void initGui() {
    final folder = gui.addFolder('Origin')..onVisibilityChange = (b){origin.childred.visible = b;};
    update(){setState(() {});}
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
      folder.add(o.name, icon, update, o.userData['selected'], o.visible)
        ..onSelected((b){
          o.userData['selected'] = b;
          origin.selectPlane(b?o.name:null);
        })
        ..onVisibilityChange((b){o.visible = b;});
      i++;
    }

    final bFolder = gui.addFolder('Bodies')..onVisibilityChange = (b){bodies.visible = b;};
    final sFolder = gui.addFolder('Sketches')..onVisibilityChange = (b){sketches.visible = b;};
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double safePadding = MediaQuery.of(context).padding.top;
    double deviceHeight = MediaQuery.of(context).size.height-safePadding-25;
    
    return MaterialApp( 
      theme: CSS.darkTheme,
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
                                threeJs.scene.add(object.add(h));
                              },
                            ),
                            NavItems(
                              name: 'Sphere',
                              icon: Icons.view_in_ar_rounded,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                final object = three.Mesh(three.SphereGeometry(),three.MeshStandardMaterial.fromMap({'flatShading': true}));
                                final three.BoundingBox box = three.BoundingBox();
                                box.setFromObject(object);     
                                BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                object.name = 'Sphere';
                                threeJs.scene.add(object.add(h));
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
                                threeJs.scene.add(object.add(h));
                              },
                            ),
                            NavItems(
                              name: 'Torus',
                              icon: Icons.view_in_ar_rounded,
                              function: (data){
                                callBacks(call: LSICallbacks.updatedNav);
                                final object = three.Mesh(TorusGeometry(),three.MeshStandardMaterial.fromMap({'flatShading': true}));
                                final three.BoundingBox box = three.BoundingBox();
                                box.setFromObject(object);     
                                BoundingBoxHelper h = BoundingBoxHelper(box)..visible = false;
                                object.name = 'Torus';
                                threeJs.scene.add(object.add(h));
                              },
                            ),
                          ]
                        ),   
                      ]
                    ),
                  ]
                ),
            ),
            body: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: (){
                        setState(() {
                          if(action == Actions.sketch){
                            action = Actions.none;
                            orbit.enableRotate = true;
                            origin.showGrid = false;
                            origin.lockGrid = false;
                            origin.childred.visible = true;
                          }
                          else{
                            action = Actions.sketch;
                            origin.showGrid = true;
                            planeSelected();
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: (action == Actions.sketch?lightBlue:Theme.of(context).primaryColorLight))
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.draw, color: (action == Actions.sketch?lightBlue:Theme.of(context).primaryColorLight)),
                      ),
                    )
                  ],
                ),
                Stack(
                  children: [
                    threeJs.build(),
                    if(threeJs.mounted)Positioned(
                      top: 5,
                      left: 20,
                      child: SizedBox(
                        height: threeJs.height,
                        width: 130,
                        child: gui.render(context)
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