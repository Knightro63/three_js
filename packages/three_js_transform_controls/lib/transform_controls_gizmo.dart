part of three_js_transform_controls;

enum ContorlsMode{gizmo,picker,helper}

final _tempEuler = Euler(0, 0, 0);
final _alignVector = Vector3(0, 1, 0);
final _zeroVector = Vector3(0, 0, 0);
final _lookAtMatrix = Matrix4();
final _tempQuaternion2 = Quaternion();
final _identityQuaternion = Quaternion();
final _dirVector = Vector3();
final _tempMatrix = Matrix4();

final _unitX = Vector3(1, 0, 0);
final _unitY = Vector3(0, 1, 0);
final _unitZ = Vector3(0, 0, 1);

final _v1 = Vector3();
final _v2 = Vector3();
final _v3 = Vector3();

class TransformControlsGizmo extends Object3D {
  bool isTransformControlsGizmo = true;

  Camera? camera;
  Object3D? object;
  bool enabled = true;
  String? axis;
  GizmoType mode = GizmoType.translate;
  String space = "world";
  double size = 1;
  bool dragging = false;
  bool showX = true;
  bool showY = true;
  bool showZ = true;

  // final worldPosition = Vector3();
  // final worldPositionStart = Vector3();
  // final worldQuaternion = Quaternion();
  // final worldQuaternionStart = Quaternion();
  // final cameraPosition = Vector3();
  // final cameraQuaternion = Quaternion();
  // final pointStart = Vector3();
  // final pointEnd = Vector3();
  // final rotationAxis = Vector3();
  // num rotationAngle = 0;
  // final eye = Vector3();

  Vector3 get eye {
    return controls.eye;
  }

  Vector3 get cameraPosition {
    return controls.cameraPosition;
  }

  Quaternion get cameraQuaternion {
    return controls.cameraQuaternion;
  }

  Vector3 get worldPosition {
    return controls.worldPosition;
  }

  double get rotationAngle {
    return controls.rotationAngle;
  }

  double? get rotationSnap {
    return controls.rotationSnap;
  }

  get translationSnap {
    return controls.translationSnap;
  }

  double? get scaleSnap {
    return controls.scaleSnap;
  }

  Vector3 get worldPositionStart {
    return controls.worldPositionStart;
  }

  Quaternion get worldQuaternion {
    return controls.worldQuaternion;
  }

  Quaternion get worldQuaternionStart {
    return controls.worldQuaternionStart;
  }

  Vector3 get pointStart {
    return controls.pointStart;
  }

  Vector3 get pointEnd {
    return controls.pointEnd;
  }

  Vector3 get rotationAxis {
    return controls.rotationAxis;
  }

  final Map<GizmoType,dynamic> gizmo = {};
  final Map<GizmoType,dynamic> picker = {};
  final Map<GizmoType,dynamic> helper = {};

  late TransformControls controls;

  TransformControlsGizmo(this.controls) : super() {
    type = 'TransformControlsGizmo';
    // shared materials

    // Gizmo definitions - custom hierarchy definitions for setupGizmo() function

    // Gizmo creation
    gizmo[GizmoType.translate] = setupGizmo(gizmoInfo(GizmoType.translate,ContorlsMode.gizmo)!);
    gizmo[GizmoType.rotate] = setupGizmo(gizmoInfo(GizmoType.rotate,ContorlsMode.gizmo)!);
    gizmo[GizmoType.scale] = setupGizmo(gizmoInfo(GizmoType.scale,ContorlsMode.gizmo)!);
    picker[GizmoType.translate] = setupGizmo(gizmoInfo(GizmoType.translate,ContorlsMode.picker)!);
    picker[GizmoType.rotate] = setupGizmo(gizmoInfo(GizmoType.rotate,ContorlsMode.picker)!);
    picker[GizmoType.scale] = setupGizmo(gizmoInfo(GizmoType.scale,ContorlsMode.picker)!);
    helper[GizmoType.translate] = setupGizmo(gizmoInfo(GizmoType.translate,ContorlsMode.helper)!);
    helper[GizmoType.rotate] = setupGizmo(gizmoInfo(GizmoType.rotate,ContorlsMode.helper)!);
    helper[GizmoType.scale] = setupGizmo(gizmoInfo(GizmoType.scale,ContorlsMode.helper)!);

    add(gizmo[GizmoType.translate]);
    add(gizmo[GizmoType.rotate]);
    add(gizmo[GizmoType.scale]);
    add(picker[GizmoType.translate]);
    add(picker[GizmoType.rotate]);
    add(picker[GizmoType.scale]);
    add(helper[GizmoType.translate]);
    add(helper[GizmoType.rotate]);
    add(helper[GizmoType.scale]);

    // Pickers should be hidden always

    picker[GizmoType.translate].visible = false;
    picker[GizmoType.rotate].visible = false;
    picker[GizmoType.scale].visible = false;
  }
  
  static Map<String,dynamic>? gizmoInfo(GizmoType type, ContorlsMode mode){
    final gizmoMaterial = MeshBasicMaterial.fromMap({
      "depthTest": false,
      "depthWrite": false,
      "fog": false,
      "toneMapped": false,
      "transparent": true
    });

    final gizmoLineMaterial = LineBasicMaterial.fromMap({
      "depthTest": false,
      "depthWrite": false,
      "fog": false,
      "toneMapped": false,
      "transparent": true
    });

    // Make unique material for each axis/color
    final matInvisible = gizmoMaterial.clone();
    matInvisible.opacity = 0.15;

    final matHelper = gizmoLineMaterial.clone();
    matHelper.opacity = 0.5;

    final matRed = gizmoMaterial.clone();
    matRed.color.setFromHex32(0xff0000);

    final matGreen = gizmoMaterial.clone();
    matGreen.color.setFromHex32(0x00ff00);

    final matBlue = gizmoMaterial.clone();
    matBlue.color.setFromHex32(0x0000ff);

    final matRedTransparent = gizmoMaterial.clone();
    matRedTransparent.color.setFromHex32(0xff0000);
    matRedTransparent.opacity = 0.5;

    final matGreenTransparent = gizmoMaterial.clone();
    matGreenTransparent.color.setFromHex32(0x00ff00);
    matGreenTransparent.opacity = 0.5;

    final matBlueTransparent = gizmoMaterial.clone();
    matBlueTransparent.color.setFromHex32(0x0000ff);
    matBlueTransparent.opacity = 0.5;

    final matWhiteTransparent = gizmoMaterial.clone();
    matWhiteTransparent.opacity = 0.25;

    final matYellowTransparent = gizmoMaterial.clone();
    matYellowTransparent.color.setFromHex32(0xffff00);
    matYellowTransparent.opacity = 0.25;

    final matYellow = gizmoMaterial.clone();
    matYellow.color.setFromHex32(0xffff00);

    final matGray = gizmoMaterial.clone();
    matGray.color.setFromHex32(0x787878);

    // reusable geometry
    geo.TorusGeometry circleGeometry(radius, arc) {
      final geometry = geo.TorusGeometry(radius, 0.0075, 3, 64, arc * math.pi * 2);
      geometry.rotateY(math.pi / 2);
      geometry.rotateX(math.pi / 2);
      return geometry;
    };
    
    final arrowGeometry = geo.CylinderGeometry(0, 0.04, 0.1, 12);
    arrowGeometry.translate(0, 0.05, 0);

    final scaleHandleGeometry = BoxGeometry(0.08, 0.08, 0.08);
    scaleHandleGeometry.translate(0, 0.04, 0);

    final viewHandleGeometry = SphereGeometry(0.04);
    scaleHandleGeometry.translate(0, 0.04, 0);

    final lineGeometry = BufferGeometry();
    lineGeometry.setAttribute(Attribute.position, Float32BufferAttribute.fromList(Float32List.fromList([0.0, 0.0, 0.0, 1.0, 0.0, 0.0]), 3));

    final lineGeometry2 = geo.CylinderGeometry(0.0075, 0.0075, 0.5, 3);
    lineGeometry2.translate(0, 0.25, 0);

    // Special geometry for transform helper. If scaled with position vector it spans from [0,0,0] to position

    BufferGeometry translateHelperGeometry() {
      final geometry = BufferGeometry();
      geometry.setAttribute(Attribute.position, Float32BufferAttribute.fromList(Float32List.fromList([0.0, 0.0, 0.0, 1.0, 1.0, 1.0]), 3));
      return geometry;
    }
    
    if(type == GizmoType.translate && mode == ContorlsMode.gizmo)
    return {
      "X": [
        [
          Mesh(arrowGeometry, matRed),
          [0.5, 0.0, 0.0],
          [0.0, 0.0, -math.pi / 2]
        ],
        [
          Mesh(arrowGeometry, matRed),
          [-0.5, 0.0, 0.0],
          [0.0, 0.0, math.pi / 2]
        ],
        [
          Mesh(lineGeometry2, matRed),
          [0.0, 0.0, 0.0],
          [0.0, 0.0, -math.pi / 2]
        ]
      ],
      "Y": [
        [
          Mesh(arrowGeometry, matGreen),
          [0, 0.5, 0]
        ],
        [
          Mesh(arrowGeometry, matGreen),
          [0, -0.5, 0],
          [math.pi, 0, 0]
        ],
        [Mesh(lineGeometry2, matGreen)]
      ],
      "Z": [
        [
          Mesh(arrowGeometry, matBlue),
          [0, 0, 0.5],
          [math.pi / 2, 0, 0]
        ],
        [
          Mesh(arrowGeometry, matBlue),
          [0, 0, -0.5],
          [-math.pi / 2, 0, 0]
        ],
        [
          Mesh(lineGeometry2, matBlue),
          null,
          [math.pi / 2, 0, 0]
        ]
      ],
      "XYZ": [
        [
          Mesh(geo.OctahedronGeometry(0.1, 0), matWhiteTransparent.clone()),
          [0, 0, 0]
        ]
      ],
      "XY": [
        [
          Mesh(
              BoxGeometry(0.15, 0.15, 0.01), matBlueTransparent.clone()),
          [0.15, 0.15, 0]
        ]
      ],
      "YZ": [
        [
          Mesh(
              BoxGeometry(0.15, 0.15, 0.01), matRedTransparent.clone()),
          [0, 0.15, 0.15],
          [0, math.pi / 2, 0]
        ]
      ],
      "XZ": [
        [
          Mesh(
              BoxGeometry(0.15, 0.15, 0.01), matGreenTransparent.clone()),
          [0.15, 0, 0.15],
          [-math.pi / 2, 0, 0]
        ]
      ]
    };

    if(type == GizmoType.translate && mode == ContorlsMode.picker)
    return {
      "X": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0.3, 0, 0],
          [0, 0, -math.pi / 2]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [-0.3, 0, 0],
          [0, 0, math.pi / 2]
        ]
      ],
      "Y": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0.3, 0]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, -0.3, 0],
          [0, 0, math.pi]
        ]
      ],
      "Z": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0, 0.3],
          [math.pi / 2, 0, 0]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0, -0.3],
          [-math.pi / 2, 0, 0]
        ]
      ],
      "XYZ": [
        [Mesh(geo.OctahedronGeometry(0.2, 0), matInvisible)]
      ],
      "XY": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0.15, 0.15, 0]
        ]
      ],
      "YZ": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0, 0.15, 0.15],
          [0, math.pi / 2, 0]
        ]
      ],
      "XZ": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0.15, 0, 0.15],
          [-math.pi / 2, 0, 0]
        ]
      ]
    };

    if(type == GizmoType.translate && mode == ContorlsMode.helper)
    return {
      "START": [
        [
          Mesh(geo.OctahedronGeometry(0.01, 2), matHelper),
          null,
          null,
          null,
          'helper'
        ]
      ],
      "END": [
        [
          Mesh(geo.OctahedronGeometry(0.01, 2), matHelper),
          null,
          null,
          null,
          'helper'
        ]
      ],
      "DELTA": [
        [
          Line(translateHelperGeometry(), matHelper),
          null,
          null,
          null,
          'helper'
        ]
      ],
      "X": [
        [
          Line(lineGeometry, matHelper.clone()),
          [-1e3, 0, 0],
          null,
          [1e6, 1, 1],
          'helper'
        ]
      ],
      "Y": [
        [
          Line(lineGeometry, matHelper.clone()),
          [0, -1e3, 0],
          [0, 0, math.pi / 2],
          [1e6, 1, 1],
          'helper'
        ]
      ],
      "Z": [
        [
          Line(lineGeometry, matHelper.clone()),
          [0, 0, -1e3],
          [0, -math.pi / 2, 0],
          [1e6, 1, 1],
          'helper'
        ]
      ]
    };

    if(type == GizmoType.rotate && mode == ContorlsMode.gizmo)
    return {
      "XYZE": [
        [
          Mesh(circleGeometry(0.5,1), matGray),//geo.CircleGeometry(radius: 0.5, thetaLength:1)
          null,
          [0, math.pi / 2, 0]
        ]
      ],
      "X": [
        [Mesh(circleGeometry(0.5,0.5),matRed)],//geo.CircleGeometry(radius: 0.5, thetaLength:0.5), matRed)]
      ],
      "Y": [
        [
          Mesh(circleGeometry(0.5,0.5),matGreen),//Mesh(geo.CircleGeometry(radius: 0.5, thetaLength:0.5), matGreen),
          null,
          [0, 0, -math.pi / 2]
        ]
      ],
      "Z": [
        [
          Mesh(circleGeometry(0.5,0.5),matBlue),//Mesh(geo.CircleGeometry(radius: 0.5, thetaLength:0.5), matBlue),
          null,
          [0, math.pi / 2, 0]
        ]
      ],
      "E": [
        [
          Mesh(circleGeometry(0.75,1),matYellowTransparent),//Mesh(geo.CircleGeometry(radius: 0.75, thetaLength:1), matYellowTransparent),
          null,
          [0, math.pi / 2, 0]
        ]
      ]
    };

    if(type == GizmoType.rotate && mode == ContorlsMode.helper)
    return {
      "AXIS": [
        [
          Line(lineGeometry, matHelper.clone()),
          [-1e3, 0, 0],
          null,
          [1e6, 1, 1],
          'helper'
        ]
      ]
    };

    if(type == GizmoType.rotate && mode == ContorlsMode.picker)
    return {
      "XYZE": [
        [Mesh(SphereGeometry(0.25, 10, 8), matInvisible)]
      ],
      "X": [
        [
          Mesh(geo.TorusGeometry(0.5, 0.1, 4, 24), matInvisible),
          [0, 0, 0],
          [0, -math.pi / 2, -math.pi / 2]
        ],
      ],
      "Y": [
        [
          Mesh(geo.TorusGeometry(0.5, 0.1, 4, 24), matInvisible),
          [0, 0, 0],
          [math.pi / 2, 0, 0]
        ],
      ],
      "Z": [
        [
          Mesh(geo.TorusGeometry(0.5, 0.1, 4, 24), matInvisible),
          [0, 0, 0],
          [0, 0, -math.pi / 2]
        ],
      ],
      "E": [
        [Mesh(geo.TorusGeometry(0.75, 0.1, 2, 24), matInvisible)]
      ]
    };

    if(type == GizmoType.scale && mode == ContorlsMode.gizmo)
    return {
      "X": [
        [
          Mesh(scaleHandleGeometry, matRed),
          [0.5, 0, 0],
          [0, 0, -math.pi / 2]
        ],
        [
          Mesh(lineGeometry2, matRed),
          [0, 0, 0],
          [0, 0, -math.pi / 2]
        ],
        [
          Mesh(scaleHandleGeometry, matRed),
          [-0.5, 0, 0],
          [0, 0, math.pi / 2]
        ],
      ],
      "Y": [
        [
          Mesh(scaleHandleGeometry, matGreen),
          [0, 0.5, 0]
        ],
        [Mesh(lineGeometry2, matGreen)],
        [
          Mesh(scaleHandleGeometry, matGreen),
          [0, -0.5, 0],
          [0, 0, math.pi]
        ],
      ],
      "Z": [
        [
          Mesh(scaleHandleGeometry, matBlue),
          [0, 0, 0.5],
          [math.pi / 2, 0, 0]
        ],
        [
          Mesh(lineGeometry2, matBlue),
          [0, 0, 0],
          [math.pi / 2, 0, 0]
        ],
        [
          Mesh(scaleHandleGeometry, matBlue),
          [0, 0, -0.5],
          [-math.pi / 2, 0, 0]
        ]
      ],
      "XY": [
        [
          Mesh(BoxGeometry(0.15, 0.15, 0.01), matBlueTransparent),
          [0.15, 0.15, 0]
        ]
      ],
      "YZ": [
        [
          Mesh(BoxGeometry(0.15, 0.15, 0.01), matRedTransparent),
          [0, 0.15, 0.15],
          [0, math.pi / 2, 0]
        ]
      ],
      "XZ": [
        [
          Mesh(BoxGeometry(0.15, 0.15, 0.01), matGreenTransparent),
          [0.15, 0, 0.15],
          [-math.pi / 2, 0, 0]
        ]
      ],
      "XYZ": [
        [Mesh(BoxGeometry(0.1, 0.1, 0.1), matWhiteTransparent.clone())],
      ]
    };

    if(type == GizmoType.scale && mode == ContorlsMode.picker)
    return {
      "X": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0.3, 0, 0],
          [0, 0, -math.pi / 2]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [-0.3, 0, 0],
          [0, 0, math.pi / 2]
        ]
      ],
      "Y": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0.3, 0]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, -0.3, 0],
          [0, 0, math.pi]
        ]
      ],
      "Z": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0, 0.3],
          [math.pi / 2, 0, 0]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0, -0.3],
          [-math.pi / 2, 0, 0]
        ]
      ],
      "XY": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0.15, 0.15, 0]
        ],
      ],
      "YZ": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0, 0.15, 0.15],
          [0, math.pi / 2, 0]
        ],
      ],
      "XZ": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0.15, 0, 0.15],
          [-math.pi / 2, 0, 0]
        ],
      ],
      "XYZ": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.2), matInvisible),
          [0, 0, 0]
        ],
      ]
    };

    if(type == GizmoType.scale && mode == ContorlsMode.helper)
    return {
      "X": [
        [
          Line(lineGeometry, matHelper.clone()),
          [-1e3, 0, 0],
          null,
          [1e6, 1, 1],
          'helper'
        ]
      ],
      "Y": [
        [
          Line(lineGeometry, matHelper.clone()),
          [0, -1e3, 0],
          [0, 0, math.pi / 2],
          [1e6, 1, 1],
          'helper'
        ]
      ],
      "Z": [
        [
          Line(lineGeometry, matHelper.clone()),
          [0, 0, -1e3],
          [0, -math.pi / 2, 0],
          [1e6, 1, 1],
          'helper'
        ]
      ]
    };
    
    if(type == GizmoType.view && mode == ContorlsMode.gizmo)
    return {
      "X": [
        [
          Mesh(viewHandleGeometry, matRed),
          [0.5, 0, 0],
          [0, 0, -math.pi / 2]
        ],
        [
          Mesh(lineGeometry2, matRed),
          [0, 0, 0],
          [0, 0, -math.pi / 2]
        ],
        [
          Mesh(viewHandleGeometry, matRed),
          [-0.5, 0, 0],
          [0, 0, math.pi / 2]
        ],
      ],
      "Y": [
        [
          Mesh(viewHandleGeometry, matGreen),
          [0, 0.5, 0]
        ],
        [Mesh(lineGeometry2, matGreen)],
        [
          Mesh(viewHandleGeometry, matGreen),
          [0, -0.5, 0],
          [0, 0, math.pi]
        ],
      ],
      "Z": [
        [
          Mesh(viewHandleGeometry, matBlue),
          [0, 0, 0.5],
          [math.pi / 2, 0, 0]
        ],
        [
          Mesh(lineGeometry2, matBlue),
          [0, 0, 0],
          [math.pi / 2, 0, 0]
        ],
        [
          Mesh(viewHandleGeometry, matBlue),
          [0, 0, -0.5],
          [-math.pi / 2, 0, 0]
        ]
      ],
      "XY": [
        [
          Mesh(BoxGeometry(0.15, 0.15, 0.01), matBlueTransparent),
          [0.15, 0.15, 0]
        ]
      ],
      "YZ": [
        [
          Mesh(BoxGeometry(0.15, 0.15, 0.01), matRedTransparent),
          [0, 0.15, 0.15],
          [0, math.pi / 2, 0]
        ]
      ],
      "XZ": [
        [
          Mesh(BoxGeometry(0.15, 0.15, 0.01), matGreenTransparent),
          [0.15, 0, 0.15],
          [-math.pi / 2, 0, 0]
        ]
      ],
      "XYZ": [
        [Mesh(BoxGeometry(0.1, 0.1, 0.1), matWhiteTransparent.clone())],
      ]
    };

    if(type == GizmoType.view && mode == ContorlsMode.picker)
    return {
      "X": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0.3, 0, 0],
          [0, 0, -math.pi / 2]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [-0.3, 0, 0],
          [0, 0, math.pi / 2]
        ]
      ],
      "Y": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0.3, 0]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, -0.3, 0],
          [0, 0, math.pi]
        ]
      ],
      "Z": [
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0, 0.3],
          [math.pi / 2, 0, 0]
        ],
        [
          Mesh(geo.CylinderGeometry(0.2, 0, 0.6, 4), matInvisible),
          [0, 0, -0.3],
          [-math.pi / 2, 0, 0]
        ]
      ],
      "XY": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0.15, 0.15, 0]
        ],
      ],
      "YZ": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0, 0.15, 0.15],
          [0, math.pi / 2, 0]
        ],
      ],
      "XZ": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.01), matInvisible),
          [0.15, 0, 0.15],
          [-math.pi / 2, 0, 0]
        ],
      ],
      "XYZ": [
        [
          Mesh(BoxGeometry(0.2, 0.2, 0.2), matInvisible),
          [0, 0, 0]
        ],
      ]
    };
    
    if(type == GizmoType.view && mode == ContorlsMode.helper)
    return {
      "X": [
        [
          Line(lineGeometry, matHelper.clone()),
          [-1e3, 0, 0],
          null,
          [1e6, 1, 1],
          'helper'
        ]
      ],
      "Y": [
        [
          Line(lineGeometry, matHelper.clone()),
          [0, -1e3, 0],
          [0, 0, math.pi / 2],
          [1e6, 1, 1],
          'helper'
        ]
      ],
      "Z": [
        [
          Line(lineGeometry, matHelper.clone()),
          [0, 0, -1e3],
          [0, -math.pi / 2, 0],
          [1e6, 1, 1],
          'helper'
        ]
      ]
    };
  
    return null;
  }

  // Creates an Object3D with gizmos described in custom hierarchy definition.
  static Mesh setupGizmo(Map<String,dynamic> gizmoMap) {
    final gizmo = Mesh();

    for (final name in gizmoMap.keys) {
      final len = gizmoMap[name].length;

      for (int i = (len - 1); i >= 0; i--) {
        final gi = gizmoMap[name][i];

        late Object3D object;
        if (gi.length > 0) {
          object = gi[0];
        }

        List<num>? position;
        if (gi.length > 1) {
          position = gi[1];
        }

        List<num>? rotation;
        if (gi.length > 2) {
          rotation = gi[2];
        }

        List<num>? scale;
        if (gi.length > 3) {
          scale = gi[3];
        }

        dynamic tag ;
        if (gi.length > 4) {
          tag = gi[4];
        }

        // name and tag properties are essential for picking and updating logic.
        object.name = name;
        object.tag = tag;

        if (position != null) {
          object.position.setValues(position[0].toDouble(), position[1].toDouble(), position[2].toDouble());
        }

        if (rotation != null) {
          object.rotation.set(rotation[0].toDouble(), rotation[1].toDouble(), rotation[2].toDouble());
        }

        if (scale != null) {
          object.scale.setValues(scale[0].toDouble(), scale[1].toDouble(), scale[2].toDouble());
        }

        object.updateMatrix();

        final tempGeometry = object.geometry?.clone();
        tempGeometry?.applyMatrix4(object.matrix);
        object.geometry = tempGeometry;
        object.renderOrder = double.maxFinite.toInt();

        object.position.setValues(0.0, 0.0, 0.0);
        object.rotation.set(0.0, 0.0, 0.0);
        object.scale.setValues(1.0, 1.0, 1.0);

        gizmo.add(object);
      }
    }

    return gizmo;
  }

  // updateMatrixWorld will update transformations and appearance of individual handles
  @override
  void updateMatrixWorld([bool force = false]) {
    final space = (mode == GizmoType.scale)
        ? 'local'
        : this.space; // scale always oriented to local rotation

    final quaternion =
        (space == 'local') ? worldQuaternion : _identityQuaternion;

    // Show only gizmos for current transform mode

    gizmo[GizmoType.translate].visible = mode == GizmoType.translate;
    gizmo[GizmoType.rotate].visible = mode == GizmoType.rotate;
    gizmo[GizmoType.scale].visible = mode == GizmoType.scale;

    helper[GizmoType.translate].visible = mode == GizmoType.translate;
    helper[GizmoType.rotate].visible = mode == GizmoType.rotate;
    helper[GizmoType.scale].visible = mode == GizmoType.scale;

    final List<Object3D> handles = [];
    handles.addAll(picker[mode].children);
    handles.addAll(gizmo[mode].children);
    handles.addAll(helper[mode].children);

    for (int i = 0; i < handles.length; i++) {
      final handle = handles[i];

      // hide aligned to camera

      handle.visible = true;
      handle.rotation.set(0.0, 0.0, 0.0);
      handle.position.setFrom(worldPosition);

      double factor;
      if (camera is OrthographicCamera) {
        factor = (camera!.top - camera!.bottom) / camera!.zoom;
      } else {
        factor = worldPosition.distanceTo(cameraPosition) *
            math.min(
                1.9 *
                    math.tan(math.pi * camera!.fov / 360) /
                    camera!.zoom,
                7);
      }

      handle.scale.setValues(1.0, 1.0, 1.0).scale(factor * size / 4);

      if (handle.tag == 'helper') {
        handle.visible = false;

        if (handle.name == 'AXIS') {
          handle.position.setFrom(worldPositionStart);
          handle.visible = axis != null;

          if (axis == 'X') {
            _tempQuaternion.setFromEuler(_tempEuler.set(0, 0, 0), false);
            handle.quaternion.setFrom(quaternion).multiply(_tempQuaternion);

            if ((_alignVector
                    .setFrom(_unitX)
                    .applyQuaternion(quaternion)
                    .dot(eye)).abs() >
                0.9) {
              handle.visible = false;
            }
          }

          if (axis == 'Y') {
            _tempQuaternion.setFromEuler(
                _tempEuler.set(0, 0, math.pi / 2), false);
            handle.quaternion.setFrom(quaternion).multiply(_tempQuaternion);

            if ((_alignVector
                    .setFrom(_unitY)
                    .applyQuaternion(quaternion)
                    .dot(eye)).abs() >
                0.9) {
              handle.visible = false;
            }
          }

          if (axis == 'Z') {
            _tempQuaternion.setFromEuler(
                _tempEuler.set(0, math.pi / 2, 0), false);
            handle.quaternion.setFrom(quaternion).multiply(_tempQuaternion);

            if ((_alignVector
                    .setFrom(_unitZ)
                    .applyQuaternion(quaternion)
                    .dot(eye)).abs() >
                0.9) {
              handle.visible = false;
            }
          }

          if (axis == 'XYZE') {
            _tempQuaternion.setFromEuler(
                _tempEuler.set(0, math.pi / 2, 0), false);
            _alignVector.setFrom(rotationAxis);
            handle.quaternion.setFromRotationMatrix(
                _lookAtMatrix.lookAt(_zeroVector, _alignVector, _unitY));
            handle.quaternion.multiply(_tempQuaternion);
            handle.visible = dragging;
          }

          if (axis == 'E') {
            handle.visible = false;
          }
        } else if (handle.name == 'START') {
          handle.position.setFrom(worldPositionStart);
          handle.visible = dragging;
        } else if (handle.name == 'END') {
          handle.position.setFrom(worldPosition);
          handle.visible = dragging;
        } else if (handle.name == 'DELTA') {
          handle.position.setFrom(worldPositionStart);
          handle.quaternion.setFrom(worldQuaternionStart);
          _tempVector
              .setValues(1e-10, 1e-10, 1e-10)
              .add(worldPositionStart)
              .sub(worldPosition)
              .scale(-1);
          _tempVector
              .applyQuaternion(worldQuaternionStart.clone().invert());
          handle.scale.setFrom(_tempVector);
          handle.visible = dragging;
        } else {
          handle.quaternion.setFrom(quaternion);

          if (dragging) {
            handle.position.setFrom(worldPositionStart);
          } else {
            handle.position.setFrom(worldPosition);
          }

          if (axis != null) {
            handle.visible = axis!.contains(handle.name);
          }
        }

        // If updating helper, skip rest of the loop
        continue;
      }

      // Align handles to current local or world rotation

      handle.quaternion.setFrom(quaternion);

      if (mode == GizmoType.translate || mode == GizmoType.scale) {
        // Hide translate and scale axis facing the camera

        const axisHideTreshold = 0.99;
        const planeHideTreshold = 0.2;

        if (handle.name == 'X') {
          if ((_alignVector
                  .setFrom(_unitX)
                  .applyQuaternion(quaternion)
                  .dot(eye)).abs() >
              axisHideTreshold) {
            handle.scale.setValues(1e-10, 1e-10, 1e-10);
            handle.visible = false;
          }
        }

        if (handle.name == 'Y') {
          if ((_alignVector
                  .setFrom(_unitY)
                  .applyQuaternion(quaternion)
                  .dot(eye)).abs() >
              axisHideTreshold) {
            handle.scale.setValues(1e-10, 1e-10, 1e-10);
            handle.visible = false;
          }
        }

        if (handle.name == 'Z') {
          if ((_alignVector
                  .setFrom(_unitZ)
                  .applyQuaternion(quaternion)
                  .dot(eye)).abs() >
              axisHideTreshold) {
            handle.scale.setValues(1e-10, 1e-10, 1e-10);
            handle.visible = false;
          }
        }

        if (handle.name == 'XY') {
          final ll = (_alignVector
              .setFrom(_unitZ)
              .applyQuaternion(quaternion)
              .dot(eye)).abs();

          if (ll < planeHideTreshold) {
            handle.scale.setValues(1e-10, 1e-10, 1e-10);
            handle.visible = false;
          }
        }

        if (handle.name == 'YZ') {
          if ((_alignVector
                  .setFrom(_unitX)
                  .applyQuaternion(quaternion)
                  .dot(eye)).abs() <
              planeHideTreshold) {
            handle.scale.setValues(1e-10, 1e-10, 1e-10);
            handle.visible = false;
          }
        }

        if (handle.name == 'XZ') {
          if ((_alignVector
                  .setFrom(_unitY)
                  .applyQuaternion(quaternion)
                  .dot(eye)).abs() <
              planeHideTreshold) {
            handle.scale.setValues(1e-10, 1e-10, 1e-10);
            handle.visible = false;
          }
        }
      } else if (mode == GizmoType.rotate) {
        // Align handles to current local or world rotation

        _tempQuaternion2.setFrom(quaternion);
        _alignVector
            .setFrom(eye)
            .applyQuaternion(_tempQuaternion.setFrom(quaternion).invert());

        if (handle.name.contains('E')) {
          handle.quaternion.setFromRotationMatrix(
              _lookAtMatrix.lookAt(eye, _zeroVector, _unitY));
        }

        if (handle.name == 'X') {
          _tempQuaternion.setFromAxisAngle(
              _unitX, math.atan2(-_alignVector.y, _alignVector.z));
          _tempQuaternion.multiplyQuaternions(
              _tempQuaternion2, _tempQuaternion);
          handle.quaternion.setFrom(_tempQuaternion);
        }

        if (handle.name == 'Y') {
          _tempQuaternion.setFromAxisAngle(
              _unitY, math.atan2(_alignVector.x, _alignVector.z));
          _tempQuaternion.multiplyQuaternions(
              _tempQuaternion2, _tempQuaternion);
          handle.quaternion.setFrom(_tempQuaternion);
        }

        if (handle.name == 'Z') {
          _tempQuaternion.setFromAxisAngle(
              _unitZ, math.atan2(_alignVector.y, _alignVector.x));
          _tempQuaternion.multiplyQuaternions(
              _tempQuaternion2, _tempQuaternion);
          handle.quaternion.setFrom(_tempQuaternion);
        }
      }
      // Hide disabled axes
      handle.visible = handle.visible && (!handle.name.contains('X') || showX);
      handle.visible = handle.visible && (!handle.name.contains('Y') || showY);
      handle.visible = handle.visible && (!handle.name.contains('Z') || showZ);
      handle.visible = handle.visible && (!handle.name.contains('E') || (showX && showY && showZ));

      // highlight selected axis

      handle.material?.userData["_color"] =
          handle.material?.userData["_color"] ?? handle.material?.color.clone();
      handle.material?.userData["_opacity"] =
          handle.material?.userData["_opacity"] ?? handle.material?.opacity;

      handle.material?.color.setFrom(handle.material?.userData["_color"]);
      handle.material?.opacity = handle.material?.userData["_opacity"];

      if (enabled && axis != null) {
        if (handle.name == axis) {
          handle.material?.color.setFromHex32(0xffff00);
          handle.material?.opacity = 1.0;
        } else if (axis!
                .split('')
                .where((a) {
                  return handle.name == a;
                })
                .toList()
                .isNotEmpty) {
          handle.material?.color.setFromHex32(0xffff00);
          handle.material?.opacity = 1.0;
        }
      }
    }

    super.updateMatrixWorld(force);
  }
}
