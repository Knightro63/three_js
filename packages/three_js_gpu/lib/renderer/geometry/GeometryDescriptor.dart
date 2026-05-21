import 'dart:math' as math;
import 'dart:typed_data';
import 'package:gpux/gpux.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart'; // Adjust based on your exact gpux library paths

/// Geometry attributes mapped for vertex buffers.
enum GeometryAttribute {
  position,
  normal,
  color,
  uv0,
  uv1,
  tangent,
  morphPosition,
  morphNormal,
  instanceMatrix,
}

class GeometryAttributeBinding {
  const GeometryAttributeBinding({
    required this.attribute,
    required this.location,
    required this.stepMode,
  });

  final GeometryAttribute attribute;
  final int location;
  final GpuVertexStepMode stepMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeometryAttributeBinding &&
          runtimeType == other.runtimeType &&
          attribute == other.attribute &&
          location == other.location &&
          stepMode == other.stepMode;

  @override
  int get hashCode => Object.hash(attribute, location, stepMode);
}

class GeometryMetadata {
  const GeometryMetadata({
    required this.bindings,
    required this.hasMorphTargets,
    required this.morphTargetCount,
    required this.isInstanced,
  });

  final List<GeometryAttributeBinding> bindings;
  final bool hasMorphTargets;
  final int morphTargetCount;
  final bool isInstanced;

  bool has(GeometryAttribute attribute) {
    return bindings.any((b) => b.attribute == attribute);
  }

  GeometryAttributeBinding? bindingFor(GeometryAttribute attribute) {
    for (final b in bindings) {
      if (b.attribute == attribute) return b;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeometryMetadata &&
          runtimeType == other.runtimeType &&
          bindings == other.bindings &&
          hasMorphTargets == other.hasMorphTargets &&
          morphTargetCount == other.morphTargetCount &&
          isInstanced == other.isInstanced;

  @override
  int get hashCode => Object.hash(bindings, hasMorphTargets, morphTargetCount, isInstanced);
}

class VertexStream {
  const VertexStream({
    required this.data,
    required this.layout,
  });

  final Float32List data;
  final GpuVertexBufferLayout layout;
}

class GeometryBuffer {
  const GeometryBuffer({
    required this.streams,
    this.indexData,
    required this.vertexCount,
    required this.instanceCount,
    required this.metadata,
  });

  final List<VertexStream> streams;
  final Uint32List? indexData;
  final int vertexCount;
  final int instanceCount;
  final GeometryMetadata metadata;

  int get indexCount => indexData?.length ?? 0;
}

class GeometryBuildOptions {
  const GeometryBuildOptions({
    this.includeNormals = true,
    this.includeColors = true,
    this.includeUVs = true,
    this.includeSecondaryUVs = true,
    this.includeTangents = true,
    this.includeMorphTargets = true,
    this.includeInstancing = true,
  });

  final bool includeNormals;
  final bool includeColors;
  final bool includeUVs;
  final bool includeSecondaryUVs;
  final bool includeTangents;
  final bool includeMorphTargets;
  final bool includeInstancing;
}

abstract class GeometryBuilder {
  static const _positionAttr = 'position';
  static const _normalAttr = 'normal';
  static const _colorAttr = 'color';
  static const _uvAttr = 'uv';
  static const _uv2Attr = 'uv2';
  static const _tangentAttr = 'tangent';

  static const _floatBytes = 4;
  static final Float32List _defaultNormal = Float32List.fromList([0.0, 1.0, 0.0]);
  static final Float32List _defaultColor = Float32List.fromList([1.0, 1.0, 1.0]);
  static final Float32List _defaultTangent = Float32List.fromList([1.0, 0.0, 0.0, 1.0]);
  static final Float32List _defaultUv = Float32List.fromList([0.0, 0.0]);
  static final Float32List _zero3 = Float32List.fromList([0.0, 0.0, 0.0]);

  static GeometryBuffer build(
    BufferGeometry geometry, {
    GeometryBuildOptions options = const GeometryBuildOptions(),
  }) {
    final vertexStreamResult = _buildVertexStream(geometry, options);
    
    final instanceStreamResult = options.includeInstancing 
        ? _buildInstanceStream(geometry, vertexStreamResult.nextShaderLocation) 
        : null;

    final streams = <VertexStream>[vertexStreamResult.stream];
    final instanceCount = instanceStreamResult?.instanceCount ?? geometry.instanceCount;
    
    if (instanceStreamResult != null) {
      streams.add(instanceStreamResult.stream);
    }

    final indexAttribute = geometry.index;
    final indexData = indexAttribute != null
        ? Uint32List.fromList(List.generate(indexAttribute.count, (i) => indexAttribute.getX(i)?.toInt() ?? 0))
        : null;

    int maxMorph = 0;
    for (final list in geometry.morphAttributes.values) {
      maxMorph = math.max(maxMorph, list.length);
    }

    final metadata = GeometryMetadata(
      bindings: vertexStreamResult.bindings + (instanceStreamResult?.bindings ?? const []),
      hasMorphTargets: geometry.morphAttributes.isNotEmpty,
      morphTargetCount: maxMorph,
      isInstanced: instanceStreamResult != null,
    );

    return GeometryBuffer(
      streams: streams,
      indexData: indexData,
      vertexCount: vertexStreamResult.vertexCount,
      instanceCount: instanceCount ?? 0,
      metadata: metadata,
    );
  }

  static _VertexStreamResult _buildVertexStream(
    BufferGeometry geometry,
    GeometryBuildOptions options,
  ) {
    final positions = geometry.getAttributeFromString(_positionAttr);
    if (positions == null) {
      throw StateError("BufferGeometry is missing required '$_positionAttr' attribute");
    }
    assert(positions.itemSize >= 3, 'Expected position attribute with itemSize >= 3 (received ${positions.itemSize})');

    final vertexCount = positions.count;
    final normals = options.includeNormals ? geometry.getAttributeFromString(_normalAttr) : null;
    final tangents = options.includeTangents ? geometry.getAttributeFromString(_tangentAttr) : null;
    final colors = options.includeColors ? geometry.getAttributeFromString(_colorAttr) : null;
    final uv = options.includeUVs ? geometry.getAttributeFromString(_uvAttr) : null;
    final uv2 = options.includeSecondaryUVs ? geometry.getAttributeFromString(_uv2Attr) : null;

    final packedAttributes = <_PackedAttribute>[];
    
    packedAttributes.add(_PackedAttribute(
      attribute: positions,
      componentCount: 3,
      defaultValue: null,
      format: GpuVertexFormat.float32x3,
      includeWhenMissing: true,
      attributeType: GeometryAttribute.position,
    ));
    packedAttributes.add(_PackedAttribute(
      attribute: normals,
      componentCount: 3,
      defaultValue: _defaultNormal,
      format: GpuVertexFormat.float32x3,
      includeWhenMissing: options.includeNormals,
      attributeType: GeometryAttribute.normal,
    ));
    packedAttributes.add(_PackedAttribute(
      attribute: colors,
      componentCount: 3,
      defaultValue: _defaultColor,
      format: GpuVertexFormat.float32x3,
      includeWhenMissing: options.includeColors,
      attributeType: GeometryAttribute.color,
    ));
    packedAttributes.add(_PackedAttribute(
      attribute: tangents,
      componentCount: 4,
      defaultValue: _defaultTangent,
      format: GpuVertexFormat.float32x4,
      includeWhenMissing: options.includeTangents,
      attributeType: GeometryAttribute.tangent,
    ));
    packedAttributes.add(_PackedAttribute(
      attribute: uv,
      componentCount: 2,
      defaultValue: _defaultUv,
      format: GpuVertexFormat.float32x2,
      includeWhenMissing: options.includeUVs,
      attributeType: GeometryAttribute.uv0,
    ));
    packedAttributes.add(_PackedAttribute(
      attribute: uv2,
      componentCount: 2,
      defaultValue: _defaultUv,
      format: GpuVertexFormat.float32x2,
      includeWhenMissing: options.includeSecondaryUVs,
      attributeType: GeometryAttribute.uv1,
    ));

    if (options.includeMorphTargets) {
      final morphPositions = geometry.morphAttributes[_positionAttr];
      if (morphPositions != null) {
        for (final attr in morphPositions) {
          assert(attr.itemSize >= 3, 'Morph position attribute requires itemSize >= 3 (received ${attr.itemSize})');
          packedAttributes.add(_PackedAttribute(
            attribute: attr,
            componentCount: 3,
            defaultValue: _zero3,
            format: GpuVertexFormat.float32x3,
            includeWhenMissing: true,
            attributeType: GeometryAttribute.morphPosition,
          ));
        }
      }
      final morphNormals = geometry.morphAttributes[_normalAttr];
      if (morphNormals != null) {
        for (final attr in morphNormals) {
          assert(attr.itemSize >= 3, 'Morph normal attribute requires itemSize >= 3 (received ${attr.itemSize})');
          packedAttributes.add(_PackedAttribute(
            attribute: attr,
            componentCount: 3,
            defaultValue: _zero3,
            format: GpuVertexFormat.float32x3,
            includeWhenMissing: true,
            attributeType: GeometryAttribute.morphNormal,
          ));
        }
      }
    }

    final attributes = packedAttributes.where((a) => a.includeWhenMissing || a.attribute != null).toList();
    int componentsPerVertex = 0;
    for (final a in attributes) {
      componentsPerVertex += a.componentCount;
    }

    final vertexData = Float32List(vertexCount * componentsPerVertex);
    int writeOffset = 0;

    for (int index = 0; index < vertexCount; index++) {
      for (final attr in attributes) {
        if (attr.attribute != null) {
          _writeComponents(attr.attribute!, index, attr.componentCount, vertexData, writeOffset);
        } else if (attr.defaultValue != null) {
          vertexData.setRange(writeOffset, writeOffset + attr.componentCount, attr.defaultValue!);
        }
        writeOffset += attr.componentCount;
      }
    }

    final layoutAttributes = <GpuVertexAttribute>[];
    final bindings = <GeometryAttribute, GeometryAttributeBinding>{};
    int shaderLocation = 0;
    int byteOffset = 0;

    for (final attr in attributes) {
      layoutAttributes.add(GpuVertexAttribute(
        format: attr.format,
        offset: byteOffset,
        shaderLocation: shaderLocation,
      ));
      
      final type = attr.attributeType;
      if (type != null) {
        if (!bindings.containsKey(type)) {
          bindings[type] = GeometryAttributeBinding(
            attribute: type,
            location: shaderLocation,
            stepMode: GpuVertexStepMode.vertex,
          );
        }
      }
      shaderLocation += 1;
      byteOffset += attr.componentCount * _floatBytes;
    }

    final layout = GpuVertexBufferLayout(
      arrayStride: byteOffset,
      stepMode: GpuVertexStepMode.vertex,
      attributes: layoutAttributes,
    );

    return _VertexStreamResult(
      stream: VertexStream(data: vertexData, layout: layout),
      vertexCount: vertexCount,
      nextShaderLocation: shaderLocation,
      bindings: bindings.values.toList(),
    );
  }

  static _InstanceStreamResult? _buildInstanceStream(
    BufferGeometry geometry,
    int startShaderLocation,
  ) {
    final instancedAttributes = geometry.attributes;
    if (instancedAttributes.isEmpty) return null;

    int instanceCount = 0;
    if ((geometry.instanceCount ?? 0) > 0) {
      instanceCount = (geometry.instanceCount ?? 0);
    } else if (instancedAttributes.isNotEmpty) {
      instanceCount = instancedAttributes.values.first.count;
    }

    if (instanceCount == 0) return null;

    final sortedKeys = instancedAttributes.keys.toList()..sort();
    final attributes = <_PackedAttribute>[];

    for (final key in sortedKeys) {
      final attribute = instancedAttributes[key]!;
      if (attribute.itemSize <= 4) {
        attributes.add(_PackedAttribute(
          attribute: attribute,
          componentCount: attribute.itemSize,
          defaultValue: null,
          format: _formatForSize(attribute.itemSize),
          includeWhenMissing: true,
          attributeType: GeometryAttribute.instanceMatrix,
        ));
      } else if (attribute.itemSize % 4 == 0) {
        final chunkCount = attribute.itemSize ~/ 4;
        for (int chunk = 0; chunk < chunkCount; chunk++) {
          attributes.add(_PackedAttribute(
            attribute: _ChunkedBufferAttribute(attribute, chunk * 4, 4),
            componentCount: 4,
            defaultValue: null,
            format: GpuVertexFormat.float32x4,
            includeWhenMissing: true,
            attributeType: chunk == 0 ? GeometryAttribute.instanceMatrix : null,
          ));
        }
      } else {
        throw StateError('Unsupported instanced attribute itemSize=${attribute.itemSize}');
      }
    }

    if (attributes.isEmpty) return null;

    int componentsPerInstance = 0;
    for (final a in attributes) {
      componentsPerInstance += a.componentCount;
    }

    final instanceData = Float32List(instanceCount * componentsPerInstance);
    int writeOffset = 0;

    for (int instanceIndex = 0; instanceIndex < instanceCount; instanceIndex++) {
      for (final attr in attributes) {
        _writeComponents(attr.attribute!, instanceIndex, attr.componentCount, instanceData, writeOffset);
        writeOffset += attr.componentCount;
      }
    }

    final layoutAttributes = <GpuVertexAttribute>[];
    final bindings = <GeometryAttribute, GeometryAttributeBinding>{};
    int shaderLocation = startShaderLocation;
    int byteOffset = 0;

    for (final attr in attributes) {
      layoutAttributes.add(GpuVertexAttribute(
        format: attr.format,
        offset: byteOffset,
        shaderLocation: shaderLocation,
      ));

      final type = attr.attributeType;
      if (type != null) {
        if (!bindings.containsKey(type)) {
          bindings[type] = GeometryAttributeBinding(
            attribute: type,
            location: shaderLocation,
            stepMode: GpuVertexStepMode.instance,
          );
        }
      }
      shaderLocation += 1;
      byteOffset += attr.componentCount * _floatBytes;
    }

    final layout = GpuVertexBufferLayout(
      arrayStride: byteOffset,
      stepMode: GpuVertexStepMode.instance,
      attributes: layoutAttributes,
    );

    return _InstanceStreamResult(
      stream: VertexStream(data: instanceData, layout: layout),
      instanceCount: instanceCount,
      bindings: bindings.values.toList(),
    );
  }

  static void _writeComponents(
    BufferAttribute attribute,
    int vertexIndex,
    int componentCount,
    Float32List target,
    int targetOffset,
  ) {
    switch (componentCount) {
      case 1:
        target[targetOffset] = attribute.getX(vertexIndex)!.toDouble();
        break;
      case 2:
        target[targetOffset] = attribute.getX(vertexIndex)!.toDouble();
        target[targetOffset + 1] = attribute.getY(vertexIndex)!.toDouble();
        break;
      case 3:
        target[targetOffset] = attribute.getX(vertexIndex)!.toDouble();
        target[targetOffset + 1] = attribute.getY(vertexIndex)!.toDouble();
        target[targetOffset + 2] = attribute.getZ(vertexIndex)!.toDouble();
        break;
      case 4:
        target[targetOffset] = attribute.getX(vertexIndex)!.toDouble();
        target[targetOffset + 1] = attribute.getY(vertexIndex)!.toDouble();
        target[targetOffset + 2] = attribute.getZ(vertexIndex)!.toDouble();
        target[targetOffset + 3] = attribute.getW(vertexIndex)!.toDouble();
        break;
      default:
        final base = vertexIndex * attribute.itemSize;
        final source = attribute.array;
        for (int component = 0; component < componentCount; component++) {
          target[targetOffset + component] = source[base + component];
        }
    }
  }

  static GpuVertexFormat _formatForSize(int components) {
    return switch (components) {
      1 => GpuVertexFormat.float32,
      2 => GpuVertexFormat.float32x2,
      3 => GpuVertexFormat.float32x3,
      4 => GpuVertexFormat.float32x4,
      _ => throw StateError('Unsupported component count $components'),
    };
  }
}

class _PackedAttribute {
  const _PackedAttribute({
    this.attribute,
    required this.componentCount,
    this.defaultValue,
    required this.format,
    required this.includeWhenMissing,
    this.attributeType,
  });

  final BufferAttribute? attribute;
  final int componentCount;
  final Float32List? defaultValue;
  final GpuVertexFormat format;
  final bool includeWhenMissing;
  final GeometryAttribute? attributeType;
}

class _VertexStreamResult {
  const _VertexStreamResult({
    required this.stream,
    required this.vertexCount,
    required this.nextShaderLocation,
    required this.bindings,
  });

  final VertexStream stream;
  final int vertexCount;
  final int nextShaderLocation;
  final List<GeometryAttributeBinding> bindings;
}

class _InstanceStreamResult {
  const _InstanceStreamResult({
    required this.stream,
    required this.instanceCount,
    required this.bindings,
  });

  final VertexStream stream;
  final int instanceCount;
  final List<GeometryAttributeBinding> bindings;
}

class _ChunkedBufferAttribute extends BufferAttribute {
  _ChunkedBufferAttribute(this.delegate, this.start, this.length)
      : super(delegate.array, length, delegate.normalized);

  final BufferAttribute delegate;
  final int start;
  final int length;

  @override
  int get count => delegate.count;

  @override
  int get itemSize => length;

  @override
  double getX(int index) => _value(index, 0);

  @override
  double getY(int index) => _value(index, 1);

  @override
  double getZ(int index) => _value(index, 2);

  @override
  double getW(int index) => _value(index, 3);

  double _value(int vertexIndex, int component) {
    if (component >= length) return 0.0;
    final base = vertexIndex * delegate.itemSize + start + component;
    return delegate.array[base];
  }
}
