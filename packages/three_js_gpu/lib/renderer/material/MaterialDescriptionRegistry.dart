import 'package:gpux/gpux.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import '../../shader/MaterialShaderLibrary.dart';
import '../geometry/GeometryDescriptor.dart';
import '../webgpu/WebGPUPipeline.dart';


/// Enumeration of non-uniform material resource attachment types.
enum MaterialBindingType {
  texture2d,
  textureCube,
  texture3d,
  sampler,
}

/// Enumeration of structural material asset resource streams.
enum MaterialBindingSource {
  environmentPrefilter,
  environmentBrdf,
  albedoMap,
  normalMap,
  roughnessMap,
  metalnessMap,
  aoMap,
  volumeTexture,
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

enum StandardBlendMode {
  none,
  normal,
  additive,
  subtractive,
  multiply,
  custom,
}

enum MaterialUniformType {
  mat4,
  vec4,
}

const int materialTextureGroup = 1;
const int environmentTextureGroup = 2;

/// Color target configuration including blending.
class ColorTargetDescriptor {
  const ColorTargetDescriptor({
    this.format = GpuTextureFormat.bgra8Unorm,
    this.blendState,
    this.writeMask = ColorWriteMask.all,
  });

  final GpuTextureFormat format;
  final GpuBlendState? blendState;
  final ColorWriteMask writeMask; // Maps to WebGPU / gpux bitwise flag integer mask representation

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  ColorTargetDescriptor copyWith({
    GpuTextureFormat? format,
    GpuBlendState? blendState,
    ColorWriteMask? writeMask,
  }) {
    return ColorTargetDescriptor(
      format: format ?? this.format,
      blendState: blendState ?? this.blendState,
      writeMask: writeMask ?? this.writeMask,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorTargetDescriptor &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          blendState == other.blendState &&
          writeMask == other.writeMask;

  @override
  int get hashCode => Object.hash(format, blendState, writeMask);

  @override
  String toString() {
    return 'ColorTargetDescriptor(format: $format, blendState: $blendState, writeMask: $writeMask)';
  }
}

/// Describes fixed-function pipeline state for a material.
class MaterialRenderState {
  MaterialRenderState({
    this.topology = GpuPrimitiveTopology.triangleList,
    this.cullMode = GpuCullMode.back,
    this.frontFace = GpuFrontFace.ccw,
    this.depthTest = true,
    this.depthWrite = true,
    this.depthCompare = GpuCompareFunction.less,
    this.depthFormat = GpuTextureFormat.depth24Plus,
    ColorTargetDescriptor? colorTarget
  }){
    this.colorTarget = colorTarget ?? ColorTargetDescriptor();
  }

  final GpuPrimitiveTopology topology;
  final GpuCullMode cullMode;
  final GpuFrontFace frontFace;
  final bool depthTest;
  final bool depthWrite;
  final GpuCompareFunction depthCompare;
  final GpuTextureFormat depthFormat;
  late final ColorTargetDescriptor colorTarget;

  MaterialRenderState applyCommonOverrides({
    required bool depthTest,
    required bool depthWrite,
    required bool colorWrite,
    required int side,
    required bool hasBlend,
  }) {
    final cullModeOverride = 
      side == FrontSide? GpuCullMode.back:
      side == BackSide? GpuCullMode.front:
      GpuCullMode.none;

    final writeMask = colorWrite ? ColorWriteMask.all : ColorWriteMask.none;

    return copyWith(
      cullMode: cullModeOverride,
      depthTest: depthTest,
      // Transparent alpha blending layers bypass depth-buffer writes to avoid alpha sorting artifacts
      depthWrite: hasBlend ? false : depthWrite,
      colorTarget: colorTarget.copyWith(writeMask: writeMask),
    );
  }

  /// Appends alpha transparency configurations down into the color target description.
  MaterialRenderState withBlend(GpuBlendState? blendState) {
    return copyWith(
      colorTarget: colorTarget.copyWith(blendState: blendState),
    );
  }

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialRenderState copyWith({
    GpuPrimitiveTopology? topology,
    GpuCullMode? cullMode,
    GpuFrontFace? frontFace,
    bool? depthTest,
    bool? depthWrite,
    GpuCompareFunction? depthCompare,
    GpuTextureFormat? depthFormat,
    ColorTargetDescriptor? colorTarget,
  }) {
    return MaterialRenderState(
      topology: topology ?? this.topology,
      cullMode: cullMode ?? this.cullMode,
      frontFace: frontFace ?? this.frontFace,
      depthTest: depthTest ?? this.depthTest,
      depthWrite: depthWrite ?? this.depthWrite,
      depthCompare: depthCompare ?? this.depthCompare,
      depthFormat: depthFormat ?? this.depthFormat,
      colorTarget: colorTarget ?? this.colorTarget,
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
          depthTest == other.depthTest &&
          depthWrite == other.depthWrite &&
          depthCompare == other.depthCompare &&
          depthFormat == other.depthFormat &&
          colorTarget == other.colorTarget;

  @override
  int get hashCode => Object.hash(
        topology,
        cullMode,
        frontFace,
        depthTest,
        depthWrite,
        depthCompare,
        depthFormat,
        colorTarget,
      );

  @override
  String toString() {
    return 'MaterialRenderState(topology: $topology, cullMode: $cullMode, frontFace: $frontFace, depthTest: $depthTest, depthWrite: $depthWrite, depthCompare: $depthCompare, depthFormat: $depthFormat, colorTarget: $colorTarget)';
  }
}


/// Represents a fully resolved material descriptor ready for pipeline compilation.
class ResolvedMaterialDescriptor {
  const ResolvedMaterialDescriptor({
    required this.descriptor,
    required this.renderState,
    this.shaderOverrides = const {},
  });

  final MaterialDescriptor descriptor;
  final MaterialRenderState renderState;
  final Map<String, String> shaderOverrides;

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  ResolvedMaterialDescriptor copyWith({
    MaterialDescriptor? descriptor,
    MaterialRenderState? renderState,
    Map<String, String>? shaderOverrides,
  }) {
    return ResolvedMaterialDescriptor(
      descriptor: descriptor ?? this.descriptor,
      renderState: renderState ?? this.renderState,
      shaderOverrides: shaderOverrides ?? this.shaderOverrides,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedMaterialDescriptor &&
          runtimeType == other.runtimeType &&
          descriptor == other.descriptor &&
          renderState == other.renderState &&
          // Explicit deep map entries content check
          Object.hashAll(shaderOverrides.entries) == Object.hashAll(other.shaderOverrides.entries);

  @override
  int get hashCode => Object.hash(
        descriptor,
        renderState,
        Object.hashAll(shaderOverrides.entries),
      );

  @override
  String toString() {
    return 'ResolvedMaterialDescriptor(descriptor: $descriptor, renderState: $renderState, shaderOverrides: $shaderOverrides)';
  }
}

/// Describes a field within a material uniform block.
class MaterialUniformField {
  const MaterialUniformField(
    this.name,
    this.type,
  {
    required this.offset,
  });

  final String name;
  final MaterialUniformType type;
  final int offset;

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialUniformField copyWith({
    String? name,
    MaterialUniformType? type,
    int? offset,
  }) {
    return MaterialUniformField(
      name ?? this.name,
      type ?? this.type,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialUniformField &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(name, type, offset);

  @override
  String toString() {
    return 'MaterialUniformField(name: $name, type: $type, offset: $offset)';
  }
}

/// Represents a non-uniform binding required by a material (texture, sampler, etc.).
class MaterialBinding {
  const MaterialBinding({
    required this.name,
    required this.type,
    required this.group,
    required this.binding,
    required this.source,
    this.required = true,
  });

  final String name;
  final MaterialBindingType type;
  final int group;
  final int binding;
  final MaterialBindingSource source;
  final bool required;

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialBinding copyWith({
    String? name,
    MaterialBindingType? type,
    int? group,
    int? binding,
    MaterialBindingSource? source,
    bool? required,
  }) {
    return MaterialBinding(
      name: name ?? this.name,
      type: type ?? this.type,
      group: group ?? this.group,
      binding: binding ?? this.binding,
      source: source ?? this.source,
      required: required ?? this.required,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialBinding &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          group == other.group &&
          binding == other.binding &&
          source == other.source &&
          required == other.required;

  @override
  int get hashCode => Object.hash(
        name,
        type,
        group,
        binding,
        source,
        required,
      );

  @override
  String toString() {
    return 'MaterialBinding(name: $name, type: $type, group: $group, binding: $binding, source: $source, required: $required)';
  }
}

/// Fully describes how a material should be rendered within the pipeline.
class MaterialDescriptor {
  MaterialDescriptor({
    required this.key,
    required this.shader,
    required this.uniformBlock,
    this.bindings = const [],
    MaterialRenderState? renderState,
    Map<String,String>? defines,
    Set<GeometryAttribute>? requiredAttributes,
    Set<GeometryAttribute>? optionalAttributes,
  }){
    this.renderState = renderState ?? MaterialRenderState();
    this.defines = defines ?? {};
    this.requiredAttributes = requiredAttributes ?? {};
    this.optionalAttributes = optionalAttributes ?? {};
  }

  final String key;
  final MaterialShaderDescriptor shader;
  final MaterialUniformBlock uniformBlock;
  final List<MaterialBinding> bindings;
  late final MaterialRenderState renderState;
  late final Map<String, String> defines;
  late final Set<GeometryAttribute> requiredAttributes;
  late final Set<GeometryAttribute> optionalAttributes;

  /// Evaluates whether the descriptor demands a specific binding resource type.
  bool requiresBinding(MaterialBindingSource source) {
    return bindings.any((b) => b.source == source && b.required);
  }

  /// Extracts the set of unique bind group indices assigned to a given resource source type.
  Set<int> bindingGroups(MaterialBindingSource source) {
    final groups = <int>{};
    for (final binding in bindings) {
      if (binding.source == source) {
        groups.add(binding.group);
      }
    }
    return groups;
  }

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialDescriptor copyWith({
    String? key,
    MaterialShaderDescriptor? shader,
    MaterialUniformBlock? uniformBlock,
    List<MaterialBinding>? bindings,
    MaterialRenderState? renderState,
    Map<String, String>? defines,
    Set<GeometryAttribute>? requiredAttributes,
    Set<GeometryAttribute>? optionalAttributes,
  }) {
    return MaterialDescriptor(
      key: key ?? this.key,
      shader: shader ?? this.shader,
      uniformBlock: uniformBlock ?? this.uniformBlock,
      bindings: bindings ?? this.bindings,
      renderState: renderState ?? this.renderState,
      defines: defines ?? this.defines,
      requiredAttributes: requiredAttributes ?? this.requiredAttributes,
      optionalAttributes: optionalAttributes ?? this.optionalAttributes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialDescriptor &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          shader == other.shader &&
          uniformBlock == other.uniformBlock &&
          // Explicit deep-content array checks
          Object.hashAll(bindings) == Object.hashAll(other.bindings) &&
          renderState == other.renderState &&
          // Explicit deep map checks (key/value entry pairs hashing)
          Object.hashAll(defines.entries) == Object.hashAll(other.defines.entries) &&
          // Explicit deep set checks
          Object.hashAll(requiredAttributes) == Object.hashAll(other.requiredAttributes) &&
          Object.hashAll(optionalAttributes) == Object.hashAll(other.optionalAttributes);

  @override
  int get hashCode => Object.hash(
        key,
        shader,
        uniformBlock,
        Object.hashAll(bindings),
        renderState,
        Object.hashAll(defines.entries),
        Object.hashAll(requiredAttributes),
        Object.hashAll(optionalAttributes),
      );

  @override
  String toString() {
    return 'MaterialDescriptor(key: $key, shader: $shader, uniformBlock: $uniformBlock, bindings: $bindings, renderState: $renderState, defines: $defines, requiredAttributes: $requiredAttributes, optionalAttributes: $optionalAttributes)';
  }
}

/// Describes the layout of a uniform buffer used by a material.
class MaterialUniformBlock {
  const MaterialUniformBlock({
    required this.name,
    required this.group,
    required this.binding,
    required this.sizeBytes,
    required this.fields,
  });

  final String name;
  final int group;
  final int binding;
  final int sizeBytes;
  final List<MaterialUniformField> fields;

  /// Shorthand immutable copier mimicking Kotlin's data class copy modifier.
  MaterialUniformBlock copyWith({
    String? name,
    int? group,
    int? binding,
    int? sizeBytes,
    List<MaterialUniformField>? fields,
  }) {
    return MaterialUniformBlock(
      name: name ?? this.name,
      group: group ?? this.group,
      binding: binding ?? this.binding,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      fields: fields ?? this.fields,
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
          sizeBytes == other.sizeBytes &&
          // Optimized collection content equality fallback
          Object.hashAll(fields) == Object.hashAll(other.fields);

  @override
  int get hashCode => Object.hash(
        name,
        group,
        binding,
        sizeBytes,
        Object.hashAll(fields),
      );

  @override
  String toString() {
    return 'MaterialUniformBlock(name: $name, group: $group, binding: $binding, sizeBytes: $sizeBytes, fields: $fields)';
  }
}

abstract class MaterialDescriptorRegistry {
  static bool _defaultsRegistered = false;

  static _DescriptorState _state = const _DescriptorState(
    byKey: {},
    byMaterial: {},
  );

  static const Set<GeometryAttribute> _basicRequiredAttributes = {
    GeometryAttribute.position,
    GeometryAttribute.normal,
    GeometryAttribute.color,
  };

  static const Set<GeometryAttribute> _basicOptionalAttributes = {
    GeometryAttribute.uv0,
  };

  static const Set<GeometryAttribute> _standardRequiredAttributes = {
    GeometryAttribute.position,
    GeometryAttribute.normal,
    GeometryAttribute.color,
  };

  static const Set<GeometryAttribute> _standardOptionalAttributes = {
    GeometryAttribute.uv0,
    GeometryAttribute.uv1,
    GeometryAttribute.tangent,
  };

  static const MaterialUniformBlock _defaultUniformBlock = MaterialUniformBlock(
    name: 'Uniforms',
    group: 0,
    binding: 0,
    sizeBytes: 352,
    fields: [
      MaterialUniformField('projectionMatrix', MaterialUniformType.mat4, offset: 0),
      MaterialUniformField('viewMatrix', MaterialUniformType.mat4, offset: 64),
      MaterialUniformField('modelMatrix', MaterialUniformType.mat4, offset: 128),
      MaterialUniformField('baseColor', MaterialUniformType.vec4, offset: 192),
      MaterialUniformField('pbrParams', MaterialUniformType.vec4, offset: 208),
      MaterialUniformField('cameraPosition', MaterialUniformType.vec4, offset: 224),
      MaterialUniformField('ambientColor', MaterialUniformType.vec4, offset: 240),
      MaterialUniformField('fogColor', MaterialUniformType.vec4, offset: 256),
      MaterialUniformField('fogParams', MaterialUniformType.vec4, offset: 272),
      MaterialUniformField('mainLightDirection', MaterialUniformType.vec4, offset: 288),
      MaterialUniformField('mainLightColor', MaterialUniformType.vec4, offset: 304),
      MaterialUniformField('morphInfluences0', MaterialUniformType.vec4, offset: 320),
      MaterialUniformField('morphInfluences1', MaterialUniformType.vec4, offset: 336),
    ],
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

  /// Returns the default uniform block used by built-in materials.
  static MaterialUniformBlock get sharedUniformBlock {
    _ensureDefaultsRegistered();
    return _defaultUniformBlock;
  }

  /// Returns size of the default uniform block (in bytes).
  static int uniformBlockSizeBytes() {
    _ensureDefaultsRegistered();
    return _defaultUniformBlock.sizeBytes;
  }

  /// Intercepts material variants and forwards them to specialized resolution systems.
  static ResolvedMaterialDescriptor? resolve(Material material) {
    final descriptor = descriptorFor(material);
    if (descriptor == null) return null;

    if (material is MeshBasicMaterial) {
      return _resolveBasic(descriptor, material);
    } else if (material is MeshStandardMaterial) {
      return _resolveStandard(descriptor, material);
    }
    return null;
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
    MaterialShaderLibrary.ensureBuiltInsRegistered();
    
    _defaultsRegistered = true;
    _registerDefaultsLocked();
  }

  static ResolvedMaterialDescriptor _resolveBasic(
    MaterialDescriptor descriptor,
    MeshBasicMaterial material,
  ) {
    final blendState = _blendStateFor(
      Blending.values[material.blending],
      material.transparent,
      material.opacity,
    );

    final state = descriptor.renderState.applyCommonOverrides(
      depthTest: material.depthTest,
      depthWrite: material.depthWrite,
      colorWrite: material.colorWrite,
      side: material.side, // Assuming material.side already handles internal common Side conversions
      hasBlend: blendState != null,
    ).copyWith(
      colorTarget: descriptor.renderState.colorTarget.copyWith(
        blendState: blendState,
      ),
    );

    return ResolvedMaterialDescriptor(
      descriptor: descriptor,
      renderState: state,
    );
  }

  static ResolvedMaterialDescriptor _resolveStandard(
    MaterialDescriptor descriptor,
    MeshStandardMaterial material,
  ) {
    final blendState = _blendStateFor(
      _standardBlendToCommon(StandardBlendMode.values[material.blending]),
      material.transparent,
      material.opacity,
    );

    final state = descriptor.renderState.applyCommonOverrides(
      depthTest: material.depthTest,
      depthWrite: material.depthWrite,
      colorWrite: material.colorWrite,
      side: _standardSideToCommon(material.side),
      hasBlend: blendState != null,
    ).copyWith(
      colorTarget: descriptor.renderState.colorTarget.copyWith(
        blendState: blendState,
      ),
    );

    return ResolvedMaterialDescriptor(
      descriptor: descriptor,
      renderState: state,
    );
  }


  static void _registerDefaultsLocked() {
    final basicDescriptor = MaterialDescriptor(
      key: 'material.basic',
      shader: MaterialShaderLibrary.basic(),
      uniformBlock: _defaultUniformBlock,
      bindings: _albedoBindings() + _volumeBindings(),
      renderState: MaterialRenderState(),
      requiredAttributes: _basicRequiredAttributes,
      optionalAttributes: _basicOptionalAttributes,
    );

    _registerInternal(
      basicDescriptor,
      [MeshBasicMaterial],
      true,
    );

    final standardDescriptor = MaterialDescriptor(
      key: 'material.meshStandard',
      shader: MaterialShaderLibrary.meshStandard(),
      uniformBlock: _defaultUniformBlock,
      bindings: _albedoBindings() +
          _normalBindings() +
          _roughnessBindings() +
          _metalnessBindings() +
          _aoBindings() +
          _environmentBindings(),
      renderState: MaterialRenderState(),
      requiredAttributes: _standardRequiredAttributes,
      optionalAttributes: _standardOptionalAttributes,
    );

    _registerInternal(
      standardDescriptor,
      [MeshStandardMaterial],
      true,
    );
  }

  static void resetForTests() {
    _state = const _DescriptorState(byKey: {}, byMaterial: {});
    _defaultsRegistered = false;
  }

  static List<MaterialBinding> _bindingsForGroup(int group) {
    _ensureDefaultsRegistered();
    final descriptors = _state.byKey.values;
    final allBindings = <MaterialBinding>[];

    for (final descriptor in descriptors) {
      for (final binding in descriptor.bindings) {
        if (binding.group == group) {
          allBindings.add(binding);
        }
      }
    }

    // Emulate distinctBy using a value verification tracking set
    final seen = <(int, MaterialBindingType)>{};
    final distinctBindings = <MaterialBinding>[];

    for (final binding in allBindings) {
      final key = (binding.binding, binding.type);
      if (seen.add(key)) {
        distinctBindings.add(binding);
      }
    }

    return distinctBindings..sort((a, b) => a.binding.compareTo(b.binding));
  }

  static List<MaterialBinding> materialTextureBindingLayout() => _bindingsForGroup(materialTextureGroup);

  static List<MaterialBinding> environmentBindingLayout() => _bindingsForGroup(environmentTextureGroup);

  static List<MaterialBinding> _albedoBindings() => [
        const MaterialBinding(
          name: 'albedoTexture',
          type: MaterialBindingType.texture2d,
          group: materialTextureGroup,
          binding: 0,
          source: MaterialBindingSource.albedoMap,
          required: false,
        ),
        const MaterialBinding(
          name: 'albedoSampler',
          type: MaterialBindingType.sampler,
          group: materialTextureGroup,
          binding: 1,
          source: MaterialBindingSource.albedoMap,
          required: false,
        ),
      ];

  static List<MaterialBinding> _normalBindings() => [
        const MaterialBinding(
          name: 'normalTexture',
          type: MaterialBindingType.texture2d,
          group: materialTextureGroup,
          binding: 2,
          source: MaterialBindingSource.normalMap,
          required: false,
        ),
        const MaterialBinding(
          name: 'normalSampler',
          type: MaterialBindingType.sampler,
          group: materialTextureGroup,
          binding: 3,
          source: MaterialBindingSource.normalMap,
          required: false,
        ),
      ];

  static List<MaterialBinding> _roughnessBindings() => [
        const MaterialBinding(
          name: 'roughnessTexture',
          type: MaterialBindingType.texture2d,
          group: materialTextureGroup,
          binding: 4,
          source: MaterialBindingSource.roughnessMap,
          required: false,
        ),
        const MaterialBinding(
          name: 'roughnessSampler',
          type: MaterialBindingType.sampler,
          group: materialTextureGroup,
          binding: 5,
          source: MaterialBindingSource.roughnessMap,
          required: false,
        ),
      ];

  static List<MaterialBinding> _metalnessBindings() => [
        const MaterialBinding(
          name: 'metalnessTexture',
          type: MaterialBindingType.texture2d,
          group: materialTextureGroup,
          binding: 6,
          source: MaterialBindingSource.metalnessMap,
          required: false,
        ),
        const MaterialBinding(
          name: 'metalnessSampler',
          type: MaterialBindingType.sampler,
          group: materialTextureGroup,
          binding: 7,
          source: MaterialBindingSource.metalnessMap,
          required: false,
        ),
      ];

  static List<MaterialBinding> _aoBindings() => [
        const MaterialBinding(
          name: 'aoTexture',
          type: MaterialBindingType.texture2d,
          group: materialTextureGroup,
          binding: 8,
          source: MaterialBindingSource.aoMap,
          required: false,
        ),
        const MaterialBinding(
          name: 'aoSampler',
          type: MaterialBindingType.sampler,
          group: materialTextureGroup,
          binding: 9,
          source: MaterialBindingSource.aoMap,
          required: false,
        ),
      ];

  static List<MaterialBinding> _volumeBindings() => [
        const MaterialBinding(
          name: 'volumeTexture',
          type: MaterialBindingType.texture3d,
          group: materialTextureGroup,
          binding: 10,
          source: MaterialBindingSource.volumeTexture,
          required: false,
        ),
        const MaterialBinding(
          name: 'volumeSampler',
          type: MaterialBindingType.sampler,
          group: materialTextureGroup,
          binding: 11,
          source: MaterialBindingSource.volumeTexture,
          required: false,
        ),
      ];

  static List<MaterialBinding> _environmentBindings() => [
        const MaterialBinding(
          name: 'prefilterTexture',
          type: MaterialBindingType.textureCube,
          group: environmentTextureGroup,
          binding: 0,
          source: MaterialBindingSource.environmentPrefilter,
          required: true,
        ),
        const MaterialBinding(
          name: 'prefilterSampler',
          type: MaterialBindingType.sampler,
          group: environmentTextureGroup,
          binding: 1,
          source: MaterialBindingSource.environmentPrefilter,
          required: true,
        ),
        const MaterialBinding(
          name: 'brdfLutTexture',
          type: MaterialBindingType.texture2d,
          group: environmentTextureGroup,
          binding: 2,
          source: MaterialBindingSource.environmentBrdf,
          required: true,
        ),
        const MaterialBinding(
          name: 'brdfLutSampler',
          type: MaterialBindingType.sampler,
          group: environmentTextureGroup,
          binding: 3,
          source: MaterialBindingSource.environmentBrdf,
          required: true,
        ),
      ];

  /// Evaluates material parameters and selects the optimal alpha blending equation.
  static GpuBlendState? _blendStateFor(Blending mode, bool transparent, double opacity) {
    if (mode == Blending.noBlending) {
      return null;
    }

    final bool needsBlend = transparent || opacity < 1.0 || mode != Blending.normalBlending;
    if (!needsBlend) return null;

    return switch (mode) {
      Blending.normalBlending || Blending.customBlending => _alphaBlend,
      Blending.additiveBlending => _additiveBlend,
      Blending.subtractiveBlending => _subtractiveBlend,
      Blending.multiplyBlending => _multiplyBlend,
      Blending.noBlending => null,
    };
  }

  // Global immutable constant blocks mapped precisely to WebGPU/gpux specification bindings
  static  GpuBlendState _alphaBlend = GpuBlendState(
    color: GpuBlendComponent(
      srcFactor: GpuBlendFactor.srcAlpha,
      dstFactor: GpuBlendFactor.oneMinusSrcAlpha,
      operation: GpuBlendOperation.add,
    ),
    alpha: GpuBlendComponent(
      srcFactor: GpuBlendFactor.one,
      dstFactor: GpuBlendFactor.oneMinusSrcAlpha,
      operation: GpuBlendOperation.add,
    ),
  );

  static GpuBlendState _additiveBlend = GpuBlendState(
    color: GpuBlendComponent(
      srcFactor: GpuBlendFactor.srcAlpha,
      dstFactor: GpuBlendFactor.one,
      operation: GpuBlendOperation.add,
    ),
    alpha: GpuBlendComponent(
      srcFactor: GpuBlendFactor.one,
      dstFactor: GpuBlendFactor.one,
      operation: GpuBlendOperation.add,
    ),
  );

  static GpuBlendState _subtractiveBlend = GpuBlendState(
    color: GpuBlendComponent(
      srcFactor: GpuBlendFactor.srcAlpha,
      dstFactor: GpuBlendFactor.one,
      operation: GpuBlendOperation.reverseSubtract,
    ),
    alpha: GpuBlendComponent(
      srcFactor: GpuBlendFactor.one,
      dstFactor: GpuBlendFactor.one,
      operation: GpuBlendOperation.reverseSubtract,
    ),
  );

  static GpuBlendState _multiplyBlend = GpuBlendState(
    color: GpuBlendComponent(
      srcFactor: GpuBlendFactor.dst,
      dstFactor: GpuBlendFactor.zero,
      operation: GpuBlendOperation.add,
    ),
    alpha: GpuBlendComponent(
      srcFactor: GpuBlendFactor.one,
      dstFactor: GpuBlendFactor.oneMinusSrcAlpha,
      operation: GpuBlendOperation.add,
    ),
  );

  /// Conversion bridge routing Standard material blending modes over to the unified engine enum.
  static Blending _standardBlendToCommon(StandardBlendMode mode) {
    return switch (mode) {
      StandardBlendMode.none => Blending.noBlending,
      StandardBlendMode.normal => Blending.normalBlending,
      StandardBlendMode.additive => Blending.additiveBlending,
      StandardBlendMode.subtractive => Blending.subtractiveBlending,
      StandardBlendMode.multiply => Blending.multiplyBlending,
      StandardBlendMode.custom => Blending.customBlending,
    };
  }

  /// Conversion bridge routing Standard face culling definitions over to the unified engine enum.
  static int _standardSideToCommon(int side) {
    return side;
  }

}

class _DescriptorState {
  const _DescriptorState({
    required this.byKey,
    required this.byMaterial,
  });

  final Map<String, MaterialDescriptor> byKey;
  final Map<Type, MaterialDescriptor> byMaterial;
}