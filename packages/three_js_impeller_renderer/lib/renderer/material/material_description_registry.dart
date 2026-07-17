import 'package:flutter_gpu/gpu.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_impeller_renderer/renderer/shaders.dart';
import 'package:three_js_math/three_js_math.dart';
import '../geometry/geometry_descriptor.dart';


/// Enumeration of non-uniform material resource attachment types.
enum TextureType {
  map,
  alphaMap,
  aoMap,
  specularMap,
  lightMap,
  bumpMap,
  normalMap,
  displacementMap,
  roughnessMap,
  metalnessMap,
  emissiveMap,
  clearcoatMap,
  clearcoatNormalMap,
  clearcoatRoughnessMap,
  sheenColorMap,
  sheenRoughnessMap,
  transmissionMap,
  thicknessMap,
  iridescenceMap,
  iridescenceThicknessMap,
  matcap,
  gradientMap,
  uniforms,
  boneTexture,
  instanceTexture
}

/// Core blending modes supported by the material system.
enum Blending {
  noBlending,
  normalBlending,
  additiveBlending,
  subtractiveBlending,
  multiplyBlending,
  customBlending,
}

const int materialTextureGroup = 1;
const int environmentTextureGroup = 2;

/// Describes fixed-function pipeline state for a material.
class MaterialRenderState {
  MaterialRenderState({
    this.topology = gpux.PrimitiveType.triangle,
    this.cullMode = gpux.CullMode.backFace,
    this.frontFace = gpux.StencilFace.front,
    this.winding = gpux.WindingOrder.counterClockwise,
    this.depthTest = true,
    this.depthWrite = true,
    gpux.ColorBlendEquation? blendState,
    this.depthCompare = gpux.CompareFunction.less,
    this.depthFormat = gpux.PixelFormat.d24UnormS8Uint,
  }){
    this.blendState = blendState ?? MaterialDescriptorRegistry._noBlending;
  }
  
  final String uuid = MathUtils.generateUUID(); 
  final gpux.PrimitiveType topology;
  final gpux.CullMode cullMode;
  final gpux.StencilFace frontFace;
  final gpux.WindingOrder winding;
  final bool depthTest;
  final bool depthWrite;
  late final gpux.ColorBlendEquation blendState;
  final gpux.CompareFunction depthCompare;
  final gpux.PixelFormat depthFormat;

  MaterialRenderState applyCommonOverrides({
    required bool depthTest,
    required bool depthWrite,
    required bool colorWrite,
    required int side,
    required gpux.ColorBlendEquation? blendState,
    gpux.PrimitiveType topology = gpux.PrimitiveType.triangle,
    gpux.WindingOrder winding = gpux.WindingOrder.counterClockwise
  }) {
    final cullModeOverride = 
      side == FrontSide? gpux.CullMode.backFace:
      side == BackSide? gpux.CullMode.frontFace:
      gpux.CullMode.none;

    return copyWith(
      cullMode: cullModeOverride,
      depthTest: depthTest,
      topology: topology,
      blendState: blendState ?? blendState,
      winding: winding,
      // Transparent alpha blending layers bypass depth-buffer writes to avoid alpha sorting artifacts
      depthWrite: blendState != null ? false : depthWrite,
    );
  }

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialRenderState copyWith({
    gpux.PrimitiveType? topology,
    gpux.CullMode? cullMode,
    gpux.StencilFace? frontFace,
    gpux.WindingOrder? winding,
    bool? depthTest,
    bool? depthWrite,
    gpux.ColorBlendEquation? blendState,
    gpux.CompareFunction? depthCompare,
    gpux.PixelFormat? depthFormat,
  }) {
    return MaterialRenderState(
      topology: topology ?? this.topology,
      cullMode: cullMode ?? this.cullMode,
      frontFace: frontFace ?? this.frontFace,
      winding: winding ?? this.winding,
      blendState: blendState?? this.blendState,
      depthTest: depthTest ?? this.depthTest,
      depthWrite: depthWrite ?? this.depthWrite,
      depthCompare: depthCompare ?? this.depthCompare,
      depthFormat: depthFormat ?? this.depthFormat,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialRenderState &&
          runtimeType == other.runtimeType &&
          topology == other.topology &&
          cullMode == other.cullMode &&
          frontFace == other.frontFace &&
          winding == other.winding &&
          blendState == other.blendState &&
          depthTest == other.depthTest &&
          depthWrite == other.depthWrite &&
          depthCompare == other.depthCompare &&
          depthFormat == other.depthFormat;

  @override
  int get hashCode => Object.hash(
        topology,
        cullMode,
        frontFace,
        winding,
        depthTest,
        blendState,
        depthWrite,
        depthCompare,
        depthFormat,
      );

  @override
  String toString() {
    return 'MaterialRenderState(topology: $topology, cullMode: $cullMode, frontFace: $frontFace, depthTest: $depthTest, depthWrite: $depthWrite, depthCompare: $depthCompare, depthFormat: $depthFormat)';
  }
}

/// Represents a fully resolved material descriptor ready for pipeline compilation.
class ResolvedMaterialDescriptor {
  const ResolvedMaterialDescriptor({
    required this.descriptor,
    required this.renderState,
  });

  final MaterialDescriptor descriptor;
  final MaterialRenderState renderState;

  String get vertexName => descriptor.key+"Vertex";
  String get fragmentName => descriptor.key+"Fragment";

  gpux.Shader get vertex => shaderLibrary[vertexName]!;
  gpux.Shader get fragment => shaderLibrary[fragmentName]!;

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  ResolvedMaterialDescriptor copyWith({
    MaterialDescriptor? descriptor,
    MaterialRenderState? renderState,
  }) {
    return ResolvedMaterialDescriptor(
      descriptor: descriptor ?? this.descriptor,
      renderState: renderState ?? this.renderState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedMaterialDescriptor &&
          runtimeType == other.runtimeType &&
          descriptor == other.descriptor &&
          renderState == other.renderState ;

  @override
  int get hashCode => Object.hash(
        descriptor,
        renderState,
      );

  @override
  String toString() {
    return 'ResolvedMaterialDescriptor(descriptor: $descriptor, renderState: $renderState)';
  }
}

/// Fully describes how a material should be rendered within the pipeline.
class MaterialDescriptor {
  MaterialDescriptor({
    required this.key,
    this.bindings = const [],
    MaterialRenderState? renderState,
    Map<String,String>? defines,
    List<GeometryAttribute>? requiredAttributes,
  }){
    this.renderState = renderState ?? MaterialRenderState();
    this.defines = defines ?? {};
    this.requiredAttributes = requiredAttributes ?? [];
  }

  final String key;
  final List<TextureType> bindings;
  late final MaterialRenderState renderState;
  late final Map<String, String> defines;
  late final List<GeometryAttribute> requiredAttributes;


  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialDescriptor copyWith({
    String? key,
    MaterialUniformBlock? uniformBlock,
    List<TextureType>? bindings,
    MaterialRenderState? renderState,
    Map<String, String>? defines,
    List<GeometryAttribute>? requiredAttributes,
  }) {
    return MaterialDescriptor(
      key: key ?? this.key,
      bindings: bindings ?? this.bindings,
      renderState: renderState ?? this.renderState,
      defines: defines ?? this.defines,
      requiredAttributes: requiredAttributes ?? this.requiredAttributes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialDescriptor &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          // Explicit deep-content array checks
          Object.hashAll(bindings) == Object.hashAll(other.bindings) &&
          renderState == other.renderState &&
          // Explicit deep map checks (key/value entry pairs hashing)
          Object.hashAll(defines.entries) == Object.hashAll(other.defines.entries) &&
          // Explicit deep set checks
          Object.hashAll(requiredAttributes) == Object.hashAll(other.requiredAttributes);

  @override
  int get hashCode => Object.hash(
        key,
        Object.hashAll(bindings),
        renderState,
        Object.hashAll(defines.entries),
        Object.hashAll(requiredAttributes),
      );

  @override
  String toString() {
    return 'MaterialDescriptor(key: $key, bindings: $bindings, renderState: $renderState, defines: $defines, requiredAttributes: $requiredAttributes)';
  }
}

/// Describes the layout of a uniform buffer used by a material.
class MaterialUniformBlock {
  const MaterialUniformBlock({
    required this.name,
    required this.group,
    required this.binding,
    required this.sizeBytes,
  });

  final String name;
  final int group;
  final int binding;
  final int sizeBytes;

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialUniformBlock copyWith({
    String? name,
    int? group,
    int? binding,
    int? sizeBytes,
  }) {
    return MaterialUniformBlock(
      name: name ?? this.name,
      group: group ?? this.group,
      binding: binding ?? this.binding,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialUniformBlock &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          group == other.group &&
          binding == other.binding &&
          sizeBytes == other.sizeBytes;

  @override
  int get hashCode => Object.hash(
        name,
        group,
        binding,
        sizeBytes,
        //Object.hashAll(fields),
      );

  @override
  String toString() {
    return 'MaterialUniformBlock(name: $name, group: $group, binding: $binding, sizeBytes: $sizeBytes)';//, fields: $fields)';
  }
}

abstract class MaterialDescriptorRegistry {
  static bool _defaultsRegistered = false;

  static _DescriptorState _state = const _DescriptorState(
    byKey: {},
    byMaterial: {},
  );

  /// Registers a descriptor for the provided [materials]. Optionally replaces existing registrations.
  static void register(
    MaterialDescriptor descriptor,
    List<Type> materials, {
    bool replaceExisting = false,
  }) {
    _ensureDefaultsRegistered();
    _registerInternal(descriptor, materials, replaceExisting);
  }

  /// Retrieves a descriptor by material instance runtime type.
  static MaterialDescriptor? descriptorFor(Material material) {
    _ensureDefaultsRegistered();
    return _state.byMaterial[material.runtimeType];
  }

  /// Retrieves a descriptor by key name identifier.
  static MaterialDescriptor? descriptorForKey(String key) {
    _ensureDefaultsRegistered();
    return _state.byKey[key];
  }

  /// Intercepts material variants and forwards them to specialized resolution systems.
  static ResolvedMaterialDescriptor? resolve(Material material, Object3D mesh) {
    final descriptor = descriptorFor(material);
    if (descriptor == null) return null;
  
    final blendState = _blendStateFor(
      Blending.values[material.blending],
      material.transparent,
      material.opacity,
    );

    var activeTopology = gpux.PrimitiveType.triangle;

    if (
      material is LineDashedMaterial ||
      mesh is LineSegments ||
      material.wireframe == true
    ) {
      activeTopology = gpux.PrimitiveType.line;
    } 
    else if (
      material is LineBasicMaterial
    ) {
      activeTopology = gpux.PrimitiveType.lineStrip;
    } 
    else if (
      mesh is Points ||
      material is PointsMaterial
    ) {
      activeTopology = gpux.PrimitiveType.point;
    }

    final state = descriptor.renderState.applyCommonOverrides(
      depthTest: material.depthTest,
      depthWrite: material.depthWrite,
      colorWrite: material.colorWrite,
      side: material.side, // Assuming material.side already handles internal common Side conversions
      blendState: blendState,
      topology: activeTopology,
      winding: gpux.WindingOrder.counterClockwise
    );

    return ResolvedMaterialDescriptor(
      descriptor: descriptor,
      renderState: state,
    );
  }

  static void _registerInternal(
    MaterialDescriptor descriptor,
    List<Type> materials,
    bool replaceExisting,
  ) {
    if (!replaceExisting) {
      if (_state.byKey.containsKey(descriptor.key)) {
        throw StateError("Material descriptor with key '${descriptor.key}' already registered");
      }
      for (final type in materials) {
        if (_state.byMaterial.containsKey(type)) {
          throw StateError('Descriptor already registered for material target type: $type');
        }
      }
    }

    // Shallow duplicate maps to maintain mutations immutably
    final updatedByKey = Map<String, MaterialDescriptor>.from(_state.byKey);
    updatedByKey[descriptor.key] = descriptor;

    final updatedByMaterial = Map<Type, MaterialDescriptor>.from(_state.byMaterial);
    for (final type in materials) {
      updatedByMaterial[type] = descriptor;
    }

    _state = _DescriptorState(byKey: updatedByKey, byMaterial: updatedByMaterial);
  }

  static void _ensureDefaultsRegistered() {
    if (_defaultsRegistered) return;
    _defaultsRegistered = true;
    _registerDefaultsLocked();
  }

  static void _registerDefaultsLocked() {
    final basicDescriptor = MaterialDescriptor(
      key: 'Basic',
      bindings: [TextureType.map,TextureType.alphaMap,TextureType.aoMap,TextureType.boneTexture,TextureType.instanceTexture],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal,
        GeometryAttribute.uv0,
        GeometryAttribute.color,
        GeometryAttribute.skinIndex,
        GeometryAttribute.skinWeight
      ],
    );

    _registerInternal(
      basicDescriptor,
      [MeshBasicMaterial],
      true,
    );

    final normalDescriptor = MaterialDescriptor(
      key: 'Normal',
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal,
      ],
    );
    _registerInternal(normalDescriptor,[MeshNormalMaterial],true);

    final toonDescriptor = MaterialDescriptor(
      key: 'Toon',
      bindings: [TextureType.map,TextureType.alphaMap,TextureType.gradientMap,TextureType.normalMap,TextureType.bumpMap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal,
        GeometryAttribute.uv0,
        GeometryAttribute.color,
      ],
    );
    _registerInternal(toonDescriptor, [MeshToonMaterial], true);

    final phongDescriptor = MaterialDescriptor(
      key: 'Phong',
      bindings: [TextureType.map,TextureType.alphaMap,TextureType.displacementMap,TextureType.normalMap,TextureType.bumpMap,TextureType.specularMap,TextureType.aoMap,TextureType.lightMap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal,
        GeometryAttribute.uv0,
        GeometryAttribute.color,
      ],
    );

    _registerInternal(phongDescriptor,[MeshPhongMaterial],true,);

    final lambertDescriptor = MaterialDescriptor(
      key: 'Lambert',
      bindings: [TextureType.map,TextureType.alphaMap,TextureType.specularMap,TextureType.aoMap,TextureType.lightMap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal,
        GeometryAttribute.uv0,
        GeometryAttribute.color,
      ],
    );
    _registerInternal(lambertDescriptor,[MeshLambertMaterial,MeshGouraudMaterial],true,);

    final pointsDescriptor = MaterialDescriptor(
      key: 'Points',
      bindings: [TextureType.map],
      // CRITICAL OVERRIDE: Tells the pipeline compiler to draw points instead of triangles
      renderState: MaterialRenderState(
        topology: gpux.PrimitiveType.point, 
      ),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.color, 
      ],
    );
    _registerInternal(pointsDescriptor, [PointsMaterial], true);

    final shadowDescriptor = MaterialDescriptor(
      key: 'Shadow',
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal, 
        GeometryAttribute.color, // REQUIRED to protect your sequential offset registers
      ],
    );
    _registerInternal(shadowDescriptor, [ShadowMaterial], true);

    final spriteDescriptor = MaterialDescriptor(
      key: 'Sprite',
      bindings: [TextureType.map,TextureType.alphaMap], // Allocates albedo texture binding slots for the sprite asset maps
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.color, // Always required to preserve layout index offsets
      ],
    );
    _registerInternal(spriteDescriptor, [SpriteMaterial], true);

    final lineBasicDescriptor = MaterialDescriptor(
      key: 'LineBasic',
      renderState: MaterialRenderState(
        //topology: gpux.PrimitiveType.line, 
      ),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.color, // REQUIRED to protect your sequential offset registers
      ],
    );
    _registerInternal(lineBasicDescriptor, [LineBasicMaterial], true);

    final lineDashedDescriptor = MaterialDescriptor(
      key: 'LineDashed',
      renderState: MaterialRenderState(
        topology: gpux.PrimitiveType.line, 
      ),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.uv0,
        GeometryAttribute.color, // REQUIRED to secure layout stability
        //GeometryAttribute.lineDistance,
      ],
    );
    _registerInternal(lineDashedDescriptor, [LineDashedMaterial], true);

    final metcapDescriptor = MaterialDescriptor(
      key: 'Matcap',
      bindings: [TextureType.matcap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal,
        GeometryAttribute.uv0,
        GeometryAttribute.color,
      ],
    );

    _registerInternal(metcapDescriptor,[MeshMatcapMaterial],true,);

    final distanceDescriptor = MaterialDescriptor(
      key: 'Distance',
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.color,
      ],
    );
    _registerInternal(distanceDescriptor, [MeshDistanceMaterial], true);

    final depthDescriptor = MaterialDescriptor(
      key: 'Depth',
      renderState: MaterialRenderState(),
      requiredAttributes: [GeometryAttribute.position],
    );

    _registerInternal(depthDescriptor,[MeshDepthMaterial],true);

    final shaderDescriptor = MaterialDescriptor(
      key: 'Shader',
      bindings: [TextureType.uniforms], 
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.color,
      ],
    );
    _registerInternal(shaderDescriptor, [ShaderMaterial], true);

    final standardDescriptor = MaterialDescriptor(
      key: 'Standard',
      bindings: [TextureType.boneTexture,TextureType.map,TextureType.alphaMap,TextureType.displacementMap,TextureType.normalMap,TextureType.bumpMap,TextureType.specularMap,TextureType.aoMap,TextureType.lightMap,TextureType.roughnessMap,TextureType.metalnessMap,TextureType.emissiveMap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal,
        GeometryAttribute.uv0,
        GeometryAttribute.color,
        GeometryAttribute.skinIndex,
        GeometryAttribute.skinWeight
      ],
    );

    _registerInternal(standardDescriptor,[MeshStandardMaterial],true,);

    final physicalDescriptor = MaterialDescriptor(
      key: 'Physical',
      bindings: [
        TextureType.map,
        TextureType.alphaMap,
        TextureType.displacementMap,
        TextureType.normalMap,
        TextureType.bumpMap,
        TextureType.specularMap,
        TextureType.aoMap,
        TextureType.lightMap,
        TextureType.roughnessMap,
        TextureType.metalnessMap,
        TextureType.emissiveMap,

        // --- MESHPHTSICALMATERIAL SAMPLER EXTENSIONS ---
        TextureType.clearcoatMap,
        TextureType.clearcoatNormalMap,
        TextureType.clearcoatRoughnessMap,
        TextureType.sheenColorMap,
        TextureType.sheenRoughnessMap,
        TextureType.transmissionMap,
        TextureType.thicknessMap,
        TextureType.iridescenceMap,
        TextureType.iridescenceThicknessMap,
      ],      
      renderState: MaterialRenderState(),
      requiredAttributes: [
        GeometryAttribute.position,
        GeometryAttribute.normal,
        GeometryAttribute.uv0,
        GeometryAttribute.color,
        GeometryAttribute.skinIndex,
        GeometryAttribute.skinWeight
      ],
    );

    _registerInternal(physicalDescriptor,[MeshPhysicalMaterial],true,);
  }

  /// Evaluates material parameters and selects the optimal alpha blending equation.
  static gpux.ColorBlendEquation _blendStateFor(Blending mode, bool transparent, double opacity) {
    if (mode == Blending.noBlending) {
      return _noBlending;
    }

    final bool needsBlend = transparent || opacity < 1.0 || mode != Blending.normalBlending;
    if (!needsBlend) return _noBlending;

    return switch (mode) {
      Blending.normalBlending || Blending.customBlending => _alphaBlend,
      Blending.additiveBlending => _additiveBlend,
      Blending.subtractiveBlending => _subtractiveBlend,
      Blending.multiplyBlending => _multiplyBlend,
      Blending.noBlending => _noBlending,
    };
  }

  // Global immutable constant blocks mapped precisely to gpux specification bindings
  static  gpux.ColorBlendEquation _alphaBlend = gpux.ColorBlendEquation(
    colorBlendOperation: gpux.BlendOperation.add,
    sourceColorBlendFactor: gpux.BlendFactor.sourceAlpha,
    destinationColorBlendFactor: gpux.BlendFactor.oneMinusSourceAlpha,
    alphaBlendOperation: gpux.BlendOperation.add,
    sourceAlphaBlendFactor: gpux.BlendFactor.one,
    destinationAlphaBlendFactor: gpux.BlendFactor.oneMinusSourceAlpha
  );

  static gpux.ColorBlendEquation _additiveBlend = gpux.ColorBlendEquation(
    sourceColorBlendFactor: gpux.BlendFactor.sourceAlpha,
    destinationColorBlendFactor: gpux.BlendFactor.one,
    colorBlendOperation: gpux.BlendOperation.add,
    sourceAlphaBlendFactor: gpux.BlendFactor.one,
    destinationAlphaBlendFactor: gpux.BlendFactor.one,
    alphaBlendOperation: gpux.BlendOperation.add,
  );

  static gpux.ColorBlendEquation _subtractiveBlend = gpux.ColorBlendEquation(
    sourceColorBlendFactor: gpux.BlendFactor.sourceAlpha,
    destinationColorBlendFactor: gpux.BlendFactor.one,
    colorBlendOperation: gpux.BlendOperation.reverseSubtract,
    sourceAlphaBlendFactor: gpux.BlendFactor.one,
    destinationAlphaBlendFactor: gpux.BlendFactor.one,
    alphaBlendOperation: gpux.BlendOperation.reverseSubtract,
  );

  static gpux.ColorBlendEquation _multiplyBlend = gpux.ColorBlendEquation(
    sourceColorBlendFactor: gpux.BlendFactor.destinationColor,
    destinationColorBlendFactor: gpux.BlendFactor.zero,
    colorBlendOperation: gpux.BlendOperation.add,
    sourceAlphaBlendFactor: gpux.BlendFactor.one,
    destinationAlphaBlendFactor: gpux.BlendFactor.oneMinusSourceAlpha,
    alphaBlendOperation: gpux.BlendOperation.add,
  );

  static gpux.ColorBlendEquation _noBlending = gpux.ColorBlendEquation(
    colorBlendOperation: gpux.BlendOperation.add,
    sourceColorBlendFactor: gpux.BlendFactor.one,
    destinationColorBlendFactor: gpux.BlendFactor.oneMinusSourceAlpha,
    alphaBlendOperation: gpux.BlendOperation.add,
    sourceAlphaBlendFactor: gpux.BlendFactor.one,
    destinationAlphaBlendFactor: gpux.BlendFactor.oneMinusSourceAlpha,
  );
}

class _DescriptorState {
  const _DescriptorState({
    required this.byKey,
    required this.byMaterial,
  });

  final Map<String, MaterialDescriptor> byKey;
  final Map<Type, MaterialDescriptor> byMaterial;
}