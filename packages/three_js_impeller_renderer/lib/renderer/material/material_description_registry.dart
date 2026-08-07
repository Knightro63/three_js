import 'package:flutter_gpu/gpu.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_impeller_renderer/renderer/shaders.dart';
import 'package:three_js_math/three_js_math.dart';


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
  instanceTexture,
  morphTexture,
  envMap
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

  String get vertexName => descriptor.vertexKey;
  String get fragmentName => descriptor.fragmentKey;
  String get bundle => descriptor.bundle;
  String? get package => descriptor.package;

  gpux.Shader? get vertex => shaderLibrary(bundle, package: package)[vertexName];
  gpux.Shader? get fragment => shaderLibrary(bundle, package: package)[fragmentName];

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
    String? vertexKey,
    String? fragmentKey,
    required this.key,
    required this.bundle,
    this.package,
    this.bindings = const [],
    MaterialRenderState? renderState,
    Map<String,String>? defines,
    List<Attribute>? requiredAttributes,
    this.useSceneData = true,
    this.useMaterialData = true
  }){
    this.vertexKey = vertexKey ?? '${key}Vertex';
    this.fragmentKey = fragmentKey ?? '${key}Fragment';
    this.renderState = renderState ?? MaterialRenderState();
    this.defines = defines ?? {};
    this.requiredAttributes = requiredAttributes ?? [];
  }

  late final String vertexKey;
  late final String fragmentKey;
  final String bundle;
  final String? package;
  final String key;
  bool useSceneData = true;
  bool useMaterialData = true;
  final List<TextureType> bindings;
  late final MaterialRenderState renderState;
  late final Map<String, String> defines;
  late final List<Attribute> requiredAttributes;


  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialDescriptor copyWith({
    String? key,
    String? vertexKey,
    String? fragmentKey,
    String? bundle,
    String? package,
    MaterialUniformBlock? uniformBlock,
    List<TextureType>? bindings,
    MaterialRenderState? renderState,
    Map<String, String>? defines,
    List<Attribute>? requiredAttributes,
  }) {
    return MaterialDescriptor(
      key: key ?? this.key,
      bundle: bundle ?? this.bundle,
      package: package ?? this.package,
      vertexKey: vertexKey ?? this.vertexKey,
      fragmentKey: fragmentKey ?? this.fragmentKey,
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
          vertexKey == other.vertexKey &&
          fragmentKey == other.fragmentKey &&
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
        vertexKey,
        fragmentKey,
        Object.hashAll(bindings),
        renderState,
        Object.hashAll(defines.entries),
        Object.hashAll(requiredAttributes),
      );

  @override
  String toString() {
    return 'MaterialDescriptor(vertexKey: $vertexKey, fragmentKey: $fragmentKey, bindings: $bindings, renderState: $renderState, defines: $defines, requiredAttributes: $requiredAttributes)';
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
  );

  /// Registers a descriptor for the provided [materials]. Optionally replaces existing registrations.
  static void register(
    MaterialDescriptor descriptor,
    Material material,{
    bool replaceExisting = false,
  }) {
    _ensureDefaultsRegistered();
    _registerInternal(descriptor, [material.type], replaceExisting);
  }

  /// Retrieves a descriptor by key name identifier.
  static MaterialDescriptor? descriptorForKey(String key) {
    _ensureDefaultsRegistered();
    return _state.byKey[key];
  }

  /// Intercepts material variants and forwards them to specialized resolution systems.
  static ResolvedMaterialDescriptor? resolve(Material material, Object3D mesh) {
    MaterialDescriptor? descriptor = material is ShaderMaterial?descriptorForKey(material.name):descriptorForKey(material.type);
    if (material is ShaderMaterial && descriptor == null && material.uniforms['ShaderParameters']?['bundle'] != null){
      print(material.uniforms['ShaderParameters']['bundle']);
      descriptor = MaterialDescriptor(
        key: material.name,
        bundle: material.uniforms['ShaderParameters']['bundle'],
        renderState: MaterialRenderState(),
        requiredAttributes: material.uniformsGroups.cast()
      );
      _registerInternal(descriptor,[material.name],true,);
    }
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
    List<String> materials,
    bool replaceExisting,
  ) {
    if (!replaceExisting) {
      if (_state.byKey.containsKey(descriptor.key)) {
        throw StateError("Material descriptor with key '${descriptor.key}' already registered");
      }
      for (final type in materials) {
        if (_state.byKey.containsKey(type)) {
          throw StateError('Descriptor already registered for material target type: $type');
        }
      }
    }

    // Shallow duplicate maps to maintain mutations immutably
    final updatedByKey = Map<String, MaterialDescriptor>.from(_state.byKey);
    updatedByKey[descriptor.key] = descriptor;

    for (final type in materials) {
      updatedByKey[type] = descriptor;
    }

    _state = _DescriptorState(byKey: updatedByKey);
  }

  static void _ensureDefaultsRegistered() {
    if (_defaultsRegistered) return;
    _defaultsRegistered = true;
    _registerDefaultsLocked();
  }

  static void _registerDefaultsLocked() {
    final basicDescriptor = MaterialDescriptor(
      key: 'Basic',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.map,TextureType.alphaMap,TextureType.aoMap,TextureType.boneTexture,TextureType.instanceTexture],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.uv,
        Attribute.color,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );
    _registerInternal(basicDescriptor,['MeshBasicMaterial'],true,);

    final normalDescriptor = MaterialDescriptor(
      key: 'Normal',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      useSceneData: false,
      renderState: MaterialRenderState(),
      bindings: [TextureType.displacementMap,TextureType.boneTexture,TextureType.instanceTexture],
      requiredAttributes: [
        Attribute.position,
        Attribute.normal,
        Attribute.uv,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );
    _registerInternal(normalDescriptor,['MeshNormalMaterial'],true);

    final toonDescriptor = MaterialDescriptor(
      key: 'Toon',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.displacementMap,TextureType.boneTexture,TextureType.instanceTexture,TextureType.map,TextureType.alphaMap,TextureType.gradientMap,TextureType.normalMap,TextureType.bumpMap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.normal,
        Attribute.uv,
        Attribute.color,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );
    _registerInternal(toonDescriptor, ['MeshToonMaterial'], true);

    final phongDescriptor = MaterialDescriptor(
      key: 'Phong',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.map,TextureType.alphaMap,TextureType.displacementMap,TextureType.normalMap,TextureType.bumpMap,TextureType.specularMap,TextureType.aoMap,TextureType.lightMap,TextureType.boneTexture,TextureType.instanceTexture,TextureType.morphTexture],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.normal,
        Attribute.uv,
        Attribute.color,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );

    _registerInternal(phongDescriptor,['MeshPhongMaterial'],true,);

    final lambertDescriptor = MaterialDescriptor(
      key: 'Lambert',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.map,TextureType.alphaMap,TextureType.specularMap,TextureType.aoMap,TextureType.lightMap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.normal,
        Attribute.uv,
        Attribute.color,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );
    _registerInternal(lambertDescriptor,['MeshLambertMaterial','MeshGouraudMaterial'],true,);

    final pointsDescriptor = MaterialDescriptor(
      key: 'Points',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.map,TextureType.instanceTexture],
      // CRITICAL OVERRIDE: Tells the pipeline compiler to draw points instead of triangles
      renderState: MaterialRenderState(
        topology: gpux.PrimitiveType.point, 
      ),
      requiredAttributes: [
        Attribute.position,
        Attribute.color, 
        Attribute.instanceId,
      ],
    );
    _registerInternal(pointsDescriptor, ['PointsMaterial'], true);

    final shadowDescriptor = MaterialDescriptor(
      key: 'Shadow',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.boneTexture,TextureType.instanceTexture],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.normal, 
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );
    _registerInternal(shadowDescriptor, ['ShadowMaterial'], true);

    final spriteDescriptor = MaterialDescriptor(
      key: 'Sprite',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.map,TextureType.alphaMap], // Allocates albedo texture binding slots for the sprite asset maps
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.color, // Always required to preserve layout index offsets
      ],
    );
    _registerInternal(spriteDescriptor, ['SpriteMaterial'], true);

    final lineBasicDescriptor = MaterialDescriptor(
      key: 'LineBasic',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.instanceTexture],
      renderState: MaterialRenderState(
        //topology: gpux.PrimitiveType.line, 
      ),
      requiredAttributes: [
        Attribute.position,
        Attribute.color, // REQUIRED to protect your sequential offset registers
        Attribute.instanceId,
      ],
    );
    _registerInternal(lineBasicDescriptor, ['LineBasicMaterial'], true);

    final lineDashedDescriptor = MaterialDescriptor(
      key: 'LineDashed',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.instanceTexture],
      renderState: MaterialRenderState(
        topology: gpux.PrimitiveType.line, 
      ),
      requiredAttributes: [
        Attribute.position,
        Attribute.uv,
        Attribute.color, // REQUIRED to secure layout stability
        Attribute.instanceId,
        Attribute.lineDistances
      ],
    );
    _registerInternal(lineDashedDescriptor, ['LineDashedMaterial'], true);

    final metcapDescriptor = MaterialDescriptor(
      key: 'Matcap',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.matcap,TextureType.boneTexture,TextureType.instanceTexture,TextureType.displacementMap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.normal,
        Attribute.uv,
        Attribute.color,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );

    _registerInternal(metcapDescriptor,['MeshMatcapMaterial'],true,);

    final distanceDescriptor = MaterialDescriptor(
      key: 'Distance',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.boneTexture,TextureType.instanceTexture],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.color,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );
    _registerInternal(distanceDescriptor, ['MeshDistanceMaterial'], true);

    final depthDescriptor = MaterialDescriptor(
      key: 'Depth',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.boneTexture,TextureType.instanceTexture],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );

    _registerInternal(depthDescriptor,['MeshDepthMaterial'],true);

    final standardDescriptor = MaterialDescriptor(
      key: 'Standard',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
      bindings: [TextureType.instanceTexture,TextureType.boneTexture,TextureType.map,TextureType.alphaMap,TextureType.displacementMap,TextureType.normalMap,TextureType.bumpMap,TextureType.specularMap,TextureType.aoMap,TextureType.lightMap,TextureType.roughnessMap,TextureType.metalnessMap,TextureType.emissiveMap],
      renderState: MaterialRenderState(),
      requiredAttributes: [
        Attribute.position,
        Attribute.normal,
        Attribute.uv,
        Attribute.color,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );

    _registerInternal(standardDescriptor,['MeshStandardMaterial'],true,);

    final physicalDescriptor = MaterialDescriptor(
      key: 'Physical',
      package: 'three_js_impeller_renderer',
      bundle: 'ThreeJS',
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
        Attribute.position,
        Attribute.normal,
        Attribute.uv,
        Attribute.color,
        Attribute.skinIndex,
        Attribute.skinWeight,
        Attribute.instanceId
      ],
    );

    _registerInternal(physicalDescriptor,['MeshPhysicalMaterial'],true,);
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
  });

  final Map<String, MaterialDescriptor> byKey;
}