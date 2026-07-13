import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js_advanced_exporters/image/image_export.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:archive/archive.dart';

// --- Global Constants ---
final Uint8List FBX_FOOTER_ID = Uint8List.fromList([
  0xfa, 0xbc, 0xab, 0x09, 0xd0, 0xc8, 0xd4, 0x66, 0xb1, 0x76, 0xfb, 0x83, 0x1c, 0xf7, 0x26, 0x7e
]);

final Uint8List FBX_FINAL_MAGIC = Uint8List.fromList([
  0xf8, 0x5a, 0x8c, 0x6a, 0xde, 0xf5, 0xd9, 0x7e, 0xec, 0xe9, 0x0c, 0xe3, 0x75, 0x8f, 0x29, 0x0b
]);

const String FBX_CREATION_TIME = '1970-01-01 10:00:00:000';

final Uint8List FBX_FILE_ID = Uint8List.fromList([
  0x28, 0xb3, 0x2a, 0xeb, 0xb6, 0x24, 0xcc, 0xc2, 0xbf, 0xc8, 0xb0, 0x2a, 0xa9, 0x2b, 0xfc, 0xf1
]);

enum FBXExportTarget { Default, HorizonWorlds }
enum FBXExportFormat { ascii, binary }

class FBXExportOptions {
  FBXExportTarget? target;
  bool? binary;
  bool? embedTextures;

  FBXExportOptions({
    this.target, 
    this.binary, 
    this.embedTextures,
  });
}

class FBXExportResult {
  FBXExportTarget target;
  FBXExportFormat format;
  String fbxFileName;
  dynamic fbxData; // Will hold String or ByteBuffer/Uint8List
  Map<String, Uint8List> files;
  List<Texture> textures;
  Uint8List zipData;

  FBXExportResult({
    required this.target,
    required this.format,
    required this.fbxFileName,
    required this.fbxData,
    required this.files,
    required this.textures,
    required this.zipData,
  });
}

class FBXConnection {
  final int childId;
  final int parentId;
  final String type;
  final String? property;

  FBXConnection({
    required this.childId,
    required this.parentId,
    required this.type,
    this.property,
  });
}

class FBXTextureInfo {
  final int id;
  final String property;

  FBXTextureInfo({required this.id, required this.property});
}

class FBXCombinedTextures {
  final Texture? br;
  final Texture? meo;

  FBXCombinedTextures({this.br, this.meo});
}

class FBXTextureTransform {
  final List<double> translation;
  final List<double> rotation;
  final List<double> scaling;
  final List<double> pivot;

  FBXTextureTransform({
    required this.translation,
    required this.rotation,
    required this.scaling,
    required this.pivot,
  });
}

final Uint8List PNG_SIGNATURE = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

final Uint32List CRC32_TABLE = (() {
  final table = Uint32List(256);
  for (int i = 0; i < 256; i++) {
    int crc = i;
    for (int j = 0; j < 8; j++) {
      crc = ((crc & 1) != 0) ? (0xedb88320 ^ (crc >>> 1)) : (crc >>> 1);
    }
    table[i] = crc.toUnsigned(32);
  }
  return table;
})();

// --- Helper Functions ---

Uint8List _concatUint8Arrays(List<Uint8List> chunks) {
  final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
  final output = Uint8List(totalLength);
  int offset = 0;
  for (final chunk in chunks) {
    output.setRange(offset, offset + chunk.length, chunk);
    offset += chunk.length;
  }
  return output;
}

void _writeUint32BE(Uint8List target, int offset, int value) {
  target[offset] = (value >>> 24) & 0xff;
  target[offset + 1] = (value >>> 16) & 0xff;
  target[offset + 2] = (value >>> 8) & 0xff;
  target[offset + 3] = value & 0xff;
}

int _crc32(Uint8List data) {
  int crc = 0xffffffff;
  for (int i = 0; i < data.length; i++) {
    crc = CRC32_TABLE[(crc ^ data[i]) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff).toUnsigned(32);
}

Uint8List _createPngChunk(String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(utf8.encode(type));
  final lengthBytes = Uint8List(4);
  _writeUint32BE(lengthBytes, 0, data.length);

  final crcBytes = Uint8List(4);
  _writeUint32BE(crcBytes, 0, _crc32(_concatUint8Arrays([typeBytes, data])));

  return _concatUint8Arrays([lengthBytes, typeBytes, data, crcBytes]);
}

Uint8List _encodePngRgba(Uint8List rgba, int width, int height) {
  final stride = width * 4;
  final filtered = Uint8List(height * (stride + 1));

  for (int y = 0; y < height; y++) {
    final sourceOffset = y * stride;
    final targetOffset = y * (stride + 1);
    filtered[targetOffset] = 0; // Filter type 0 (None)
    
    final sub = rgba.buffer.asUint8List(rgba.offsetInBytes + sourceOffset, stride);
    filtered.setRange(targetOffset + 1, targetOffset + 1 + stride, sub);
  }

  final ihdr = Uint8List(13);
  _writeUint32BE(ihdr, 0, width);
  _writeUint32BE(ihdr, 4, height);
  ihdr[8] = 8;  // Bit depth
  ihdr[9] = 6;  // Color type (RGBA)
  ihdr[10] = 0; // Compression method
  ihdr[11] = 0; // Filter method
  ihdr[12] = 0; // Interlace method

  // Using package:archive's ZLibEncoder for zlibSync
  final idat = Uint8List.fromList(ZLibEncoder().encode(filtered, level: 9));

  return _concatUint8Arrays([
    PNG_SIGNATURE,
    _createPngChunk('IHDR', ihdr),
    _createPngChunk('IDAT', idat),
    _createPngChunk('IEND', Uint8List(0))
  ]);
}

// Rewritten to natively use package:archive instead of streaming fflate callbacks
Future<Uint8List> _createZipData(Map<String, Uint8List> files) async {
  final archive = Archive();

  for (final entry in files.entries) {
    final fileName = entry.key;
    final contents = entry.value;

    final archiveFile = ArchiveFile(
      fileName, 
      contents.length, 
      contents
    );
    archive.addFile(archiveFile);
  }

  final zipBytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipBytes);
}

class FBXExporter{
  _FBXExporter exporter = _FBXExporter();

	FBXExporter();

  Future<void> export(String fileName, Object3D object, {String? path, FBXExportOptions? options }) async{
    SaveFile.saveBytes(
      printName: fileName,
      fileType: 'zip', 
      bytes: (await exporter.parse(object, fileName: fileName, options: options)).zipData,
      path: path
    );
  }

  Future<FBXExportResult?> parse(Object3D object, {String fileName = 'model', FBXExportOptions? options }) async{
    return await exporter.parse(object, fileName: fileName, options: options);
  }
}

class _FBXExporter {
  int version = 7400; // FBX version 7.4
  int idCounter = 1000; // Starting ID for objects
  Map<String, Map<int, dynamic>> objects = {};
  List<FBXConnection> connections = [];
  List<Map<String, dynamic>> globalSettings = [];
  List<Texture> textures = [];
  bool embedTextures = false;
  final Set<String> warningKeys = {};

  int fbxKTimeTicksPerSecond = 46186158000;
  int get currentTimestampTicks => (DateTime.now().millisecondsSinceEpoch ~/ 1000) * fbxKTimeTicksPerSecond;

  /// Helper for indentation (tabs per level)
  String indent(int level) {
    return '\t' * level;
  }

  /// Constructs a new FBX exporter.
  _FBXExporter() {
    globalSettings = [
      {'name': 'UpAxis', 'type': 'int', 'type2': 'Integer', 'value': 1},
      {'name': 'UpAxisSign', 'type': 'int', 'type2': 'Integer', 'value': 1},
      {'name': 'FrontAxis', 'type': 'int', 'type2': 'Integer', 'value': 2},
      {'name': 'FrontAxisSign', 'type': 'int', 'type2': 'Integer', 'value': 1},
      {'name': 'CoordAxis', 'type': 'int', 'type2': 'Integer', 'value': 0},
      {'name': 'CoordAxisSign', 'type': 'int', 'type2': 'Integer', 'value': 1},
      {'name': 'OriginalUpAxis', 'type': 'int', 'type2': 'Integer', 'value': 1},
      {'name': 'OriginalUpAxisSign', 'type': 'int', 'type2': 'Integer', 'value': 1},
      {'name': 'UnitScaleFactor', 'type': 'double', 'type2': 'Number', 'value': 1.0},
      {'name': 'OriginalUnitScaleFactor', 'type': 'double', 'type2': 'Number', 'value': 1.0},
      {'name': 'TimeSpanStart', 'type': 'KTime', 'type2': 'Time', 'value': 0},
      {'name': 'TimeSpanStop', 'type': 'KTime', 'type2': 'Time', 'value': 0},
      {'name': 'TimeMode', 'type': 'enum', 'type2': '', 'value': 0},
      {'name': 'CustomFrameRate', 'type': 'double', 'type2': 'Number', 'value': 30.0001}
    ];
  }

  /// Exports the given object to FBX format.
  Future<FBXExportResult> parse(Object3D object, {String fileName = 'model', FBXExportOptions? options}) async {
    final target = options?.target ?? FBXExportTarget.Default;
    final binary = options?.binary ?? false;
    final embed = options?.embedTextures ?? false;

    final format = binary ? FBXExportFormat.binary : FBXExportFormat.ascii;
    final fbxFileName = '$fileName.fbx';

    reset();
    
    // Explicit dynamic safety call check for updateMatrixWorld
    object.updateMatrixWorld(true);

    embedTextures = embed;
    traverseObject(object, null);

    final fbxData = generateFBX(target, binary);
    final gatheredTextures = collectTextures();
    final files = await createFiles(fbxFileName, fbxData, gatheredTextures);
    final zipData = await _createZipData(files);

    return FBXExportResult(
      target: target,
      format: format,
      fbxFileName: fbxFileName,
      fbxData: fbxData,
      files: files,
      textures: gatheredTextures,
      zipData: zipData,
    );
  }

  void reset() {
    idCounter = 1000;
    objects = {
      'Model': {},
      'Geometry': {},
      'Material': {},
      'Texture': {},
      'Video': {},
      'NodeAttribute': {},
    };
    connections = [];
    textures = [];
    embedTextures = false;
    warningKeys.clear();
  }
  void traverseObject(Object3D object, int? parentId) {
    final objectId = getNextId();

    // Create Model node
    createModel(object, objectId);
    createNodeAttributeForObject(object, objectId);
    createLookAtTargetForObject(object, objectId);

    // Connect to parent
    if (parentId != null) {
      addConnection(objectId, parentId, 'OO');
    } else {
      // Top-level objects must be connected to the root (ID 0) for Blender and FBX SDK to import them
      addConnection(objectId, 0, 'OO');
    }

    // Handle specific object types
    // Note: If three_js_core uses a runtime type check like 'is Mesh' or a property flag, update here
    if (object is Mesh) {
      handleMesh(object, objectId);
    }

    // Recurse on children
    for (final child in object.children) {
      traverseObject(child, objectId);
    }
  }

  void createModel(Object3D object, int id) {
    // Check if object is Camera or Light based on your package implementation
    final hasNodeAttribute = object is Camera || object is Light;

    final model = {
      'id': id,
      'attrName': object.name,
      'fbxClass': 'Model',
      'attrType': getModelType(object),
      'Version': 232,
      'Culling': 'CullingOff',
      'Properties70': {
        'P': createModelPropertyList(
          object.position.toList(),
          getEulerRotation(object),
          object.scale.toList(),
          getRotationOrder(object),
          object.visible,
          hasNodeAttribute ? 0 : -1,
        )
      }
    };

    objects['Model']![id] = model;
  }

  List<dynamic> createModelPropertyList(
    List<double> position,
    List<double> rotation,
    List<double> scale,
    int rotationOrder,
    bool visible, [
    int defaultAttributeIndex = -1,
  ]) {
    return [
      {'name': 'InheritType', 'type': 'enum', 'value': 1},
      {'name': 'RotationOrder', 'type': 'enum', 'value': rotationOrder},
      {'name': 'DefaultAttributeIndex', 'type': 'int', 'label': 'Integer', 'value': defaultAttributeIndex},
      createTypedScalarProperty('Visibility', 'Visibility', visible ? 1.0 : 0.0, 'D', '', 'A'),
      {'name': 'Visibility Inheritance', 'type': 'Visibility Inheritance', 'value': 1},
      {'name': 'Lcl Translation', 'type': 'Lcl_Translation', 'value': position},
      {'name': 'Lcl Rotation', 'type': 'Lcl_Rotation', 'value': rotation},
      {'name': 'Lcl Scaling', 'type': 'Lcl_Scaling', 'value': scale}
    ];
  }

  Map<String, dynamic> createTypedScalarProperty(
    String name,
    String type,
    double value,
    String encodingType, [
    String label = '',
    String flag = '',
  ]) {
    return {
      'propertyList': [
        name,
        type,
        label,
        flag,
        {'value': value, 'encodingType': encodingType}
      ]
    };
  }

  void createNodeAttributeForObject(Object3D object, int modelId) {
    if (object is Camera) {
      final nodeAttributeId = getNextId();
      createCameraAttribute(object, nodeAttributeId);
      addConnection(nodeAttributeId, modelId, 'OO');
      return;
    }
    if (object is Light) {
      final nodeAttributeId = getNextId();
      createLightAttribute(object, nodeAttributeId);
      addConnection(nodeAttributeId, modelId, 'OO');
    }
  }

  void createLookAtTargetForObject(Object3D object, int modelId) {
    if (object is! DirectionalLight && object is! SpotLight) {
      return;
    }

    // Checking for a target property on the light object safely
    dynamic targetObj = (object as dynamic).target;
    if (targetObj == null || targetObj is! Object3D) {
      return;
    }

    targetObj.updateMatrixWorld(true);
    
    final targetPosition = Vector3();
    targetObj.getWorldPosition(targetPosition);
    
    final targetId = getNextId();
    final nameStr = targetObj.name;
    final targetName = nameStr.isNotEmpty
        ? nameStr 
        : "${object.name.isNotEmpty ? object.name : 'Light'}_Target";

    objects['Model']![targetId] = {
      'id': targetId,
      'attrName': targetName,
      'fbxClass': 'Model',
      'attrType': 'Null',
      'Version': 232,
      'Culling': 'CullingOff',
      'Properties70': {
        'P': createModelPropertyList(
          targetPosition.toList(),
          [0.0, 0.0, 0.0],
          [1.0, 1.0, 1.0],
          5,
          false,
          -1,
        )
      }
    };

    // Safely append to the parent object's dynamic list property
    final modelNode = objects['Model']![modelId];
    if (modelNode != null) {
      final properties = modelNode['Properties70']?['P'] as List<dynamic>?;
      properties?.add({
        'name': 'LookAtProperty',
        'type': 'object',
        'label': '',
        'value': '',
      });
    }

    addConnection(targetId, modelId, 'OP', 'LookAtProperty');
  }

  void createCameraAttribute(Camera camera, int id) {
    final attrName = camera.name.isNotEmpty ? camera.name : 'Camera';
    
    // Check if methods exist natively, otherwise fall back to defaults
    final filmWidth = (camera as dynamic).getFilmWidth is Function 
        ? (camera as dynamic).getFilmWidth() 
        : 36.0;
    final filmHeight = (camera as dynamic).getFilmHeight is Function 
        ? (camera as dynamic).getFilmHeight() 
        : 24.0;
        
    final aspect = getCameraAspect(camera);
    final focalLength = (camera as dynamic).getFocalLength is Function 
        ? (camera as dynamic).getFocalLength() 
        : null;

    final List<Map<String, dynamic>> properties = [
      {'name': 'CameraProjectionType', 'type': 'enum', 'value': camera is OrthographicCamera ? 1 : 0},
      {'name': 'AspectWidth', 'type': 'double', 'label': 'Number', 'value': aspect * 1000.0},
      {'name': 'AspectHeight', 'type': 'double', 'label': 'Number', 'value': 1000.0},
      {'name': 'AspectW', 'type': 'double', 'label': 'Number', 'value': aspect * 1000.0},
      {'name': 'AspectH', 'type': 'double', 'label': 'Number', 'value': 1000.0},
      {'name': 'NearPlane', 'type': 'double', 'label': 'Number', 'value': camera.near * 1000.0},
      {'name': 'FarPlane', 'type': 'double', 'label': 'Number', 'value': camera.far * 1000.0},
      {'name': 'FilmWidth', 'type': 'double', 'label': 'Number', 'value': filmWidth},
      {'name': 'FilmHeight', 'type': 'double', 'label': 'Number', 'value': filmHeight}
    ];

    if (camera is PerspectiveCamera) {
      properties.add({'name': 'FieldOfView', 'type': 'double', 'label': 'Number', 'value': camera.fov});
    }

    if (focalLength != null && focalLength is num && focalLength.isFinite) {
      properties.add({'name': 'FocalLength', 'type': 'double', 'label': 'Number', 'value': focalLength.toDouble()});
    }

    if (camera is OrthographicCamera) {
      properties.add({'name': 'OrthoZoom', 'type': 'double', 'label': 'Number', 'value': getCameraOrthoZoom(camera)});
    }

    // Checking optional focus property safely
    properties.add({'name': 'FocusDistance', 'type': 'double', 'label': 'Number', 'value': camera.focus});

    objects['NodeAttribute']![id] = {
      'id': id,
      'attrName': attrName,
      'fbxClass': 'NodeAttribute',
      'attrType': 'Camera',
      'Properties70': {'P': properties}
    };
  }

  void createLightAttribute(Light light, int id) {
    final attrName = light.name.isNotEmpty ? light.name : 'Light';
    
    // Grabbing color values as an array (usually [r, g, b])
    final colorArray = light.color is Color 
        ? [light.color!.red, light.color!.green, light.color!.blue]
        : [1.0, 1.0, 1.0];

    final List<Map<String, dynamic>> properties = [
      {'name': 'LightType', 'type': 'enum', 'value': getLightType(light)},
      {'name': 'Color', 'type': 'ColorRGB', 'label': 'Color', 'value': colorArray},
      {'name': 'Intensity', 'type': 'double', 'label': 'Number', 'value': light.intensity * 100.0},
      {'name': 'CastLightOnObject', 'type': 'bool', 'value': light.visible ? 1 : 0},
      {'name': 'CastShadow', 'type': 'bool', 'value': light.castShadow ? 1 : 0},
      {'name': 'CastShadows', 'type': 'bool', 'value': light.castShadow ? 1 : 0}
    ];

    // Safely check light distance traits (Point/Spot light options)
    if (light.distance != null) {
      final double distance = light.distance ?? 0; 
      properties.add({'name': 'EnableFarAttenuation', 'type': 'bool', 'value': distance > 0 ? 1 : 0});
      if (distance > 0) {
        properties.add({'name': 'FarAttenuationEnd', 'type': 'double', 'label': 'Number', 'value': distance});
      }
    }

    if (light is SpotLight) {
      // Convert radians to degrees using imported packages or raw math formulas
      final double outerAngle = MathUtils.radToDeg(light.angle!);
      final double innerAngle = outerAngle * (1.0 - light.penumbra!);
      
      properties.add({'name': 'OuterAngle', 'type': 'double', 'label': 'Number', 'value': outerAngle});
      properties.add({'name': 'InnerAngle', 'type': 'double', 'label': 'Number', 'value': innerAngle});
    }

    objects['NodeAttribute']![id] = {
      'id': id,
      'attrName': attrName,
      'fbxClass': 'NodeAttribute',
      'attrType': 'Light',
      'Properties70': {'P': properties}
    };
  }

  double getCameraAspect(Camera camera) {
    if (camera is PerspectiveCamera) {
      return (camera.aspect as num).toDouble();
    }

    final double width = camera.right - camera.left;
    final double height = camera.top - camera.bottom;
    if (height != 0.0) {
      return (width / height).abs();
    }
    

    return 1.0;
  }

  double getCameraOrthoZoom(Camera camera) {
    final dynamic camDyn = camera;
    final double left = camDyn.left != null ? (camDyn.left as num).toDouble() : 0.0;
    final double right = camDyn.right != null ? (camDyn.right as num).toDouble() : 0.0;
    final double top = camDyn.top != null ? (camDyn.top as num).toDouble() : 0.0;
    final double bottom = camDyn.bottom != null ? (camDyn.bottom as num).toDouble() : 0.0;
    
    final double width = (right - left).abs();
    final double height = (top - bottom).abs();
    final double zoom = camDyn.zoom != null ? (camDyn.zoom as num).toDouble() : 1.0;
    
    return math.max(width, height) / zoom;
  }

  int getLightType(Light light) {
    if (light is DirectionalLight) return 1;
    if (light is SpotLight) return 2;
    if (light is PointLight) return 0;

    final String typeStr = (light as dynamic).type ?? 'Unknown';
    warnOnce(
      'unsupported-light-type:$typeStr',
      'FBX export does not have a direct mapping for $typeStr; exporting "${light.name.isNotEmpty ? light.name : typeStr}" as a PointLight.'
    );
    return 0;
  }

  String getModelType(Object3D object) {
    if (object is Mesh) return 'Mesh';
    if (object is Light) return 'Light';
    if (object is Camera) return 'Camera';
    return 'Null';
  }

  List<String> getUvAttributeNames(BufferGeometry geometry) {
    // Collect all attribute keys from the geometry object layout
    final attributeNames = geometry.attributes.keys.toList();
    final uvRegex = RegExp(r'^uv\d+$');

    final filteredNames = attributeNames.where((name) {
      return name == 'uv' || uvRegex.hasMatch(name);
    }).toList();

    filteredNames.sort((a, b) {
      if (a == 'uv') return -1;
      if (b == 'uv') return 1;
      
      final aNum = int.tryParse(a.substring(2)) ?? 0;
      final bNum = int.tryParse(b.substring(2)) ?? 0;
      return aNum.compareTo(bNum);
    });

    return filteredNames;
  }

  List<double> getEulerRotation(Object3D object) {
    final order = object.rotation.order;
    final euler = Euler().setFromQuaternion(object.quaternion, order);
    
    return [
      MathUtils.radToDeg(euler.x.toDouble()),
      MathUtils.radToDeg(euler.y.toDouble()),
      MathUtils.radToDeg(euler.z.toDouble()),
    ];
  }

  int getRotationOrder(Object3D object) {
    switch (object.rotation.order) {
      case RotationOrders.zyx:
        return 0;
      case RotationOrders.yzx:
        return 1;
      case RotationOrders.xzy:
        return 2;
      case RotationOrders.zxy:
        return 3;
      case RotationOrders.yxz:
        return 4;
      case RotationOrders.xyz:
        return 5;
    }
  }

  void handleMesh(Mesh mesh, int modelId) {
    // Capture materials array reliably whether single instance or a structured list
    final List<Material> materials = [];
    if (mesh.material is List) {
      materials.addAll(List<Material>.from(mesh.material as List));
    } else if (mesh.material != null) {
      materials.add(mesh.material!);
    }

    final geometryId = getNextId();

    // Create Geometry
    createGeometry(mesh.geometry!, geometryId, materials.length);

    // Connect Geometry to Model
    addConnection(geometryId, modelId, 'OO');

    // Handle materials and related texture attachments
    for (final material in materials) {
      final materialId = getNextId();

      // Create Material
      createMaterial(material, materialId);

      // Create Textures if they exist
      final textureInfos = createTextures(material);

      // Connect Material to Model
      addConnection(materialId, modelId, 'OO');

      // Connect Textures to Material
      for (final textureInfo in textureInfos) {
        addConnection(textureInfo.id, materialId, 'OP', textureInfo.property);
      }
    }
  }

  void createGeometry(BufferGeometry geometry, int id, [int materialCount = 1]) {
    final Map<String, dynamic> geo = {
      'id': id,
      'attrName': (geometry.name.isNotEmpty) ? geometry.name : 'Geometry',
      'fbxClass': 'Geometry',
      'attrType': 'Mesh',
      'Properties70': <String, dynamic>{}
    };

    // Vertices
    final positionAttr = geometry.attributes['position'];
    if (positionAttr != null) {
      final positions = positionAttr.array;
      geo['Vertices'] = {
        'a': List<double>.from(positions.map((e) => e.toDouble())),
        'dataType': 'd'
      };
    }

    // Polygon indices and UV handling
    final vertexCount = positionAttr?.count ?? 0;
    final List<int> polygonVertexIndex = [];
    final List<int> polygonVertices = [];
    final indexAttr = geometry.index;

    if (indexAttr != null) {
      // Indexed geometry
      final indices = indexAttr.array;
      for (int i = 0; i < indices.length; i += 3) {
        final i0 = indices[i].toInt();
        final i1 = indices[i + 1].toInt();
        final i2 = indices[i + 2].toInt();
        polygonVertexIndex.addAll([i0, i1, -(i2 + 1)]);
        polygonVertices.addAll([i0, i1, i2]);
      }
    } else {
      // Non-indexed geometry
      for (int i = 0; i < vertexCount; i += 3) {
        polygonVertexIndex.addAll([i, i + 1, -((i + 2) + 1)]);
        polygonVertices.addAll([i, i + 1, i + 2]);
      }
    }

    geo['PolygonVertexIndex'] = {'a': polygonVertexIndex, 'dataType': 'i'};
    final polygonCount = polygonVertexIndex.length ~/ 3;

    // Normals
    final normalAttr = geometry.attributes['normal'];
    if (normalAttr != null) {
      final normals = normalAttr.array;
      final normalArray = List<double>.from(normals.map((e) => e.toDouble()));
      final List<int> normalIndices = indexAttr != null
          ? List<int>.from(indexAttr.array.map((e) => e.toInt()))
          : List<int>.generate(vertexCount, (index) => index);

      geo['LayerElementNormal'] = {
        0: {
          'Version': 102,
          'Name': '',
          'MappingInformationType': 'ByPolygonVertex',
          'ReferenceInformationType': 'IndexToDirect',
          'Normals': {'a': normalArray, 'dataType': 'd'},
          'NormalsIndex': {'a': normalIndices, 'dataType': 'i'}
        }
      };
    }

    // Tangents
    final tangentAttr = geometry.attributes['tangent'];
    if (tangentAttr != null) {
      final tangents = tangentAttr.array;
      final List<double> tangentArray = [];

      if (indexAttr != null) {
        // For indexed geometry, tangents need to be in the same order as polygon vertices
        final indices = indexAttr.array;
        for (int i = 0; i < indices.length; i++) {
          final idx = indices[i].toInt() * 4;
          tangentArray.addAll([
            tangents[idx].toDouble(),
            tangents[idx + 1].toDouble(),
            tangents[idx + 2].toDouble()
          ]);
        }
      } else {
        // For non-indexed geometry, copy tangents but only the first 3 components (x,y,z)
        for (int i = 0; i < tangents.length; i += 4) {
          tangentArray.addAll([
            tangents[i].toDouble(),
            tangents[i + 1].toDouble(),
            tangents[i + 2].toDouble()
          ]);
        }
      }

      geo['LayerElementTangent'] = {
        0: {
          'Version': 101,
          'Name': 'Tangents',
          'MappingInformationType': 'ByPolygonVertex',
          'ReferenceInformationType': 'Direct',
          'Tangents': {'a': tangentArray, 'dataType': 'd'}
        }
      };
    }

    // UV layers
    final uvAttributeNames = getUvAttributeNames(geometry);
    if (uvAttributeNames.isNotEmpty) {
      final Map<int, dynamic> layerElementUV = {};
      for (int layerIndex = 0; layerIndex < uvAttributeNames.length; layerIndex++) {
        final attributeName = uvAttributeNames[layerIndex];
        final uvAttribute = geometry.getAttributeFromString(attributeName);
        if (uvAttribute == null || uvAttribute.itemSize < 2) continue;

        final List<double> uvArray = [];
        final uvBuffer = uvAttribute.array;

        for (final vertexIndex in polygonVertices) {
          final uvOffset = vertexIndex * uvAttribute.itemSize;
          uvArray.add(uvBuffer[uvOffset].toDouble());
          uvArray.add(1.0 - uvBuffer[uvOffset + 1].toDouble());
        }

        layerElementUV[layerIndex] = {
          'Version': 101,
          'Name': layerIndex == 0 ? 'UVMap' : attributeName,
          'MappingInformationType': 'ByPolygonVertex',
          'ReferenceInformationType': 'Direct',
          'UV': {'a': uvArray, 'dataType': 'd'}
        };
      }
      geo['LayerElementUV'] = layerElementUV;
    }

    // Vertex Colors
    final BufferAttribute? colorAttr = geometry.attributes['color'];
    if (colorAttr != null) {
      final colors = colorAttr.array;
      final List<double> colorArray = [];
      final int itemSize = colorAttr.itemSize;

      if (indexAttr != null) {
        // For indexed geometry, colors need to be in the same order as polygon vertices
        final indices = indexAttr.array;
        for (int i = 0; i < indices.length; i++) {
          final idx = indices[i].toInt() * itemSize;
          for (int j = 0; j < itemSize; j++) {
            colorArray.add(colors[idx + j].toDouble());
          }
          // Pad to 4 components if needed
          while (colorArray.length % 4 != 0) {
            colorArray.add(1.0);
          }
        }
      } else {
        for (int i = 0; i < colors.length; i += itemSize) {
          for (int j = 0; j < itemSize; j++) {
            colorArray.add(colors[i + j].toDouble());
          }
          // Pad to 4 components if needed
          while (colorArray.length % 4 != 0) {
            colorArray.add(1.0);
          }
        }
      }

      geo['LayerElementColor'] = {
        0: {
          'Version': 101,
          'Name': 'Colors',
          'MappingInformationType': 'ByPolygonVertex',
          'ReferenceInformationType': 'Direct',
          'Colors': {'a': colorArray, 'dataType': 'd'}
        }
      };
    }

    // Materials per Poly group configuration
    if (polygonCount > 0 && (materialCount > 1 || geometry.groups.isNotEmpty)) {
      final List<int> materialIndices = List<int>.filled(polygonCount, 0);
      for (final group in geometry.groups) {
        final int groupMaterialIndex = group['materialIndex'] ?? 0;
        final materialIndex = math.max(0, math.min(materialCount - 1, groupMaterialIndex));
        final int start = group['start'] ?? 0;
        final polygonStart = math.max(0, (start ~/ 3).floor());
        final int count = group['count'] ?? 0;
        final groupPolygonCount = math.max(0, (count ~/ 3).floor());

        for (int i = 0; i < groupPolygonCount; i++) {
          final polygonIndex = polygonStart + i;
          if (polygonIndex >= materialIndices.length) break;
          materialIndices[polygonIndex] = materialIndex;
        }
      }

      geo['LayerElementMaterial'] = {
        0: {
          'Version': 101,
          'Name': '',
          'MappingInformationType': 'ByPolygon',
          'ReferenceInformationType': 'IndexToDirect',
          'Materials': {'a': materialIndices, 'dataType': 'i'}
        }
      };
    }

    objects['Geometry']![id] = geo;
  }

  void createMaterial(Material material, int id) {
    String shadingModel = 'phong';
    String attrType = 'Phong';

    // Extract type name from the material instance
    final matType = material.type;

    if (matType == 'MeshLambertMaterial' || matType == 'MeshBasicMaterial') {
      shadingModel = 'lambert';
      attrType = 'Lambert';
    } else if (matType == 'MeshPhongMaterial') {
      shadingModel = 'phong';
      attrType = 'Phong';
    }

    final isLambertShading = shadingModel == 'lambert';
    final Map<String, dynamic> mat = {
      'id': id,
      'attrName': (material.name.isNotEmpty) ? material.name : 'Material',
      'fbxClass': 'Material',
      'attrType': attrType,
      'Version': 102,
      'ShadingModel': shadingModel,
      'Properties70': {'P': <Map<String, dynamic>>[]}
    };

    final isStandardMaterial = matType == 'MeshStandardMaterial' || material is MeshStandardMaterial;
    final List<dynamic> propertyList = mat['Properties70']['P'];

    // Diffuse color
    final color = material.color;
    propertyList.add({
      'name': 'DiffuseColor',
      'type': 'ColorRGB',
      'label': 'Color',
      'value': [color.red, color.green, color.blue]
    });

    // Ambient color (for AO)
    if (material.aoMap != null) {
      propertyList.add({
        'name': 'AmbientColor',
        'type': 'ColorRGB',
        'label': 'Color',
        'value': [1.0, 1.0, 1.0]
      });
    }

    // Specular color (for metallic)
    final double metalness = material.metalness;
    propertyList.add({
      'name': 'SpecularColor',
      'type': 'ColorRGB',
      'label': 'Color',
      'value': [metalness, metalness, metalness]
    });
    propertyList.add({
      'name': 'ReflectionFactor',
      'type': 'double',
      'label': 'Number',
      'value': metalness
    });

    // Emissive color
    if (isStandardMaterial && material.emissive != null) {
      final emissive = material.emissive!;
      propertyList.add({
        'name': 'EmissiveColor',
        'type': 'ColorRGB',
        'label': 'Color',
        'value': [emissive.red, emissive.green, emissive.blue]
      });
    }

    // Opacity
    final double opacity = material.opacity;
    final bool transparent = material.transparent;
    if (transparent || opacity < 1.0) {
      propertyList.add({
        'name': 'Opacity',
        'type': 'double',
        'label': 'Number',
        'value': opacity
      });
    }

    // Side Configuration
    if (material.side == DoubleSide || material.side == 2) {
      propertyList.add({'name': 'DoubleSided', 'type': 'bool', 'value': 1});
    }

    // Shininess (for roughness)
    if (!isLambertShading) {
      double shininess = 30.0; // default
      final double roughness = material.roughness;
      shininess = math.pow(10.0 * (1.0 - roughness), 2).toDouble();

      if (material.shininess != null) {
        shininess = material.shininess!;
      }
      
      propertyList.add({
        'name': 'Shininess',
        'type': 'double',
        'label': 'Number',
        'value': shininess
      });
    }

    objects['Material']![id] = mat;
  }

  List<FBXTextureInfo> createTextures(Material material) {
    final List<FBXTextureInfo> textureInfos = [];
    final String materialName = material.name.isNotEmpty ? material.name : 'Material';

    // Create combined textures if needed
    final combinedTextures = createCombinedTexture(material, materialName);

    // Handle BR texture (Base Color + Roughness)
    if (combinedTextures.br != null) {
      final textureId = getNextId();
      final videoId = getNextId();
      createTexture(combinedTextures.br!, textureId, videoId, 'DiffuseColor', materialName, 'BR');
      textureInfos.add(FBXTextureInfo(id: textureId, property: 'DiffuseColor'));
    } else {
      // Fallback to individual diffuse texture
      if (material.map != null) {
        final textureId = getNextId();
        final videoId = getNextId();
        createTexture(material.map!, textureId, videoId, 'DiffuseColor', materialName, 'Diffuse');
        textureInfos.add(FBXTextureInfo(id: textureId, property: 'DiffuseColor'));
      }
      
      // Also create individual roughness texture if it exists
      if (material.roughnessMap != null) {
        final textureId = getNextId();
        final videoId = getNextId();
        createTexture(material.roughnessMap!, textureId, videoId, 'SpecularFactor', materialName, 'Roughness');
        textureInfos.add(FBXTextureInfo(id: textureId, property: 'SpecularFactor'));
      }
    }

    // Handle MEO texture (Metalness + Emissive + AO)
    if (combinedTextures.meo != null) {
      final textureId = getNextId();
      final videoId = getNextId();
      createTexture(combinedTextures.meo!, textureId, videoId, 'SpecularColor', materialName, 'MEO');
      textureInfos.add(FBXTextureInfo(id: textureId, property: 'SpecularColor'));
    } else {
      // Fallback to individual textures
      if (material.metalnessMap != null) {
        final textureId = getNextId();
        final videoId = getNextId();
        createTexture(material.metalnessMap!, textureId, videoId, 'SpecularColor', materialName, 'Metallic');
        textureInfos.add(FBXTextureInfo(id: textureId, property: 'SpecularColor'));
      }
      if (material.emissiveMap != null) {
        final textureId = getNextId();
        final videoId = getNextId();
        createTexture(material.emissiveMap!, textureId, videoId, 'EmissiveColor', materialName, 'Emissive');
        textureInfos.add(FBXTextureInfo(id: textureId, property: 'EmissiveColor'));
      }
      if (material.aoMap != null) {
        final textureId = getNextId();
        final videoId = getNextId();
        createTexture(material.aoMap!, textureId, videoId, 'AmbientColor', materialName, 'AO');
        textureInfos.add(FBXTextureInfo(id: textureId, property: 'AmbientColor'));
      }
    }

    // Handle normal map (always separate)
    if (material.normalMap != null) {
      final textureId = getNextId();
      final videoId = getNextId();
      createTexture(material.normalMap!, textureId, videoId, 'NormalMap', materialName, 'Normal');
      textureInfos.add(FBXTextureInfo(id: textureId, property: 'NormalMap'));
    }

    if (material.alphaMap != null) {
      final textureId = getNextId();
      final videoId = getNextId();
      createTexture(material.alphaMap!, textureId, videoId, 'TransparencyFactor', materialName, 'Alpha');
      textureInfos.add(FBXTextureInfo(id: textureId, property: 'TransparencyFactor'));
    }

    return textureInfos;
  }

  void createTexture(
    Texture texture, 
    int textureId, 
    int videoId, 
    String textureType, 
    String materialName, 
    String slotName
  ) {
    // Ensure filename has .png extension but avoid double extensions
    late String fileName;
    late String baseName;
    
    if (texture.name.isNotEmpty) {
      baseName = texture.name.replaceFirst(RegExp(r'\.png$', caseSensitive: false), '');
      fileName = '$baseName.png';
    } 
    else {
      baseName = '${materialName}_$slotName';
      fileName = '$baseName.png';
    }

    // Extract texture data for embedding
    final textureData = extractTextureData(texture);
    final textureTransform = getFbxTextureTransform(texture);

    final Map<String, dynamic> tex = {
      'id': textureId,
      'attrName': baseName,
      'fbxClass': 'Texture',
      'attrType': '',
      'FileName': fileName,
      'RelativeFilename': fileName,
      'Properties70': {
        'P': <Map<String, dynamic>>[
          {'name': 'Type', 'type': 'KString', 'value': 'TextureVideoClip'},
          {'name': 'RelativeFilename', 'type': 'KString', 'value': fileName}
        ]
      }
    };

    final List<dynamic> propertyList = tex['Properties70']['P'];

    propertyList.add({'name': 'TextureTypeUse', 'type': 'KString', 'value': textureType});
    propertyList.add({'name': 'WrapModeU', 'type': 'enum', 'value': getTextureWrapMode(texture.wrapS, 'U', baseName)});
    propertyList.add({'name': 'WrapModeV', 'type': 'enum', 'value': getTextureWrapMode(texture.wrapT, 'V', baseName)});
    
    // Explicit dynamic layout fallback mapping for Vector2 fields like offset/repeat
    final double offsetX = texture.offset.x;
    final double offsetY = texture.offset.y;
    final double repeatX = texture.repeat.x;
    final double repeatY = texture.repeat.y;

    propertyList.add({
      'name': 'Translation', 
      'type': 'Vector3D', 
      'label': 'Vector', 
      'value': [offsetX, offsetY, 0.0]
    });
    propertyList.add({
      'name': 'Scaling', 
      'type': 'Vector3D', 
      'label': 'Vector', 
      'value': [repeatX, repeatY, 1.0]
    });

    // Store the processed texture data for later download (legacy support)
    final clonedTexture = prepareTextureForExport(texture);
    clonedTexture.name = fileName.replaceAll('.png', '');

    // Check if a texture with this name already exists
    final bool exists = textures.any((t) => t.name == clonedTexture.name);
    if (!exists) {
      textures.add(clonedTexture);
    }

    // UV set
    propertyList.add({'name': 'UVSet', 'type': 'KString', 'value': getTextureUvSet(texture)});
    propertyList.add({'name': 'Translation', 'type': 'Vector3D', 'label': 'Vector', 'value': textureTransform.translation});
    propertyList.add({'name': 'Rotation', 'type': 'Vector3D', 'label': 'Vector', 'value': textureTransform.rotation});
    propertyList.add({'name': 'Scaling', 'type': 'Vector3D', 'label': 'Vector', 'value': textureTransform.scaling});
    propertyList.add({'name': 'RotationPivot', 'type': 'Vector3D', 'label': 'Vector', 'value': textureTransform.pivot});
    propertyList.add({'name': 'ScalingPivot', 'type': 'Vector3D', 'label': 'Vector', 'value': textureTransform.pivot});

    // Texture type
    propertyList.add({'name': 'UseMaterial', 'type': 'bool', 'value': 1});

    objects['Texture']![textureId] = tex;

    final videoAttrName = '${baseName}_Video';
    final Map<String, dynamic> video = {
      'id': videoId,
      'attrName': videoAttrName,
      'fbxClass': 'Video',
      'attrType': 'Clip',
      'Type': 'Clip',
      'FileName': fileName,
      'RelativeFilename': fileName,
      'Properties70': {
        'P': <Map<String, dynamic>>[
          {'name': 'Path', 'type': 'KString', 'value': fileName}
        ]
      }
    };

    // Add embedded texture data if available
    if (textureData != null) {
      video['Content'] = textureData;
    }

    objects['Video']![videoId] = video;

    // Connect texture to its video source
    addConnection(videoId, textureId, 'OO');
  }

  String getTextureUvSet(Texture texture) {
    final int channel = texture.channel;
    return channel <= 0 ? 'UVMap' : 'uv$channel';
  }

  int getTextureWrapMode(int wrapMode, String axis, String textureName) {
    // Check against three_js wrapping constants or specific enum indices
    if (wrapMode == ClampToEdgeWrapping || wrapMode == 1001) {
      return 1;
    }
    
    if (wrapMode == MirroredRepeatWrapping || wrapMode == 1002) {
      warnOnce(
        'mirrored-repeat-wrapping',
        'FBX export does not support MirroredRepeatWrapping; exporting texture "$textureName" axis $axis as RepeatWrapping.'
      );
    }
    
    return 0;
  }

  void warnOnce(String key, String message) {
    if (warningKeys.contains(key)) return;
    warningKeys.add(key);
    print('Warning: $message'); // Maps to console.warn in production logs
  }

  List<Texture> collectTextures() {
    return List<Texture>.from(textures);
  }

  Future<Map<String, Uint8List>> createFiles(
    String fbxFileName, 
    dynamic fbxData, 
    List<Texture> textures
  ) async {
    final Map<String, Uint8List> files = {};

    if (fbxData is ByteBuffer) {
      files[fbxFileName] = fbxData.asUint8List();
    } else if (fbxData is Uint8List) {
      files[fbxFileName] = fbxData;
    } else if (fbxData is String) {
      files[fbxFileName] = Uint8List.fromList(utf8.encode(fbxData));
    } else {
      throw ArgumentError('FBX data must be a String, ByteBuffer, or Uint8List');
    }

    // Process and add texture files concurrently
    final texturePromises = textures.map((texture) async {
      final pngData = await convertTextureToPNG(texture);
      if (pngData != null) {
        final String nameStr = texture.name;
        files['$nameStr.png'] = pngData;
      }
    });

    await Future.wait(texturePromises);
    return files;
  }

  Future<Uint8List?> convertTextureToPNG(Texture texture) async {
    // Prefer rasterizing image-backed textures through your ImageExport decoder utility
    if (texture.image != null) {
      try {
        final imageElement = texture.image;
        final bool flipY = texture.flipY; // Maintain default Three.js texture coordinate flip behavior
        const int maxTextureSize = 2048; // Standard fallback size boundary

        // Execute your custom image processing utility directly
        final pngData = await ImageExport.decodeImageFromList(
          imageElement, 
          flipY, 
          maxTextureSize
        );
        
        if (pngData != null) {
          return pngData;
        }
      } catch (error) {
        warnOnce(
          'texture-convert-fail', 
          'Failed to convert texture to PNG via ImageExport: $error'
        );
      }
    }

    // Fall back to collecting uncompressed/raw pixel arrays instantly if no image element exists
    final textureData = getImmediateTextureData(texture);
    if (textureData != null) {
      return textureData;
    }

    return null;
  }

	Texture prepareTextureForExport(Texture texture) {
		return texture;
	}

  FBXCombinedTextures createCombinedTexture(Material material, String materialName) {
    // Temporarily disable combined texture creation to avoid performance issues
    return FBXCombinedTextures(br: null, meo: null);
  }

  Texture createBRTexture(Material material, String materialName) {
    final Texture? baseColorTexture = material.map;
    final Texture? roughnessTexture = material.roughnessMap;

    // Determine texture size - use the largest available texture
    final size = getMaxTextureSize([baseColorTexture, roughnessTexture]);
    final int width = size.width.toInt();
    final int height = size.height.toInt();

    // Create RGBA data array
    final Uint8List data = Uint8List(width * height * 4);

    // Fill with base color (RGB) and roughness (A)
    for (int i = 0; i < width * height; i++) {
      final int pixelIndex = i * 4;

      // Base color (RGB)
      int r = 255, g = 255, b = 255; // Default white
      if (baseColorTexture != null) {
        final baseColorData = getTextureData(baseColorTexture, width, height);
        r = (pixelIndex < baseColorData.length) ? baseColorData[pixelIndex] : 255;
        g = (pixelIndex + 1 < baseColorData.length) ? baseColorData[pixelIndex + 1] : 255;
        b = (pixelIndex + 2 < baseColorData.length) ? baseColorData[pixelIndex + 2] : 255;
      }

      // Roughness (A)
      int a = 128; // Default 0.5 roughness
      if (roughnessTexture != null) {
        final roughnessData = getTextureData(roughnessTexture, width, height);
        a = (pixelIndex < roughnessData.length) ? roughnessData[pixelIndex] : 128; // Use R channel for roughness
      }

      data[pixelIndex] = r;
      data[pixelIndex + 1] = g;
      data[pixelIndex + 2] = b;
      data[pixelIndex + 3] = a;
    }

    // Creating DataTexture matching package specifications
    final texture = DataTexture(data, width, height, RGBAFormat);
    texture.name = '${materialName}_BR';
    return texture;
  }

  Texture createMEOTexture(Material material, String materialName) {
    final Texture? metalnessTexture = material.metalnessMap;
    final Texture? emissiveTexture = material.emissiveMap;
    final Texture? aoTexture = material.aoMap;

    // Determine texture size - use the largest available texture
    final size = getMaxTextureSize([metalnessTexture, emissiveTexture, aoTexture]);
    final int width = size.width.toInt();
    final int height = size.height.toInt();

    // Create RGBA data array
    final Uint8List data = Uint8List(width * height * 4);

    // Fill with metalness (R), emissive (G), AO (B), and default A
    for (int i = 0; i < width * height; i++) {
      final int pixelIndex = i * 4;

      // Metalness (R)
      int r = 0; // Default 0 metalness
      if (metalnessTexture != null) {
        final metalnessData = getTextureData(metalnessTexture, width, height);
        r = (pixelIndex < metalnessData.length) ? metalnessData[pixelIndex] : 0;
      }

      // Emissive (G) - use luminance or R channel
      int g = 0; // Default 0 emissive
      if (emissiveTexture != null) {
        final emissiveData = getTextureData(emissiveTexture, width, height);
        
        final emissiveR = (pixelIndex < emissiveData.length) ? emissiveData[pixelIndex] : 0;
        final emissiveG = (pixelIndex + 1 < emissiveData.length) ? emissiveData[pixelIndex + 1] : 0;
        final emissiveB = (pixelIndex + 2 < emissiveData.length) ? emissiveData[pixelIndex + 2] : 0;
        
        // Use luminance approximation: 0.299*R + 0.587*G + 0.114*B
        g = (0.299 * emissiveR + 0.587 * emissiveG + 0.114 * emissiveB).round();
      }

      // AO (B)
      int b = 255; // Default 1.0 AO (no occlusion)
      if (aoTexture != null) {
        final aoData = getTextureData(aoTexture, width, height);
        b = (pixelIndex < aoData.length) ? aoData[pixelIndex] : 255;
      }

      data[pixelIndex] = r;
      data[pixelIndex + 1] = g;
      data[pixelIndex + 2] = b;
      data[pixelIndex + 3] = 255; // Alpha
    }

    final texture = DataTexture(data, width, height, RGBAFormat);
    texture.name = '${materialName}_MEO';
    return texture;
  }
  Uint8List getTextureData(Texture texture, int targetWidth, int targetHeight) {
    // For DataTextures, return the data directly
    if (texture is DataTexture) {
      final dynamic img = texture.image;
      if (img != null && img.data != null) {
        if (img.data is Uint8List) return img.data as Uint8List;
        if (img.data is ByteBuffer) return (img.data as ByteBuffer).asUint8List();
      }
    }
    // Return default unoccluded/grey fallback values filled with 128
    return Uint8List(targetWidth * targetHeight * 4)..fillRange(0, targetWidth * targetHeight * 4, 128);
  }

  FBXTextureTransform getFbxTextureTransform(Texture texture) {
    final dynamic texDyn = texture;
    
    final double offsetX = texDyn.offset?.x?.toDouble() ?? 0.0;
    final double offsetY = texDyn.offset?.y?.toDouble() ?? 0.0;
    final double rotVal = texDyn.rotation?.toDouble() ?? 0.0;
    final double repeatX = texDyn.repeat?.x?.toDouble() ?? 1.0;
    final double repeatY = texDyn.repeat?.y?.toDouble() ?? 1.0;
    final double centerX = texDyn.center?.x?.toDouble() ?? 0.0;
    final double centerY = texDyn.center?.y?.toDouble() ?? 0.0;

    return FBXTextureTransform(
      translation: [offsetX, -offsetY, 0.0],
      rotation: [0.0, 0.0, MathUtils.radToDeg(rotVal)],
      scaling: [repeatX, repeatY, 1.0],
      pivot: [centerX, 1.0 - centerY, 0.0],
    );
  }

  Uint8List? getImmediateTextureData(Texture texture) {
    if (texture is DataTexture) {
      final dynamic img = texture.image;
      if (img != null && img.data != null && img.width != null && img.height != null) {
        final int w = (img.width as num).toInt();
        final int h = (img.height as num).toInt();
        
        Uint8List? rawBytes;
        if (img.data is Uint8List) rawBytes = img.data as Uint8List;
        if (img.data is ByteBuffer) rawBytes = (img.data as ByteBuffer).asUint8List();

        if (rawBytes != null && w > 0 && h > 0) {
          return _encodePngRgba(rawBytes, w, h);
        }
      }
    }

    final dynamic texDyn = texture;
    if (texDyn.image != null && texDyn.image.src is String) {
      final String dataUrl = texDyn.image.src as String;
      const prefix = 'data:image/png;base64,';
      if (dataUrl.startsWith(prefix)) {
        return base64Decode(dataUrl.substring(prefix.length));
      }
    }

    if (texDyn.source != null && texDyn.source.data != null) {
      final dynamic sourceData = texDyn.source.data;
      if (sourceData is Uint8List) {
        return Uint8List.fromList(sourceData);
      }
      if (sourceData is ByteBuffer) {
        return sourceData.asUint8List();
      }
    }

    return null;
  }

  Uint8List? extractTextureData(Texture texture) {
    if (!embedTextures) return null;
    return getImmediateTextureData(texture);
  }

  Vector2 getMaxTextureSize(List<Texture?> textures) {
    double width = 64;
    double height = 64; // Default minimum size

    for (final texture in textures) {
      final ImageElement img = texture?.image;
      width = math.max(width, img.width.toDouble());
      height = math.max(height, img.height.toDouble());
    }

    // Limit maximum texture size to prevent performance issues
    double maxSize = 1024; // Maximum 1024x1024 for combined textures
    if (width > maxSize || height > maxSize) {
      width = math.min(width, maxSize);
      height = math.min(height, maxSize);
    }
    
    return Vector2(width, height);
  }

  void addConnection(int childId, int parentId, String type, [String? property]) {
    connections.add(FBXConnection(
      childId: childId,
      parentId: parentId,
      type: type,
      property: property,
    ));
  }

  int getNextId() {
    return idCounter++;
  }

  dynamic generateFBX(FBXExportTarget target, [bool binary = false]) {
    final fbxTree = buildFBXTree(target);
    if (binary) {
      return generateBinaryFBX(fbxTree);
    } else {
      return generateASCIIFBX(fbxTree);
    }
  }

  String getEncodingType(String fbxType) {
    if (fbxType.isEmpty) return 'I';
    switch (fbxType) {
      case 'int':
      case 'enum':
      case 'Integer':
      case 'KInt':
        return 'I'; // 32-bit integer
      case 'double':
      case 'Number':
      case 'KDouble':
        return 'D'; // 64-bit float
      case 'KTime':
        return 'L'; // 64-bit integer
      case 'ColorRGB':
      case 'Vector':
      case 'Vector3D':
      case 'Vector3':
      case 'Float3':
        return 'D';
      case 'Lcl_Translation':
      case 'Lcl_Rotation':
      case 'Lcl_Scaling':
        return 'D'; // Vector properties should be doubles
      default:
        return 'I'; // default to 32-bit integer
    }
  }

  List ensurePropertyList(dynamic prop) {
    if (prop == null) {
      return [];
    }
    
    if (prop is List) {
      return List<dynamic>.from(prop);
    }
    
    if (prop is Map && prop['propertyList'] is List) {
      return List<dynamic>.from(prop['propertyList'] as List);
    }

    final Map pDyn = prop;
    final String name = pDyn['name'] ?? '';
    final String type = pDyn['type'] ?? '';
    final String label = pDyn['label'] ?? '';
    final String flag = pDyn['flag'] ?? '';

    final List<dynamic> propertyList = [name, type, label, flag];
    final String baseEncodingType = getEncodingType(type);

    // Explicitly typed internal helper to mirror the JavaScript closure structure recursively
    void appendValue(dynamic value) {
      if (value == null) {
        return;
      }
      
      if (value is List) {
        for (final element in value) {
          appendValue(element);
        }
        return;
      }
      
      if (value is num) {
        String encodingType = baseEncodingType;
        // Equivalent to checking JavaScript's Number.isInteger() 
        final bool isInt = value == value.toInt();
        if (encodingType == 'I' && !isInt) {
          encodingType = 'D';
        }
        propertyList.add({
          'value': value.toDouble(), 
          'encodingType': encodingType
        });
        return;
      }
      
      if (value is Map && value['value'] != null && value['encodingType'] != null) {
        propertyList.add({
          'value': value['value'], 
          'encodingType': value['encodingType']
        });
        return;
      }
      
      propertyList.add(value);
    }

    appendValue(pDyn['value']);
    return propertyList;
  }

  Map<String, dynamic> buildObjectNode(String type, Map<String,dynamic> obj) {
    final Map<String, dynamic> node = {
      'id': obj['id'],
      'attrName': obj['attrName'],
      'attrType': obj['attrType']
    };

    if (obj['fbxClass'] != null) {
      node['fbxClass'] = obj['fbxClass'];
    }
    if (obj['Version'] != null) {
      node['Version'] = obj['Version'];
    }
    if (obj['ShadingModel'] != null) {
      final sm = obj['ShadingModel'];
      if (sm is Map && sm['value'] != null) {
        node['ShadingModel'] = sm['value'];
      } else {
        node['ShadingModel'] = sm;
      }
    }
    if (obj['Type'] != null) {
      node['Type'] = obj['Type'];
    }
    if (obj['Culling'] != null) {
      node['Culling'] = obj['Culling'];
    }
    if (obj['UseMipMap'] != null) {
      node['UseMipMap'] = obj['UseMipMap'];
    }

    // Direct properties (not in Properties70)
    if (obj['FileName'] != null) {
      node['FileName'] = obj['FileName'];
    }
    if (obj['RelativeFilename'] != null) {
      node['RelativeFilename'] = obj['RelativeFilename'];
    }
    if (obj['WrapModeU'] != null) {
      node['WrapModeU'] = obj['WrapModeU'];
    }
    if (obj['WrapModeV'] != null) {
      node['WrapModeV'] = obj['WrapModeV'];
    }
    if (obj['Translation'] != null) {
      node['Translation'] = obj['Translation'];
    }
    if (obj['Scaling'] != null) {
      node['Scaling'] = obj['Scaling'];
    }

    // Content field for embedded textures (Video objects)
    if (obj['Content'] != null) {
      node['Content'] = obj['Content'];
    }

    // Properties70 Mapping Configuration
    if (obj['Properties70'] != null && obj['Properties70']['P'] != null) {
      final List<dynamic> pList = obj['Properties70']['P'] as List;
      node['Properties70'] = {
        'P': pList.map((prop) => ensurePropertyList(prop)).toList()
      };
    }

    // Geometry specific adjustments
    if (type == 'Geometry') {
      final List<Map<String, dynamic>> layerEntries = [];

      if (obj['Vertices'] != null) {
        node['Vertices'] = {
          'a': obj['Vertices']['a'],
          'dataType': obj['Vertices']['dataType'] ?? 'd'
        };
      }
      if (obj['PolygonVertexIndex'] != null) {
        node['PolygonVertexIndex'] = {
          'a': obj['PolygonVertexIndex']['a'],
          'dataType': obj['PolygonVertexIndex']['dataType'] ?? 'i'
        };
      }
      if (obj['LayerElementNormal'] != null) {
        final layer = obj['LayerElementNormal'][0];
        final Map<String, dynamic> normalLayer = {
          'id': 0,
          'Version': layer['Version'] ?? 102,
          'Name': layer['Name'] ?? '',
          'MappingInformationType': layer['MappingInformationType'] ?? 'ByPolygonVertex',
          'ReferenceInformationType': layer['ReferenceInformationType'] ?? 'Direct'
        };

        if (layer['Normals'] != null) {
          normalLayer['Normals'] = {
            'a': layer['Normals']['a'], 
            'dataType': layer['Normals']['dataType'] ?? 'd'
          };
        }
        if (layer['NormalsW'] != null) {
          normalLayer['NormalsW'] = {
            'a': layer['NormalsW']['a'], 
            'dataType': layer['NormalsW']['dataType'] ?? 'd'
          };
        }
        if (layer['NormalsIndex'] != null) {
          normalLayer['NormalsIndex'] = {
            'a': layer['NormalsIndex']['a'], 
            'dataType': layer['NormalsIndex']['dataType'] ?? 'i'
          };
        }
        node['LayerElementNormal'] = [normalLayer];
        layerEntries.add({'Type': 'LayerElementNormal', 'TypedIndex': 0});
      }
      if (obj['LayerElementTangent'] != null) {
        final layer = obj['LayerElementTangent'][0];
        node['LayerElementTangent'] = [
          {
            'id': 0,
            'Version': layer['Version'] ?? 101,
            'Name': layer['Name'] ?? 'Tangents',
            'MappingInformationType': layer['MappingInformationType'] ?? 'ByPolygonVertex',
            'ReferenceInformationType': layer['ReferenceInformationType'] ?? 'Direct',
            'Tangents': {
              'a': layer['Tangents']['a'], 
              'dataType': layer['Tangents']['dataType'] ?? 'd'
            }
          }
        ];
        layerEntries.add({'Type': 'LayerElementTangent', 'TypedIndex': 0});
      }
      if (obj['LayerElementColor'] != null) {
        final layer = obj['LayerElementColor'][0];
        node['LayerElementColor'] = [
          {
            'id': 0,
            'Version': layer['Version'] ?? 101,
            'Name': layer['Name'] ?? 'Colors',
            'MappingInformationType': layer['MappingInformationType'] ?? 'ByPolygonVertex',
            'ReferenceInformationType': layer['ReferenceInformationType'] ?? 'Direct',
            'Colors': {
              'a': layer['Colors']['a'], 
              'dataType': layer['Colors']['dataType'] ?? 'd'
            }
          }
        ];
        layerEntries.add({'Type': 'LayerElementColor', 'TypedIndex': 0});
      }
      if (obj['LayerElementUV'] != null) {
        node['LayerElementUV'] = <Map<String, dynamic>>[];
        final Map uvMap = obj['LayerElementUV'] as Map;

        for (final entry in uvMap.entries) {
          final layer = entry.value;
          final int typedIndex = entry.key is int ? entry.key : int.parse(entry.key.toString());
          
          final Map<String, dynamic> uvLayer = {
            'id': typedIndex,
            'Version': layer['Version'] ?? 101,
            'Name': layer['Name'] ?? (typedIndex == 0 ? 'UVMap' : 'uv$typedIndex'),
            'MappingInformationType': layer['MappingInformationType'] ?? 'ByPolygonVertex',
            'ReferenceInformationType': layer['ReferenceInformationType'] ?? 'Direct'
          };

          if (layer['UV'] != null) {
            uvLayer['UV'] = {
              'a': layer['UV']['a'], 
              'dataType': layer['UV']['dataType'] ?? 'd'
            };
          }
          if (layer['UVIndex'] != null) {
            uvLayer['UVIndex'] = {
              'a': layer['UVIndex']['a'], 
              'dataType': layer['UVIndex']['dataType'] ?? 'i'
            };
          }
          (node['LayerElementUV'] as List).add(uvLayer);
          layerEntries.add({'Type': 'LayerElementUV', 'TypedIndex': typedIndex});
        }
      }
      if (obj['LayerElementMaterial'] != null) {
        final layer = obj['LayerElementMaterial'][0];
        node['LayerElementMaterial'] = [
          {
            'id': 0,
            'Version': layer['Version'] ?? 101,
            'Name': layer['Name'] ?? '',
            'MappingInformationType': layer['MappingInformationType'] ?? 'ByPolygon',
            'ReferenceInformationType': layer['ReferenceInformationType'] ?? 'IndexToDirect',
            'Materials': {
              'a': layer['Materials']['a'], 
              'dataType': layer['Materials']['dataType'] ?? 'i'
            }
          }
        ];
        layerEntries.add({'Type': 'LayerElementMaterial', 'TypedIndex': 0});
      }
      if (layerEntries.isNotEmpty) {
        node['Layer'] = [
          {
            'id': 0,
            'Version': 100, 
            'LayerElement': layerEntries
          }
        ];
      }
    }

    return node;
  }

  Map<String, dynamic> buildFBXTree(FBXExportTarget target) {
    final Map<String, dynamic> fbxTree = {};

    // FBXHeaderExtension (structural only)
    fbxTree['FBXHeaderExtension'] = {
      'FBXHeaderVersion': 1004,
      'FBXVersion': version,
      'EncryptionType': 0,
      'CreationTimeStamp': {
        'Version': 1000,
        'Year': 1970,
        'Month': 1,
        'Day': 1,
        'Hour': 10,
        'Minute': 0,
        'Second': 0,
        'Millisecond': 0
      }
    };

    // Top-level metadata expected by many readers
    fbxTree['Creator'] = 'FBXExporter';
    fbxTree['CreationTime'] = FBX_CREATION_TIME;
    fbxTree['FileId'] = {'rawBytes': FBX_FILE_ID};

    // GlobalSettings
    fbxTree['GlobalSettings'] = {
      'Version': 1000,
      'Properties70': {
        'P': globalSettings.map((setting) {
          return ensurePropertyList({
            'name': setting['name'],
            'type': setting['type'],
            'label': setting['type2'] ?? '',
            'flag': '',
            'value': setting['value']
          });
        }).toList()
      }
    };

    // Documents
    fbxTree['Documents'] = {
      'a': 1, // Documents count as array property
      'Count': 1,
      'Document': {
        'id': 1234567890,
        'attrName': 'Scene',
        'fbxClass': 'Document',
        'attrType': 'Scene',
        'Properties70': {
          'P': [
            ensurePropertyList({'name': 'SourceObject', 'type': 'object', 'label': '', 'value': ''}),
            ensurePropertyList({'name': 'ActiveAnimStackName', 'type': 'KString', 'label': '', 'value': 'AnimStack::Take 001'})
          ]
        },
        'RootNode': 0
      }
    };

    // References
    fbxTree['References'] = {'Version': 100};

    // Definitions
    final List<Map<String, dynamic>> objectTypeDefinitions = [];
    for (final entry in objects.entries) {
      final String type = entry.key;
      final Map<int, dynamic> subObjects = entry.value;
      final int count = subObjects.keys.length;
      if (count > 0) {
        objectTypeDefinitions.add({
          'name': type,
          'attrName': type,
          'Count': count,
          'a': count,
        });
      }
    }

    fbxTree['Definitions'] = {
      'a': 4, // Definitions count as array property
      'Version': 100,
      'Count': getDefinitionCount(),
      'ObjectType': objectTypeDefinitions
    };

    // Objects mapping loop
    final Map<String, Map<String, dynamic>> fbxObjects = {};
    for (final entry in objects.entries) {
      final String type = entry.key;
      final Map<int, dynamic> subObjects = entry.value;

      fbxObjects[type] = {};
      for (final subEntry in subObjects.entries) {
        final String idKey = subEntry.key.toString();
        final dynamic obj = subEntry.value;
        fbxObjects[type]![idKey] = buildObjectNode(type, obj);
      }
    }
    fbxTree['Objects'] = fbxObjects;

    // Connections Translation Pipeline
    fbxTree['Connections'] = {
      'connections': connections.map((conn) {
        if (conn.property != null) {
          return [conn.childId, conn.parentId, conn.type, conn.property!];
        } else {
          return [conn.childId, conn.parentId, conn.type];
        }
      }).toList(),
      'C': connections.map((conn) {
        final List<dynamic> pList = [
          conn.type,
          {'value': conn.childId, 'encodingType': 'L'},
          {'value': conn.parentId, 'encodingType': 'L'}
        ];
        if (conn.property != null) {
          pList.add(conn.property!);
        }
        return {'propertyList': pList};
      }).toList()
    };

    // Takes (for animations, placeholder)
    fbxTree['Takes'] = {
      'Current': 'Take 001',
      'Take': {
        'attrName': 'Take 001',
        'FileName': 'Take 001.tak',
        'LocalTime': [ 0, 0 ],
        'ReferenceTime': [0, 0]
      }
    };

    return fbxTree;
  }

  String generateASCIIFBX(Map<String,dynamic> fbxTree) {
    String fbx = '';

    // FBX ASCII header comment
    fbx += '; FBX 7.4.0 project file\n';
    fbx += '; Copyright (C) 1997-2015 Autodesk Inc. and/or its licensors.\n';
    fbx += '; All rights reserved.\n';
    fbx += '; ----------------------------------------------------\n\n';

    // Helper for indentation (tabs per level)
    String indent(int level) => '\t' * level;

    // FBXHeaderExtension
    fbx += 'FBXHeaderExtension: {\n';
    fbx += '${indent(1)}FBXHeaderVersion: 1004\n';
    
    final headerVersion = fbxTree['FBXHeaderExtension']['FBXVersion'];
    final headerVersionValue = (headerVersion is Map && headerVersion['value'] != null)
        ? headerVersion['value']
        : headerVersion;
        
    fbx += '${indent(1)}FBXVersion: $headerVersionValue\n';
    fbx += '${indent(1)}EncryptionType: 0\n';
    fbx += '${indent(1)}CreationTimeStamp: {\n';
    fbx += '${indent(2)}Version: 1000\n';
    fbx += '${indent(2)}Year: 2023\n';
    fbx += '${indent(2)}Month: 10\n';
    fbx += '${indent(2)}Day: 3\n';
    fbx += '${indent(2)}Hour: 12\n';
    fbx += '${indent(2)}Minute: 0\n';
    fbx += '${indent(2)}Second: 0\n';
    fbx += '${indent(2)}Millisecond: 0\n';
    fbx += '${indent(1)}}\n';
    fbx += '${indent(1)}Creator: "FBXExporter"\n';
    fbx += '}\n\n';

    // GlobalSettings
    fbx += 'GlobalSettings: {\n';
    fbx += '${indent(1)}Version: 1000\n';
    fbx += '${indent(1)}Properties70: {\n';
    
    final globalProps = fbxTree['GlobalSettings']?['Properties70']?['P'] as List? ?? [];
    for (final prop in globalProps) {
      // Handle the property list check safely
      final List<dynamic> list = (prop is Map && prop['propertyList'] != null) 
          ? prop['propertyList'] as List 
          : (prop is List ? prop : []);
          
      if (list.length < 4) continue;
      final String name = list[0].toString();
      final String type = list[1].toString();
      final String label = list[2].toString();
      final String flag = list[3].toString();
      
      final values = list.sublist(4);
      final normalizedValues = values
          .map((value) => (value is Map && value['value'] != null) ? value['value'] : value)
          .where((value) => value != null)
          .toList();

      final dynamic valuePayload = normalizedValues.isEmpty 
          ? (prop is Map ? prop['value'] : null) 
          : (normalizedValues.length == 1 ? normalizedValues[0] : normalizedValues);
          
      final valueStr = formatPropertyValue(valuePayload, type);
      fbx += '${indent(2)}P: "$name", "$type", "$label", "$flag", $valueStr\n';
    }
    fbx += '${indent(1)}}\n';
    fbx += '}\n\n';

    // Documents
    fbx += 'Documents: 1 {\n';
    fbx += '${indent(1)}Count: 1\n';
    final doc = fbxTree['Documents']['Document'];
    fbx += '${indent(1)}Document: ${doc['id']}, "${doc['attrName']}", "${doc['attrType']}" {\n';
    fbx += '${indent(2)}Properties70: {\n';
    
    final docProps = doc['Properties70']?['P'] as List? ?? [];
    for (final prop in docProps) {
      final List<dynamic> list = (prop is Map && prop['propertyList'] != null) 
          ? prop['propertyList'] as List 
          : (prop is List ? prop : []);
          
      if (list.length < 4) continue;
      final String name = list[0].toString();
      final String type = list[1].toString();
      final String label = list[2].toString();
      final String flag = list[3].toString();
      
      final values = list.sublist(4);
      final normalizedValues = values
          .map((value) => (value is Map && value['value'] != null) ? value['value'] : value)
          .where((value) => value != null)
          .toList();

      final dynamic valuePayload = normalizedValues.isEmpty 
          ? (prop is Map ? prop['value'] : null) 
          : (normalizedValues.length == 1 ? normalizedValues[0] : normalizedValues);
          
      final valueStr = formatPropertyValue(valuePayload, type);
      fbx += '${indent(3)}P: "$name", "$type", "$label", "$flag", $valueStr\n';
    }
    fbx += '${indent(2)}}\n';
    fbx += '${indent(2)}RootNode: 0\n';
    fbx += '${indent(1)}}\n';
    fbx += '}\n\n';

    // References
    fbx += 'References: {\n';
    fbx += '}\n\n';

    // Definitions
    fbx += 'Definitions: 4 {\n';
    fbx += '${indent(1)}Version: 100\n';
    fbx += '${indent(1)}Count: ${fbxTree['Definitions']['Count']}\n';
    
    final objTypeDefinitions = fbxTree['Definitions']['ObjectType'] as List? ?? [];
    for (final objType in objTypeDefinitions) {
      fbx += '${indent(1)}ObjectType: "${objType['name']}", ${objType['Count']} {\n';
      fbx += '${indent(2)}Count: ${objType['Count']}\n';
      fbx += '${indent(1)}}\n';
    }
    fbx += '}\n\n';

    // Objects
    fbx += 'Objects: {\n';
    final Map treeObjects = fbxTree['Objects'] as Map? ?? {};
    for (final entry in treeObjects.entries) {
      final String type = entry.key.toString();
      final Map subObjects = entry.value as Map? ?? {};
      
      for (final obj in subObjects.values) {
        fbx += writeObjectFromNode(type, obj);
      }
    }
    fbx += '}\n\n';

    // Connections
    fbx += 'Connections: {\n';
    final connectionsList = fbxTree['Connections']['connections'] as List? ?? [];
    for (final conn in connectionsList) {
      final List connList = conn as List;
      if (connList.length == 4) {
        fbx += '${this.indent(1)}C: "${connList[2]}",${connList[0]},${connList[1]},"${connList[3]}"\n';
      } else {
        fbx += '${this.indent(1)}C: "${connList[2]}",${connList[0]},${connList[1]}\n';
      }
    }
    fbx += '}\n\n';

    // Takes (for animations, placeholder)
    fbx += 'Takes: {\n';
    fbx += '${indent(1)}Current: "Take 001"\n';
    final take = fbxTree['Takes']['Take'];
    fbx += '${indent(1)}Take: "${take['attrName']}" {\n';
    fbx += '${indent(2)}FileName: "${take['FileName']}"\n';
    fbx += '${indent(2)}LocalTime: ${take['LocalTime'][0]},${take['LocalTime'][1]}\n';
    fbx += '${indent(2)}ReferenceTime: ${take['ReferenceTime'][0]},${take['ReferenceTime'][1]}\n';
    fbx += '${indent(1)}}\n';
    fbx += '}\n';

    return fbx;
  }

  String writeGeometryLayers(dynamic obj) {
    String str = '';

    if (obj['LayerElementNormal'] != null) {
      final List normalList = obj['LayerElementNormal'] as List;
      if (normalList.isNotEmpty) {
        final layer = normalList[0];
        final List normalsA = layer['Normals']?['a'] as List? ?? [];
        final List? normalsIndexA = layer['NormalsIndex']?['a'] as List?;

        str += '${indent(2)}LayerElementNormal: 0 {\n';
        str += '${indent(3)}Version: 102\n';
        str += '${indent(3)}Name: ""\n';
        str += '${indent(3)}MappingInformationType: "ByPolygonVertex"\n';
        str += '${indent(3)}ReferenceInformationType: "${layer['ReferenceInformationType'] ?? 'IndexToDirect'}"\n';
        str += '${indent(3)}Normals: *${normalsA.length} {\n';
        str += '${indent(4)}a: ${normalsA.join(',')}\n';
        str += '${indent(3)}}\n';
        
        if (normalsIndexA != null) {
          str += '${indent(3)}NormalsIndex: *${normalsIndexA.length} {\n';
          str += '${indent(4)}a: ${normalsIndexA.join(',')}\n';
          str += '${indent(3)}}\n';
        }
        str += '${indent(2)}}\n';
      }
    }

    if (obj['LayerElementTangent'] != null) {
      final List tangentList = obj['LayerElementTangent'] as List;
      if (tangentList.isNotEmpty) {
        final List tangentsA = tangentList[0]['Tangents']?['a'] as List? ?? [];
        str += '${indent(2)}LayerElementTangent: 0 {\n';
        str += '${indent(3)}Version: 101\n';
        str += '${indent(3)}Name: "Tangents"\n';
        str += '${indent(3)}MappingInformationType: "ByPolygonVertex"\n';
        str += '${indent(3)}ReferenceInformationType: "Direct"\n';
        str += '${indent(3)}Tangents: *${tangentsA.length} {\n';
        str += '${indent(4)}a: ${tangentsA.join(',')}\n';
        str += '${indent(3)}}\n';
        str += '${indent(2)}}\n';
      }
    }

    if (obj['LayerElementColor'] != null) {
      final List colorList = obj['LayerElementColor'] as List;
      if (colorList.isNotEmpty) {
        final List colorsA = colorList[0]['Colors']?['a'] as List? ?? [];
        str += '${indent(2)}LayerElementColor: 0 {\n';
        str += '${indent(3)}Version: 101\n';
        str += '${indent(3)}Name: "Colors"\n';
        str += '${indent(3)}MappingInformationType: "ByPolygonVertex"\n';
        str += '${indent(3)}ReferenceInformationType: "Direct"\n';
        str += '${indent(3)}Colors: *${colorsA.length} {\n';
        str += '${indent(4)}a: ${colorsA.join(',')}\n';
        str += '${indent(3)}}\n';
        str += '${indent(2)}}\n';
      }
    }

    if (obj['LayerElementUV'] != null) {
      final dynamic uvObj = obj['LayerElementUV'];
      if (uvObj is Map) {
        for (final entry in uvObj.entries) {
          final String key = entry.key.toString();
          final dynamic layer = entry.value;
          final int? keyNum = int.tryParse(key);
          
          final List uvA = layer['UV']?['a'] as List? ?? [];
          final List? uvIndexA = layer['UVIndex']?['a'] as List?;

          str += '${indent(2)}LayerElementUV: $key {\n';
          str += '${indent(3)}Version: ${layer['Version'] ?? 101}\n';
          str += '${indent(3)}Name: "${layer['Name'] ?? (keyNum == 0 ? 'UVMap' : 'uv$key')}"\n';
          str += '${indent(3)}MappingInformationType: "${layer['MappingInformationType'] ?? 'ByPolygonVertex'}"\n';
          str += '${indent(3)}ReferenceInformationType: "${layer['ReferenceInformationType'] ?? 'Direct'}"\n';
          
          if (layer['UV'] != null) {
            str += '${indent(3)}UV: *${uvA.length} {\n';
            str += '${indent(4)}a: ${uvA.join(',')}\n';
            str += '${indent(3)}}\n';
          }
          if (uvIndexA != null) {
            str += '${indent(3)}UVIndex: *${uvIndexA.length} {\n';
            str += '${indent(4)}a: ${uvIndexA.join(',')}\n';
            str += '${indent(3)}}\n';
          }
          str += '${indent(2)}}\n';
        }
      } else if (uvObj is List) {
        for (int i = 0; i < uvObj.length; i++) {
          final dynamic layer = uvObj[i];
          final List uvA = layer['UV']?['a'] as List? ?? [];
          final List? uvIndexA = layer['UVIndex']?['a'] as List?;

          str += '${indent(2)}LayerElementUV: $i {\n';
          str += '${indent(3)}Version: ${layer['Version'] ?? 101}\n';
          str += '${indent(3)}Name: "${layer['Name'] ?? (i == 0 ? 'UVMap' : 'uv$i')}"\n';
          str += '${indent(3)}MappingInformationType: "${layer['MappingInformationType'] ?? 'ByPolygonVertex'}"\n';
          str += '${indent(3)}ReferenceInformationType: "${layer['ReferenceInformationType'] ?? 'Direct'}"\n';
          
          if (layer['UV'] != null) {
            str += '${indent(3)}UV: *${uvA.length} {\n';
            str += '${indent(4)}a: ${uvA.join(',')}\n';
            str += '${indent(3)}}\n';
          }
          if (uvIndexA != null) {
            str += '${indent(3)}UVIndex: *${uvIndexA.length} {\n';
            str += '${indent(4)}a: ${uvIndexA.join(',')}\n';
            str += '${indent(3)}}\n';
          }
          str += '${indent(2)}}\n';
        }
      }
    }

    if (obj['LayerElementMaterial'] != null) {
      final List matList = obj['LayerElementMaterial'] as List;
      if (matList.isNotEmpty) {
        final layer = matList[0];
        final List? materialsA = layer['Materials']?['a'] as List?;

        str += '${indent(2)}LayerElementMaterial: 0 {\n';
        str += '${indent(3)}Version: ${layer['Version'] ?? 101}\n';
        str += '${indent(3)}Name: "${layer['Name'] ?? ''}"\n';
        str += '${indent(3)}MappingInformationType: "${layer['MappingInformationType'] ?? 'ByPolygon'}"\n';
        str += '${indent(3)}ReferenceInformationType: "${layer['ReferenceInformationType'] ?? 'IndexToDirect'}"\n';
        
        if (materialsA != null) {
          str += '${indent(3)}Materials: *${materialsA.length} {\n';
          str += '${indent(4)}a: ${materialsA.join(',')}\n';
          str += '${indent(3)}}\n';
        }
        str += '${indent(2)}}\n';
      }
    }

    if (obj['Layer'] != null) {
      final List layerList = obj['Layer'] as List;
      if (layerList.isNotEmpty) {
        final layer = layerList[0];
        final List layerElements = layer['LayerElement'] as List? ?? [];

        str += '${indent(2)}Layer: 0 {\n';
        str += '${indent(3)}Version: ${layer['Version'] ?? 100}\n';
        
        for (final layerElement in layerElements) {
          str += '${indent(3)}LayerElement: {\n';
          str += '${indent(4)}Type: "${layerElement['Type']}"\n';
          str += '${indent(4)}TypedIndex: ${layerElement['TypedIndex']}\n';
          str += '${indent(3)}}\n';
        }
        str += '${indent(2)}}\n';
      }
    }

    return str;
  }

  String formatPropertyValue(dynamic value, [String? type]) {
    if (value == null) {
      return '';
    }

    if (value is List) {
      return value.map((entry) => formatPropertyValue(entry, type)).join(',');
    }

    if (value is Map && value['value'] != null) {
      return formatPropertyValue(value['value'], type);
    }

    if (type == 'KString' || value is String) {
      return '"$value"';
    }

    return value.toString();
  }

  String writeObjectFromNode(String type, dynamic obj) {
    final name = obj['attrName'];
    final typeAttr = obj['attrType'];
    String str = '${indent(1)}$type: ${obj['id']}, "$name", "$typeAttr" {\n';

    if (obj['Version'] != null) {
      str += '${indent(2)}Version: ${obj['Version']}\n';
    }

    if (obj['ShadingModel'] != null) {
      final sm = obj['ShadingModel'];
      final shadingModelValue = (sm is Map && sm['propertyList'] is List) 
          ? (sm['propertyList'] as List)[0] 
          : sm;
      str += '${indent(2)}ShadingModel: "$shadingModelValue"\n';
    }

    if (obj['Type'] != null) {
      str += '${indent(2)}Type: "${obj['Type']}"\n';
    }

    if (obj['Culling'] != null) {
      str += '${indent(2)}Culling: "${obj['Culling']}"\n';
    }

    if (obj['UseMipMap'] != null) {
      str += '${indent(2)}UseMipMap: ${obj['UseMipMap']}\n';
    }

    // Direct properties (not in Properties70)
    if (obj['FileName'] != null) {
      str += '${indent(2)}FileName: "${obj['FileName']}"\n';
    }

    if (obj['RelativeFilename'] != null) {
      str += '${indent(2)}RelativeFilename: "${obj['RelativeFilename']}"\n';
    }

    if (obj['WrapModeU'] != null) {
      str += '${indent(2)}WrapModeU: ${obj['WrapModeU']}\n';
    }

    if (obj['WrapModeV'] != null) {
      str += '${indent(2)}WrapModeV: ${obj['WrapModeV']}\n';
    }

    if (obj['Translation'] != null) {
      final t = obj['Translation'];
      final List values = (t is Map && t['propertyList'] is List)
          ? (t['propertyList'] as List).map((entry) => entry['value'] ?? entry).toList()
          : (t is List ? t : []);
      str += '${indent(2)}Translation: ${values.join(',')}\n';
    }

    if (obj['Scaling'] != null) {
      final s = obj['Scaling'];
      final List values = (s is Map && s['propertyList'] is List)
          ? (s['propertyList'] as List).map((entry) => entry['value'] ?? entry).toList()
          : (s is List ? s : []);
      str += '${indent(2)}Scaling: ${values.join(',')}\n';
    }

    // Content field for embedded textures (Video objects)
    if (obj['Content'] != null) {
      final contentData = obj['Content'];
      if (contentData is Uint8List) {
        final base64Data = base64Encode(contentData);
        str += '${indent(2)}Content: "$base64Data"\n';
      }
    }

    // Properties70 Formatting Logic
    if (obj['Properties70'] != null && obj['Properties70']['P'] != null) {
      str += '${indent(2)}Properties70: {\n';
      final List pList = obj['Properties70']['P'] as List;
      
      for (final prop in pList) {
        final List list = (prop is Map && prop['propertyList'] != null)
            ? prop['propertyList'] as List
            : (prop is List ? prop : []);

        final String name = (list.isNotEmpty) ? list[0].toString() : (prop is Map ? (prop['name'] ?? '') : '');
        final String typeStr = (list.length > 1) ? list[1].toString() : (prop is Map ? (prop['type'] ?? '') : '');
        final String label = (list.length > 2) ? list[2].toString() : (prop is Map ? (prop['label'] ?? '') : '');
        final String flag = (list.length > 3) ? list[3].toString() : (prop is Map ? (prop['flag'] ?? '') : '');

        final valueSlice = (list.length > 4) ? list.sublist(4) : [];
        final normalizedValues = valueSlice
            .map((value) => (value is Map && value['value'] != null) ? value['value'] : value)
            .where((value) => value != null)
            .toList();

        final dynamic rawValue = normalizedValues.isEmpty
            ? (prop is Map ? prop['value'] : null)
            : (normalizedValues.length == 1 ? normalizedValues[0] : normalizedValues);

        final valueStr = formatPropertyValue(rawValue, typeStr);
        str += '${indent(3)}P: "$name", "$typeStr", "$label", "$flag", $valueStr\n';
      }
      str += '${indent(2)}}\n';
    }

    // Geometry specific handling
    if (type == 'Geometry') {
      if (obj['Vertices'] != null) {
        final List verticesA = obj['Vertices']['a'] as List? ?? [];
        str += '${indent(2)}Vertices: *${verticesA.length} {\n';
        str += '${indent(3)}a: ${verticesA.join(',')}\n';
        str += '${indent(2)}}\n';
      }
      
      if (obj['PolygonVertexIndex'] != null) {
        final List indexA = obj['PolygonVertexIndex']['a'] as List? ?? [];
        str += '${indent(2)}PolygonVertexIndex: *${indexA.length} {\n';
        str += '${indent(3)}a: ${indexA.join(',')}\n';
        str += '${indent(2)}}\n';
      }
      
      str += writeGeometryLayers(obj);
    }

    str += '${indent(1)}}\n';
    return str;
  }

  ByteBuffer generateBinaryFBX(dynamic fbxTree) {
    // Calculate required buffer size based on embedded texture data
    int estimatedSize = 16 * 1024 * 1024; // 16MB base size

    // Add size for embedded textures safely checking the map tree
    final Map? treeObjects = fbxTree['Objects'] as Map?;
    final Map? videos = treeObjects?['Video'] as Map?;
    
    if (videos != null) {
      for (final video in videos.values) {
        if (video is Map && video['Content'] != null && video['Content'] is Uint8List) {
          final Uint8List content = video['Content'] as Uint8List;
          estimatedSize += content.length + 1024; // Add some overhead for FBX structure
        }
      }
    }

    // Ensure minimum size and add some padding
    estimatedSize = math.max(estimatedSize, 1024 * 1024); // Minimum 1MB
    estimatedSize += 1024 * 1024; // Add 1MB padding for safety

    final writer = BinaryWriter(estimatedSize);

    // Write magic header
    const String magic = 'Kaydara FBX Binary  \x00';
    writer.setString(magic);

    // Write reserved bytes (0x1A 0x00)
    writer.setUint8(0x1A);
    writer.setUint8(0x00);

    // Write version (only once at header)
    writer.setUint32(version);

    // Write top-level nodes
    final List<MapEntry<String, dynamic>> topEntries = 
        (fbxTree as Map<String, dynamic>).entries.toList();
        
    for (int i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      writeBinaryNode(writer, entry.key, entry.value, version, 0);
    }

    // Write null terminator node
    writeBinaryNode(writer, '', null, version);

    // Write footer
    writer.setBytes(FBX_FOOTER_ID);
    writer.setUint32(0);

    final int offset = writer.getOffset();
    int padding = (((offset + 15) & ~15).toUnsigned(32) - offset).toInt();
    if (padding == 0) {
      padding = 16;
    }

    for (int i = 0; i < padding; i++) {
      writer.setUint8(0);
    }

    writer.setUint32(version);
    
    for (int i = 0; i < 120; i++) {
      writer.setUint8(0);
    }
    
    writer.setBytes(FBX_FINAL_MAGIC);

    return writer.getArrayBuffer();
  }

  void writeBinaryNode(BinaryWriter writer, String name, dynamic node, int version, [int depth = 0]) {
    // Prevent infinite recursion
    if (depth > 100) {
      warnOnce('max-depth-exceeded', 'FBX export: Maximum recursion depth exceeded, skipping node');
      return;
    }

    // Dynamic metadata function binding based on file standard version rules
    final void Function(int) writeMetaValue = version >= 7500 
        ? (int value) => writer.setUint64(value) 
        : (int value) => writer.setUint32(value);

    if (node == null) {
      writeMetaValue(0);
      writeMetaValue(0);
      writeMetaValue(0);
      writer.setUint8(0);
      return;
    }

    // Capture placeholder position for endOffset
    final int endOffsetPos = writer.getOffset();
    writeMetaValue(0); 

    // Collect properties and subnodes
    List properties = collectNodeProperties(node, name);
    final List<MapEntry<String, dynamic>> subNodes = collectNodeSubNodes(node);

    // Hack: FBXHeaderExtension should have 0 properties
    if (name == 'FBXHeaderExtension') {
      properties = [];
    }

    // numProperties
    final int numProperties = properties.length;
    writeMetaValue(numProperties);

    // Placeholder for propertyListLen, fill after writing properties
    final int propertyListLenPos = writer.getOffset();
    writeMetaValue(0);

    // nameLen and name string payload conversion
    final Uint8List nameBytes = BinaryWriter.encodeString(name);
    if (nameBytes.length > 255) {
      throw Exception('FBX node name too long: $name');
    }
    writer.setUint8(nameBytes.length);
    writer.setBytes(nameBytes);

    final int propertyListStart = writer.getOffset();
    // Write properties
    for (final prop in properties) {
      writeBinaryProperty(writer, prop);
    }
    final int propertyListEnd = writer.getOffset();
    final int propertyListLen = propertyListEnd - propertyListStart;

    final int returnOffset = writer.getOffset();
    writer.offset = propertyListLenPos;
    writeMetaValue(propertyListLen);
    writer.offset = returnOffset;

    // Write subnodes
    for (int i = 0; i < subNodes.length; i++) {
      final entry = subNodes[i];
      final String subName = entry.key;
      final dynamic subNode = entry.value;
      writeBinaryNode(writer, subName, subNode, version, depth + 1);
    }

    // Write a null sentinel only if there are child nodes.
    // This marks the end of the child list for this node as per FBX spec.
    if (subNodes.isNotEmpty) {
      writeBinaryNode(writer, '', null, version, depth + 1);
    }

    // Go back and write endOffset
    final int endOffset = writer.getOffset();
    final int originalOffset = writer.getOffset();
    writer.offset = endOffsetPos;
    writeMetaValue(endOffset);
    writer.offset = originalOffset;

    // Ensure FBXHeaderExtension has zero properties in metadata (SDK expects this)
    if (name == 'FBXHeaderExtension') {
      final int save = writer.getOffset();
      // Overwrite numProps and propertyListLen with zeros
      writer.offset = endOffsetPos + (version >= 7500 ? 8 : 4);
      writeMetaValue(0);
      writer.offset = propertyListLenPos;
      writeMetaValue(0);
      writer.offset = save;
    }
  }

  List collectNodeProperties(dynamic node, [String? nodeName]) {
    final List properties = [];

    // Primitives represent a single property value
    if (node is num || node is String || node is bool) {
      return [node];
    }

    if (node is List) {
      // For connection arrays and other array-based nodes, treat the array elements as properties
      return List<dynamic>.from(node);
    }

    if (node is Map) {
      // Special handling for P nodes (Properties70 properties)
      if (node['propertyList'] != null) {
        return node['propertyList'] as List;
      }

      // Special handling for FBXHeaderExtension - it has no direct properties in binary format
      if (node.containsKey('FBXHeaderVersion') && node.containsKey('FBXVersion') && node.containsKey('EncryptionType')) {
        return [];
      }

      // Handle rawBytes containers (e.g., FileId)
      if (node['rawBytes'] != null) {
        properties.add({'rawBytes': node['rawBytes']});
        return properties;
      }

      // Handle different node types
      if (node['id'] != null) {
        // Layer and layer element indices are 32-bit integers
        if (nodeName == 'Layer' || 
            nodeName == 'LayerElementNormal' || 
            nodeName == 'LayerElementUV' || 
            nodeName == 'LayerElementTangent' || 
            nodeName == 'LayerElementColor') {
          properties.add({'value': node['id'], 'encodingType': 'I'});
        } else {
          properties.add({'value': node['id'], 'encodingType': 'L'});
        }
      }

      if (node['attrName'] != null) {
        final String? className = node['fbxClass'] as String?;
        if (className != null && nodeName != 'Document') {
          properties.add(formatNodeAttrName(node['attrName'].toString(), className));
        } else {
          properties.add(node['attrName']);
        }
      }

      if (node['attrType'] != null) {
        properties.add(node['attrType']);
      }

      // Special handling for FBX header nodes - they have no properties in binary format
      final bool isFBXHeaderNode = node['value'] != null && node['value'] is num;
      if (isFBXHeaderNode) {
        // FBX header nodes like FBXHeaderVersion have their value as a property
        properties.add(node['value']);
      }

      // Handle 'a' convenience property (count) for specific structural nodes
      if (node['a'] != null) {
        final bool allowWithOthers = nodeName == 'Documents' || nodeName == 'Definitions' || nodeName == 'ObjectType';
        if (allowWithOthers) {
          properties.add(node['a']);
        } else {
          // For other nodes: include only if it's the sole key (pure array payload nodes)
          final keys = node.keys.where((key) => key != 'dataType').toList();
          if (keys.length == 1) {
            if (node['dataType'] != null) {
              properties.add({'value': node['a'], 'encodingType': node['dataType']});
            } else {
              properties.add(node['a']);
            }
          }
        }
      }
    }

    return properties;
  }

  List<MapEntry<String, dynamic>> collectNodeSubNodes(dynamic node) {
    final List<MapEntry<String, dynamic>> subNodes = [];
    if (node is List || node is! Map) {
      // Arrays don't have subnodes
      return subNodes;
    }

    final Map mapNode = node;

    // Collect all sub-nodes
    for (final entry in mapNode.entries) {
      final String key = entry.key.toString();
      final dynamic value = entry.value;

      if (key == 'connections') continue;
      if (key == 'id' || key == 'attrName' || key == 'attrType' || key == 'a' || key == 'dataType' || key == 'propertyList' || key == 'name' || key == 'fbxClass') {
        continue;
      }

      if (value is List) {
        final bool treatAsSingleProperty = key == 'LocalTime' || key == 'ReferenceTime' || key == 'Translation' || key == 'Scaling';
        
        if (key == 'P') {
          for (int i = 0; i < value.length; i++) {
            subNodes.add(MapEntry(key, ensurePropertyList(value[i])));
          }
        } else if (treatAsSingleProperty) {
          final String encodingType = (key == 'Translation' || key == 'Scaling') ? 'D' : 'L';
          subNodes.add(MapEntry(key, {
            'propertyList': value.map((v) => {'value': v, 'encodingType': encodingType}).toList()
          }));
        } else {
          for (int i = 0; i < value.length; i++) {
            subNodes.add(MapEntry(key, value[i]));
          }
        }
      } else if (key == 'Content' && value is Uint8List) {
        subNodes.add(MapEntry(key, {
          'propertyList': [
            {'rawBytes': value}
          ]
        }));
      } else if (value is Map) {
        final Map objectValue = value;
        if (objectValue['id'] != null || objectValue['attrType'] != null || objectValue['propertyList'] != null || objectValue['a'] != null || !isDictionaryObject(objectValue)) {
          subNodes.add(MapEntry(key, objectValue));
        } else {
          for (final child in objectValue.values) {
            subNodes.add(MapEntry(key, child));
          }
        }
      } else if (value is String || value is num || value is bool) {
        // Some numeric properties must be encoded as 64-bit (e.g., object references)
        if (value is num && key == 'RootNode') {
          subNodes.add(MapEntry(key, {
            'propertyList': [
              {'value': value, 'encodingType': 'L'}
            ]
          }));
        } else {
          subNodes.add(MapEntry(key, {
            'propertyList': [value]
          }));
        }
      }
    }
    
    return subNodes;
  }

  bool isDictionaryObject(dynamic value) {
    if (value is! Map) return false;
    final keys = value.keys;
    if (keys.isEmpty) return false;
    
    final regex = RegExp(r'^-?\d+$');
    return keys.every((key) => regex.hasMatch(key.toString()));
  }

  void writeBinaryProperty(BinaryWriter writer, dynamic prop) {
    // Handle raw bytes (special case for FBXHeaderExtension)
    if (prop is Map && prop['rawBytes'] != null) {
      final dynamic rawObj = prop['rawBytes'];
      late Uint8List raw;
      
      if (rawObj is Uint8List) {
        raw = rawObj;
      } else if (rawObj is TypedData) {
        raw = rawObj.buffer.asUint8List(rawObj.offsetInBytes, rawObj.lengthInBytes);
      } else if (rawObj is List<int>) {
        raw = Uint8List.fromList(rawObj);
      } else {
        throw ArgumentError('Unsupported rawBytes type layout inside property payload');
      }

      writer.setUint8("R".codeUnitAt(0)); // Raw data type
      writer.setUint32(raw.length);
      writer.setBytes(raw);
      return;
    }

    // Handle explicitly typed values
    if (prop is Map && prop['value'] != null && prop['encodingType'] != null) {
      final dynamic value = prop['value'];
      final String encodingType = prop['encodingType'].toString();

      if (value is List || value is TypedData) {
        List<dynamic> arrayValues;
        if (value is List) {
          arrayValues = value;
        } else {
          // Flatten typed data list views out safely to an iterable list container
          final dynamic td = value;
          arrayValues = List<dynamic>.generate(td.length, (i) => td[i]);
        }

        late int bytesPerElement;
        switch (encodingType) {
          case 'd':
            bytesPerElement = 8;
            break;
          case 'f':
            bytesPerElement = 4;
            break;
          case 'i':
            bytesPerElement = 4;
            break;
          case 'l':
            bytesPerElement = 8;
            break;
          default:
            throw Exception('Unsupported typed FBX array property encoding: $encodingType');
        }

        writer.setUint8(encodingType.codeUnitAt(0));
        writer.setUint32(arrayValues.length);
        writer.setUint32(0); // Encoding (0 = uncompressed)
        writer.setUint32(arrayValues.length * bytesPerElement);

        if (encodingType == 'd') {
          for (final entry in arrayValues) {
            writer.setFloat64((entry as num).toDouble());
          }
        } else if (encodingType == 'f') {
          for (final entry in arrayValues) {
            writer.setFloat32((entry as num).toDouble());
          }
        } else if (encodingType == 'i') {
          for (final entry in arrayValues) {
            writer.setInt32((entry as num).toInt());
          }
        } else if (encodingType == 'l') {
          for (final entry in arrayValues) {
            writer.setUint64((entry as num).toInt());
          }
        }
      } else if (value is num) {
        if (encodingType == 'I') {
          writer.setUint8("I".codeUnitAt(0)); // Integer
          writer.setInt32(value.toInt());
        } else if (encodingType == 'L') {
          writer.setUint8("L".codeUnitAt(0)); // Long
          writer.setUint64(value.toInt());
        } else if (encodingType == 'D') {
          writer.setUint8("D".codeUnitAt(0)); // Double
          writer.setFloat64(value.toDouble());
        }
      } else {
        // Fallback
        writeBinaryProperty(writer, value);
      }
      return;
    }

    // Implicit/Inferred formatting blocks based on runtime data signatures
    if (prop is int) {
      if (prop >= -2147483648 && prop <= 2147483647) {
        writer.setUint8("I".codeUnitAt(0)); // Integer
        writer.setInt32(prop);
      } else {
        writer.setUint8("L".codeUnitAt(0)); // Long
        writer.setUint64(prop);
      }
    } else if (prop is double) {
      writer.setUint8("D".codeUnitAt(0)); // Double
      writer.setFloat64(prop);
    } else if (prop is String) {
      final Uint8List stringBytes = BinaryWriter.encodeString(prop);
      writer.setUint8("S".codeUnitAt(0)); // String
      writer.setUint32(stringBytes.length);
      writer.setBytes(stringBytes);
    } else if (prop is bool) {
      writer.setUint8("C".codeUnitAt(0)); // Boolean
      writer.setUint8(prop ? 1 : 0);
    } else if (prop is List || prop is TypedData) {
      List<dynamic> arrayValues;
      if (prop is List) {
        arrayValues = prop;
      } else {
        final dynamic td = prop;
        arrayValues = List<dynamic>.generate(td.length, (i) => td[i]);
      }

      final bool hasOnlyNumbers = arrayValues.every((value) => value is num && value.isFinite);

      if (hasOnlyNumbers) {
        final bool isIntegerArray = arrayValues.every((value) => value is int);
        late String typeChar;
        late int bytesPerElement;

        if (isIntegerArray) {
          typeChar = 'i';
          bytesPerElement = 4;
        } else {
          // Use double precision for floating-point arrays
          typeChar = 'd';
          bytesPerElement = 8;
        }

        writer.setUint8(typeChar.codeUnitAt(0));
        writer.setUint32(arrayValues.length);
        writer.setUint32(0); // Encoding (0 = uncompressed)
        writer.setUint32(arrayValues.length * bytesPerElement);

        if (isIntegerArray) {
          for (final val in arrayValues) {
            writer.setInt32((val as num).toInt());
          }
        } else {
          for (final val in arrayValues) {
            writer.setFloat64((val as num).toDouble());
          }
        }
      } else {
        throw Exception('Unsupported FBX array property type payload elements found.');
      }
    } else if (prop != null) {
      throw Exception('Unsupported FBX property object structure layout parsing fallback.');
    }
  }

  int getDefinitionCount() {
    int count = 0;
    for (final subMap in objects.values) {
      count += subMap.keys.length;
    }
    return count;
  }

  String formatNodeAttrName(String? name, String nodeType) {
    final baseName = (name != null && name.isNotEmpty) ? name : nodeType;
    return '$baseName\x00\x01$nodeType';
  }

  /// Generate the most minimal FBX file possible
  /// @param binary Whether to generate binary or ASCII format
  /// @returns ByteBuffer for binary, String for ASCII
  dynamic generateMinimalFBX([bool binary = false]) {
    // Create minimal FBX tree structure matching your exact parameters
    final Map<String, dynamic> fbxTree = {
      'FBXHeaderExtension': {
        'FBXHeaderVersion': {
          'propertyList': [1004]
        },
        'FBXVersion': {
          'propertyList': [version]
        },
        'EncryptionType': {
          'propertyList': [0]
        },
        'CreationTimeStamp': {
          'Version': 1000,
          'Year': 2025,
          'Month': 10,
          'Day': 9,
          'Hour': 12,
          'Minute': 0,
          'Second': 0,
          'Millisecond': 0
        }
      },
      'GlobalSettings': {
        'Version': 1000,
        'Properties70': {
          'P': [
            {'property': 'UpAxis', 'type': 'int', 'value': 1},
            {'property': 'UpAxisSign', 'type': 'int', 'value': 1},
            {'property': 'FrontAxis', 'type': 'int', 'value': 2},
            {'property': 'FrontAxisSign', 'type': 'int', 'value': 1},
            {'property': 'CoordAxis', 'type': 'int', 'value': 0},
            {'property': 'CoordAxisSign', 'type': 'int', 'value': 1},
            {'property': 'OriginalUpAxis', 'type': 'int', 'value': 1},
            {'property': 'OriginalUpAxisSign', 'type': 'int', 'value': 1},
            {'property': 'UnitScaleFactor', 'type': 'double', 'value': 1.0},
            {'property': 'OriginalUnitScaleFactor', 'type': 'double', 'value': 1.0}
          ]
        }
      },
      'Documents': {
        'a': 1, // Documents count as array property
        'Count': 1,
        'Document': {
          'id': 1234567890,
          'attrName': 'Scene',
          'fbxClass': 'Document',
          'attrType': 'Scene',
          'Properties70': {
            'P': [
              ensurePropertyList({'name': 'SourceObject', 'type': 'object', 'label': '', 'value': ''}),
              ensurePropertyList({'name': 'ActiveAnimStackName', 'type': 'KString', 'label': '', 'value': ''})
            ]
          },
          'RootNode': 0
        }
      },
      'References': {},
      'Definitions': {
        'Version': 100, 
        'Count': 0, 
        'ObjectType': []
      },
      'Objects': {},
      'Connections': {
        'connections': []
      },
      'Takes': {
        'Current': 'Take 001',
        'Take': {
          'attrName': 'Take 001',
          'FileName': 'Take 001',
          'LocalTime': [0, 46186158000],
          'ReferenceTime': [0, 46186158000]
        }
      }
    };

    if (binary) {
      return generateBinaryFBX(fbxTree);
    } else {
      return generateASCIIFBX(fbxTree);
    }
  }


}

class BinaryWriter {
  late Uint8List _buffer;
  late ByteData _view;
  int offset = 0;
  final Endian endian = Endian.little;

  BinaryWriter([int size = 16 * 1024 * 1024]) { // 16MB default
    _buffer = Uint8List(size);
    _view = ByteData.sublistView(_buffer);
    offset = 0;
  }

  static Uint8List encodeString(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }

  int getOffset() => offset;

  void setUint8(int value) {
    if (offset + 1 > _buffer.length) {
      resize(math.max(_buffer.length * 2, offset + 1024));
    }
    _view.setUint8(offset, value);
    offset += 1;
  }

  void setInt16(int value) {
    if (offset + 2 > _buffer.length) {
      resize(math.max(_buffer.length * 2, offset + 1024));
    }
    _view.setInt16(offset, value, endian);
    offset += 2;
  }

  void setInt32(int value) {
    if (offset + 4 > _buffer.length) {
      resize(math.max(_buffer.length * 2, offset + 1024));
    }
    _view.setInt32(offset, value, endian);
    offset += 4;
  }

  void setUint32(int value) {
    if (offset + 4 > _buffer.length) {
      resize(math.max(_buffer.length * 2, offset + 1024));
    }
    _view.setUint32(offset, value, endian);
    offset += 4;
  }

  void setUint64(int value) {
    if (offset + 8 > _buffer.length) {
      resize(math.max(_buffer.length * 2, offset + 1024));
    }
    // Dart natively supports 64-bit signed/unsigned integer mutations inside ByteData
    _view.setUint64(offset, value, endian);
    offset += 8;
  }

  void setFloat32(double value) {
    if (offset + 4 > _buffer.length) {
      resize(math.max(_buffer.length * 2, offset + 1024));
    }
    _view.setFloat32(offset, value, endian);
    offset += 4;
  }

  void setFloat64(double value) {
    if (offset + 8 > _buffer.length) {
      resize(math.max(_buffer.length * 2, offset + 1024));
    }
    _view.setFloat64(offset, value, endian);
    offset += 8;
  }

  void setBytes(Uint8List bytes) {
    if (offset + bytes.length > _buffer.length) {
      resize(math.max(_buffer.length * 2, offset + bytes.length + 1024));
    }
    _buffer.setRange(offset, offset + bytes.length, bytes);
    offset += bytes.length;
  }

  void setString(String str) {
    final bytes = BinaryWriter.encodeString(str);
    setBytes(bytes);
  }

  void setArrayBuffer(ByteBuffer buffer) {
    final sourceView = buffer.asUint8List();
    setBytes(sourceView);
  }

  void resize(int newSize) {
    if (newSize <= _buffer.length) return;
    
    final newBuffer = Uint8List(newSize);
    newBuffer.setRange(0, _buffer.length, _buffer);
    
    _buffer = newBuffer;
    _view = ByteData.sublistView(_buffer);
  }

  ByteBuffer getArrayBuffer() {
    // Recreates JavaScript's buffer.slice(0, offset) 
    return _buffer.buffer.asByteData(0, offset).buffer;
  }
}
