import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_impeller_renderer/renderer/material/material_description_registry.dart';
import 'package:three_js_math/three_js_math.dart'; // Adjust based on your exact gpu library paths

class GeometryBindings{
  final gpu.GpuContext context;
  final Object3D object;
  final BufferGeometry geometry;
  final MaterialDescriptor descriptor;

  GeometryBindings(
    this.context, 
    this.object,
    this.geometry,
    this.descriptor,
  );

  bool bind(gpu.RenderPass pass){
    final bool isInstanced = object is InstancedMesh;
    final int instanceCount = isInstanced ? (object.count ?? 1) : 1;

    final GpuGeometryBuffers? hardwareBuffers = _createHardwareBuffers(instanceCount);
    if (hardwareBuffers == null) return false;

    bool needsUpdate = hardwareBuffers.needsUpdate;
    String uuidVert = '${geometry.uuid}_vert';
    String uuidIndex = '${geometry.uuid}_index';

    if(geometry.userData[uuidVert] == null || needsUpdate) {
      // 1. Calculate the real size in bytes from your typed data array
      // (Assuming hardwareBuffers.vertexBuffer is a TypedData like Float32List or ByteData)
      final int vertexBytesLength = hardwareBuffers.vertexBuffer.lengthInBytes;

      if(geometry.userData[uuidVert] == null){ 
        // Pass the BYTE length here, NOT the vertex count!
        geometry.userData[uuidVert] = context.createDeviceBuffer(
          gpu.StorageMode.hostVisible, 
          vertexBytesLength
        ); 
      }
      
      // 2. Safely populate your permanent VRAM buffer 
      geometry.userData[uuidVert].overwrite(hardwareBuffers.vertexBuffer); 
      
      // 3. Create the view using byte parameters
      geometry.userData['${uuidVert}_bufferView'] = gpu.BufferView(
        geometry.userData[uuidVert], 
        offsetInBytes: 0, 
        lengthInBytes: vertexBytesLength // Must match the byte size!
      ); 
    }

    // 4. Do the exact same thing for your Index Buffer
    if(hardwareBuffers.indexCount != 0 && (geometry.userData[uuidIndex] == null || needsUpdate)) {
      final int indexBytesLength = hardwareBuffers.indexBuffer.lengthInBytes;

      if(geometry.userData[uuidIndex] == null) {
        geometry.userData[uuidIndex] = context.createDeviceBuffer(
          gpu.StorageMode.hostVisible, 
          indexBytesLength
        );
      }
      
      geometry.userData[uuidIndex].overwrite(hardwareBuffers.indexBuffer);
      geometry.userData['${uuidIndex}_bufferView'] = gpu.BufferView(
        geometry.userData[uuidIndex], 
        offsetInBytes: 0, 
        lengthInBytes: indexBytesLength
      );
    }

    void bind(int i,bool isInstance){
      pass.bindVertexBuffer( 
        geometry.userData['${uuidVert}_bufferView'], 
        hardwareBuffers.vertexCount
      );
      if(hardwareBuffers.indexCount != 0){
        pass.bindIndexBuffer( 
          geometry.userData['${uuidIndex}_bufferView'],
          hardwareBuffers.indexType, 
          hardwareBuffers.indexCount
        );
      }
    }

    if(instanceCount > 0){
      for(int i = 0; i < instanceCount; i++){
        bind(i,true);
      }
    }
    else{
      bind(0,false);
    }

    return true;
  }

  // GpuGeometryBuffers? _createAttributeBuffers(int instanceCount) {
  //   String uuid = '${material.uuid}_${geometry.uuid}';
  //   int version = 0;

  //   if (material.userData[uuid]?.version == version) {
  //     material.userData[uuid].needsUpdate = false;
  //     if(object.autoUpdate){
  //       _updateBuffer(material.userData[uuid]);
  //     }
  //     return material.userData[uuid];
  //   }

  //   final positionAttr = geometry.attributes['position'] as BufferAttribute?;
  //   final indexAttr = geometry.index;

  //   if (positionAttr == null) {
  //     return null;
  //   }

  //   final int totalVertices = positionAttr.count;
  //   final int effectiveInstances = instanceCount > 0 ? instanceCount : 1;
    
  //   // 1. Calculate multiplied capacities across the instance block window
  //   final int finalVertexCount = totalVertices * effectiveInstances;
  //   int originalIndexCount = indexAttr?.count ?? totalVertices;
  //   final int finalIndexCount = originalIndexCount * effectiveInstances;
  //   bool overwrite = indexAttr == null;

  //   // Extract base template index reference data
  //   final TypedDataList baseIndices = (indexAttr != null) ? indexAttr.array : Uint16List(totalVertices);

  //   // Determine standard integer sizing requirements for the index pool allocation
  //   late TypedDataList finalIndices;
  //   if (finalVertexCount > 65535 || baseIndices is Uint32List || baseIndices is Int32List) {
  //     finalIndices = Uint32List(finalIndexCount);
  //   } else {
  //     finalIndices = Uint16List(finalIndexCount);
  //   }


  //   for(final key in geometry.attributes.keys){
  //     final buffer = geometry.attributes[key] as BufferAttribute;
  //     int stride = buffer.itemSize;
  //   }

  //   int currentInst = 0;
  //   double currentInstDouble = 0.0;
  //   int currentVertexTemplateIdx = 0;

  //   for (int globalV = 0; globalV < finalVertexCount; globalV++) {
  //     final int i = currentVertexTemplateIdx;

  //     // Step indices manually instead of using division/modulo
  //     currentVertexTemplateIdx++;
  //     if (currentVertexTemplateIdx == totalVertices) {
  //       currentVertexTemplateIdx = 0;
  //       currentInst++;
  //       currentInstDouble = currentInst.toDouble();
  //     }
  //   }

  //   // Track index loops manually
  //   int currentIndexTemplateIdx = 0;
  //   int vertexOffset = 0;

  //   // B. Unnested Single-Pass Index Mapping Layout
  //   for (int globalIdx = 0; globalIdx < finalIndexCount; globalIdx++) {
  //     final int j = currentIndexTemplateIdx;
  //     final int baseIndex = overwrite ? j : baseIndices[j];
      
  //     finalIndices[globalIdx] = baseIndex + vertexOffset;

  //     currentIndexTemplateIdx++;
  //     if (currentIndexTemplateIdx == originalIndexCount) {
  //       currentIndexTemplateIdx = 0;
  //       vertexOffset += totalVertices; // Tick up the base offset for the next instance block
  //     }
  //   }
    
  //   material.userData[uuid] = GpuGeometryBuffers(
  //     vertexFloatArray: interleavedData,
  //     indexBuffer: finalIndices.buffer.asByteData(),
  //     indexCount: finalIndexCount, 
  //     vertexCount: finalVertexCount, 
  //     version: version,
  //     needsUpdate: true,
  //     indexType: finalIndices is Uint32List ? gpu.IndexType.int32 : gpu.IndexType.int16,
  //     instanceCount: effectiveInstances,
  //   );

  //   return material.userData[uuid];
  // }
  
  GpuGeometryBuffers? _createHardwareBuffers(int instanceCount) {
    String uuid = '${geometry.uuid}_buffers';
    int version = 
      (geometry.attributes['position']?.version ?? 0) +
      (geometry.attributes['uv']?.version ?? 0) +
      (geometry.attributes['normal']?.version ?? 0)+
      (geometry.attributes['color']?.version ?? 0)+
      (geometry.attributes['skinIndex']?.version ?? 0)+
      (geometry.attributes['skinWeight']?.version ?? 0);

    if (geometry.userData[uuid]?.version == version) {
      geometry.userData[uuid].needsUpdate = false;
      if(object.autoUpdate){
        _updateBuffer(geometry.userData[uuid]);
      }
      return geometry.userData[uuid];
    }

    final positionAttr = geometry.attributes['position'] as BufferAttribute?;
    final normalAttr = geometry.attributes['normal'] as BufferAttribute?;
    final uv0Attr = geometry.attributes['uv'] as BufferAttribute?;
    final uv1Attr = geometry.attributes['uv1'] as BufferAttribute?;
    final colorAttr = geometry.attributes['color'] as BufferAttribute?;
    final skinIndexAttr = geometry.attributes['skinIndex'] as BufferAttribute?;
    final skinWeightAttr = geometry.attributes['skinWeight'] as BufferAttribute?;
    final lineDistanceAttr = geometry.attributes['lineDistances'] as BufferAttribute?;
    final indexAttr = geometry.index;

    if (positionAttr == null) {
      return null;
    }

    final int totalVertices = positionAttr.count;
    final int effectiveInstances = instanceCount > 0 ? instanceCount : 1;
    
    // 1. Calculate multiplied capacities across the instance block window
    final int finalVertexCount = totalVertices * effectiveInstances;
    int originalIndexCount = indexAttr?.count ?? totalVertices;
    final int finalIndexCount = originalIndexCount * effectiveInstances;
    bool overwrite = indexAttr == null;

    // Extract base template index reference data
    final TypedDataList baseIndices = (indexAttr != null) ? indexAttr.array : Uint16List(totalVertices);

    // Determine standard integer sizing requirements for the index pool allocation
    late TypedDataList finalIndices;
    if (finalVertexCount > 65535 || baseIndices is Uint32List || baseIndices is Int32List) {
      finalIndices = Uint32List(finalIndexCount);
    } else {
      finalIndices = Uint16List(finalIndexCount);
    }

    // Attribute array extracts
    final Float32List positions = positionAttr.array as Float32List;
    final Float32List? normals = normalAttr?.array as Float32List?;
    final colors = colorAttr?.array.buffer.asFloat32List();
    final uvs0 = uv0Attr?.array.buffer.asFloat32List();
    final uvs1 = uv1Attr?.array.buffer.asFloat32List();
    final skinIndices = skinIndexAttr?.array;
    final Float32List? skinWeights = skinWeightAttr?.array as Float32List?;
    final Float32List? lineDistance = lineDistanceAttr?.array as Float32List?;

    final attri = descriptor.requiredAttributes;

    // 2. Configure float layout step strides and dynamic slot offset positions
    int stride = 3; 
    final int colorItemSize = colorAttr?.itemSize ?? 3;
    final Map<Attribute, int> attributeOffsets = {};

    if (attri.contains(Attribute.normal)) {
      attributeOffsets[Attribute.normal] = stride;
      stride += 3;
    }
    if (attri.contains(Attribute.uv)) {
      attributeOffsets[Attribute.uv] = stride;
      stride += 2;
    }
    if (attri.contains(Attribute.uv2)) {
      attributeOffsets[Attribute.uv2] = stride;
      stride += 2;
    }
    if (attri.contains(Attribute.color)) {
      attributeOffsets[Attribute.color] = stride;
      stride += 3;
    }
    if (attri.contains(Attribute.skinIndex)) {
      attributeOffsets[Attribute.skinIndex] = stride;
      stride += 4;
    }
    if (attri.contains(Attribute.skinWeight)) {
      attributeOffsets[Attribute.skinWeight] = stride;
      stride += 4;
    }
    // LOCK IN SLOT: Instance ID Attribute Location Layout
    if (attri.contains(Attribute.instanceId)) {
      attributeOffsets[Attribute.instanceId] = stride;
      stride += 1;
    }
    if (attri.contains(Attribute.lineDistances)) {
      attributeOffsets[Attribute.lineDistances] = stride;
      stride += 1;
    }

    final Float32List interleavedData = Float32List(finalVertexCount * stride);
    int vertexStride = 0;

    // ========================================================
    // 3. FLATTENED MASTER INFLATION LOOP (Unnested & Optimized)
    // ========================================================

    // Cache map lookups and attribute states outside the loop
    final bool hasNormal = attri.contains(Attribute.normal);
    final bool hasUv0 = uvs0 != null && attri.contains(Attribute.uv);
    final bool hasUv1 = attri.contains(Attribute.uv2);
    final bool hasColor = attri.contains(Attribute.color);
    final bool hasSkinIndex = attri.contains(Attribute.skinIndex);
    final bool hasSkinWeight = attri.contains(Attribute.skinWeight);
    final bool hasInstanceId = attri.contains(Attribute.instanceId);
    final bool hasLineDistance = attri.contains(Attribute.lineDistances);

    final int normalOff = attributeOffsets[Attribute.normal] ?? 0;
    final int uv0Off = attributeOffsets[Attribute.uv] ?? 0;
    final int uv1Off = attributeOffsets[Attribute.uv2] ?? 0;
    final int colorOff = attributeOffsets[Attribute.color] ?? 0;
    final int skinIdxOff = attributeOffsets[Attribute.skinIndex] ?? 0;
    final int skinWgtOff = attributeOffsets[Attribute.skinWeight] ?? 0;
    final int instanceIdOff = attributeOffsets[Attribute.instanceId] ?? 0;
    final int lineDistanceOff = attributeOffsets[Attribute.lineDistances] ?? 0;

    final double matRed = 1;//material.color.red;
    final double matGreen = 1;//material.color.green;
    final double matBlue = 1;//material.color.blue;

    // Track current instance and template vertex indices manually
    int currentInst = 0;
    double currentInstDouble = 0.0;
    int currentVertexTemplateIdx = 0;

    // A. Unnested Single-Pass Vertex Buffering Layout
    for (int globalV = 0; globalV < finalVertexCount; globalV++) {
      final int i = currentVertexTemplateIdx;
      
      // 1. Position
      final int i3 = i * 3;
      interleavedData[vertexStride + 0] = positions[i3 + 0];
      interleavedData[vertexStride + 1] = positions[i3 + 1];
      interleavedData[vertexStride + 2] = positions[i3 + 2];

      // 2. Normal
      if (hasNormal) {
        final int dest = vertexStride + normalOff;
        if (normals != null) {
          interleavedData[dest + 0] = normals[i3 + 0];
          interleavedData[dest + 1] = normals[i3 + 1];
          interleavedData[dest + 2] = normals[i3 + 2];
        } else {
          interleavedData[dest + 0] = 0.0;
          interleavedData[dest + 1] = 0.0;
          interleavedData[dest + 2] = 0.0;
        }
      }

      // 3. UV0
      if (hasUv0) {
        final int i2 = i * 2;
        final int dest = vertexStride + uv0Off;
        interleavedData[dest + 0] = uvs0[i2 + 0];
        interleavedData[dest + 1] = uvs0[i2 + 1];
      }

      // 4. UV1
      if (hasUv1) {
        final int i2 = i * 2;
        final int dest = vertexStride + uv1Off;
        if (uvs1 != null) {
          interleavedData[dest + 0] = uvs1[i2 + 0];
          interleavedData[dest + 1] = uvs1[i2 + 1];
        } else {
          interleavedData[dest + 0] = 0.0;
          interleavedData[dest + 1] = 0.0;
        }
      }

      // 5. Colors
      if (hasColor) {
        final int dest = vertexStride + colorOff;
        final int idx = i * colorItemSize;
        final int colorsLen = colors?.length ?? 0;
        interleavedData[dest + 0] = (colorsLen > idx) ? colors![idx] : matRed;
        interleavedData[dest + 1] = (colorsLen > idx + 1) ? colors![idx + 1] : matGreen;
        interleavedData[dest + 2] = (colorsLen > idx + 2) ? colors![idx + 2] : matBlue;
      }

      // 6. Skin Index
      if (hasSkinIndex) {
        final int dest = vertexStride + skinIdxOff;
        final int idx = i * 4;
        final int len = skinIndices?.length ?? 0;
        interleavedData[dest + 0] = (len > idx) ? skinIndices![idx].toDouble() : 0.0;
        interleavedData[dest + 1] = (len > idx + 1) ? skinIndices![idx + 1].toDouble() : 0.0;
        interleavedData[dest + 2] = (len > idx + 2) ? skinIndices![idx + 2].toDouble() : 0.0;
        interleavedData[dest + 3] = (len > idx + 3) ? skinIndices![idx + 3].toDouble() : 0.0;
      }

      // 7. Skin Weight
      if (hasSkinWeight) {
        final int dest = vertexStride + skinWgtOff;
        final int idx = i * 4;
        final int len = skinWeights?.length ?? 0;
        interleavedData[dest + 0] = (len > idx) ? skinWeights![idx] : 1.0;
        interleavedData[dest + 1] = (len > idx + 1) ? skinWeights![idx + 1] : 0.0;
        interleavedData[dest + 2] = (len > idx + 2) ? skinWeights![idx + 2] : 0.0;
        interleavedData[dest + 3] = (len > idx + 3) ? skinWeights![idx + 3] : 0.0;
      }

      // 8. Instance ID
      if (hasInstanceId) {
        interleavedData[vertexStride + instanceIdOff] = currentInstDouble;
      }

      // 9. Line Distance
      if (hasLineDistance) {
        interleavedData[vertexStride + lineDistanceOff] = lineDistance?[i] ?? 0;
      }

      vertexStride += stride;

      // Step indices manually instead of using division/modulo
      currentVertexTemplateIdx++;
      if (currentVertexTemplateIdx == totalVertices) {
        currentVertexTemplateIdx = 0;
        currentInst++;
        currentInstDouble = currentInst.toDouble();
      }
    }

    // Track index loops manually
    int currentIndexTemplateIdx = 0;
    int vertexOffset = 0;

    // B. Unnested Single-Pass Index Mapping Layout
    for (int globalIdx = 0; globalIdx < finalIndexCount; globalIdx++) {
      final int j = currentIndexTemplateIdx;
      final int baseIndex = overwrite ? j : baseIndices[j];
      
      finalIndices[globalIdx] = baseIndex + vertexOffset;

      currentIndexTemplateIdx++;
      if (currentIndexTemplateIdx == originalIndexCount) {
        currentIndexTemplateIdx = 0;
        vertexOffset += totalVertices; // Tick up the base offset for the next instance block
      }
    }
    
    geometry.userData[uuid] = GpuGeometryBuffers(
      vertexFloatArray: interleavedData,
      indexBuffer: finalIndices.buffer.asByteData(),
      indexCount: finalIndexCount, 
      vertexCount: finalVertexCount, 
      version: version,
      needsUpdate: true,
      indexType: finalIndices is Uint32List ? gpu.IndexType.int32 : gpu.IndexType.int16,
      instanceCount: effectiveInstances,
    );

    return geometry.userData[uuid];
  }

  void _updateBuffer(GpuGeometryBuffers cachedBuffers) {
    final positionAttr = geometry.attributes['position'] as BufferAttribute;
    final normalAttr = geometry.attributes['normal'] as BufferAttribute?;

    final Float32List currentPositions = positionAttr.array as Float32List;
    final Float32List? currentNormals = normalAttr?.array as Float32List?;

    final Float32List destData = cachedBuffers.vertexFloatArray;
    
    // 1. DYNAMICALLY RESOLVE STRIDE AND OFFSETS FROM THE ORIGINAL LAYOUT DESCRIPTOR
    final attri = descriptor.requiredAttributes;
    int stride = 3; 
    int normalOff = 0;

    if (attri.contains(Attribute.normal)) {
      normalOff = stride;
      stride += 3;
    }
    if (attri.contains(Attribute.uv)) stride += 2;
    if (attri.contains(Attribute.uv2)) stride += 2;
    if (attri.contains(Attribute.color)) stride += 3;
    if (attri.contains(Attribute.skinIndex)) stride += 4;
    if (attri.contains(Attribute.skinWeight)) stride += 4;
    if (attri.contains(Attribute.instanceId)) stride += 1;

    final int totalVerts = positionAttr.count;
    final bool hasNormal = currentNormals != null && attri.contains(Attribute.normal);

    // 2. RUN THE SAFELY POSITIONED UPDATE LOOP
    int vertexStride = 0;

    int currentVertexTemplateIdx = 0;
    final int finalVertexCount = totalVerts * cachedBuffers.instanceCount;

    for (int globalV = 0; globalV < finalVertexCount; globalV++) {
      final int i = currentVertexTemplateIdx;
      final int i3 = i * 3;

      // 1. Safely insert position into its exact slot
      destData.setRange(vertexStride + 0, vertexStride + 3, currentPositions, i3);

      // 2. Safely insert normal into its exact slot
      if (hasNormal) {
        destData.setRange(vertexStride + normalOff, vertexStride + normalOff + 3, currentNormals, i3);
      }

      // 3. Step forward by the TRUE full layout stride length
      vertexStride += stride;

      // 4. Step vertex templates manually instead of using division or modulo
      currentVertexTemplateIdx++;
      if (currentVertexTemplateIdx == totalVerts) {
        currentVertexTemplateIdx = 0;
      }
    }

    cachedBuffers.needsUpdate = true;
  }

}

class GpuGeometryBuffers {
  GpuGeometryBuffers({
    required this.vertexFloatArray,
    required this.indexBuffer,
    required this.indexCount,
    required this.vertexCount,
    required this.version,
    required this.indexType,
    required this.needsUpdate,
    required this.instanceCount,
  });
  ByteData get vertexBuffer => vertexFloatArray.buffer.asByteData();
  final Float32List vertexFloatArray;
  final ByteData indexBuffer;
  final int indexCount;
  final int vertexCount;
  int version;
  final int instanceCount;
  final gpu.IndexType indexType;
  bool needsUpdate;
}

class GpuFilterPair {
  final gpu.MinMagFilter minFilter;
  final gpu.MipFilter mipFilter;
  const GpuFilterPair(this.minFilter, this.mipFilter);
}

class GpuSamplerConverter {
  // OpenGL Filter Constants
  static const int GL_NEAREST = 9728;
  static const int GL_LINEAR = 9729;
  static const int GL_NEAREST_MIPMAP_NEAREST = 9984;
  static const int GL_LINEAR_MIPMAP_NEAREST = 9985;
  static const int GL_NEAREST_MIPMAP_LINEAR = 9986;
  static const int GL_LINEAR_MIPMAP_LINEAR = 9987;
  static const int GL_REPEAT = 10497;
  static const int GL_CLAMP_TO_EDGE = 33071;
  static const int GL_MIRRORED_REPEAT = 33648;
  static const int GL_TEXTURE_MIN_FILTER = 10241;

  static gpu.SamplerOptions getSampler([Texture? text]){
    if(text == null){
      return gpu.SamplerOptions();
    }
    final GpuFilterPair minf = fromGlMinFilter(text.minFilter);

    return gpu.SamplerOptions(
      minFilter: minf.minFilter,
      magFilter: fromGlMagFilter(text.magFilter),
      mipFilter: minf.mipFilter, 
      widthAddressMode: fromGlWrapMode(text.wrapS),
      heightAddressMode: fromGlWrapMode(text.wrapT),
    );
  }

  /// Converts OpenGL `GL_TEXTURE_MIN_FILTER` values to a Flutter GPU pair.
  static GpuFilterPair fromGlMinFilter(int glValue) {
    switch (glValue) {
      case GL_NEAREST:
        return const GpuFilterPair(gpu.MinMagFilter.nearest, gpu.MipFilter.nearest);
      case GL_LINEAR:
        return const GpuFilterPair(gpu.MinMagFilter.linear, gpu.MipFilter.nearest);
      case GL_NEAREST_MIPMAP_NEAREST:
        return const GpuFilterPair(gpu.MinMagFilter.nearest, gpu.MipFilter.nearest);
      case GL_LINEAR_MIPMAP_NEAREST:
        return const GpuFilterPair(gpu.MinMagFilter.linear, gpu.MipFilter.nearest);
      case GL_NEAREST_MIPMAP_LINEAR:
        return const GpuFilterPair(gpu.MinMagFilter.nearest, gpu.MipFilter.linear);
      case GL_TEXTURE_MIN_FILTER:
      case GL_LINEAR_MIPMAP_LINEAR:
      default:
        return const GpuFilterPair(gpu.MinMagFilter.linear, gpu.MipFilter.linear);
    }
  }

  /// Converts OpenGL `GL_TEXTURE_MAG_FILTER` values to a Flutter GPU filter enum.
  static gpu.MinMagFilter fromGlMagFilter(int glValue) {
    switch (glValue) {
      case GL_NEAREST:
        return gpu.MinMagFilter.nearest;
      case GL_LINEAR:
      default:
        return gpu.MinMagFilter.linear;
    }
  }

  static gpu.SamplerAddressMode fromGlWrapMode(int glValue) {
    switch (glValue) {
      case GL_REPEAT:
        return gpu.SamplerAddressMode.repeat;
      case GL_MIRRORED_REPEAT:
        return gpu.SamplerAddressMode.mirror;
      case GL_CLAMP_TO_EDGE:
      default:
        return gpu.SamplerAddressMode.clampToEdge;
    }
  }
}