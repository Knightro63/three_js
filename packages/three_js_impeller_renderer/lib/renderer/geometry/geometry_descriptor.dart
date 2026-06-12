import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_impeller_renderer/renderer/material/material_description_registry.dart';
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
  lineDistance,
  pointSize
}

class GeometryBindings{
  final gpux.GpuContext context;
  final BufferGeometry geometry;
  final MaterialDescriptor descriptor;
  final Material material;

  GeometryBindings(
    this.context, 
    this.geometry,
    this.material,
    this.descriptor
  );

  void bind(
    gpux.RenderPass pass,
    gpux.Shader vertex,
    Float32List sceneData,
    Float32List materialData,
  ){
    final gpux.HostBuffer host = context.createHostBuffer();
    final GpuGeometryBuffers? hardwareBuffers = _createHardwareBuffers();//_geometryCache.getOrCreate(geometry);
    if (hardwareBuffers == null) return;

    // Bind and draw using the correct calculated indices count
    pass.bindVertexBuffer( host.emplace(hardwareBuffers.vertexBuffer), hardwareBuffers.vertexCount);
    pass.bindIndexBuffer( host.emplace(hardwareBuffers.indexBuffer), gpux.IndexType.int16, hardwareBuffers.indexCount);
  
    _bindUniforms(host, pass, vertex, sceneData, materialData);
  }

  void _bindUniforms(
    gpux.HostBuffer host,
    gpux.RenderPass pass,
    gpux.Shader vertex,
    Float32List sceneData,
    Float32List materialData,
  ){
    // Emplace raw Float32 data segments straight into the host-visible staging memory
    final gpux.BufferView sceneBufferView = host.emplace(sceneData.buffer.asByteData());    
    final gpux.BufferView materialBufferView = host.emplace(materialData.buffer.asByteData());

    //Map uniform buffer blocks to specific shader string properties
    final sceneSlotVertex = vertex.getUniformSlot('SceneBlock');
    final materialSlotVertex = vertex.getUniformSlot('MaterialBlock'); // Add this for the Vertex transform!

    pass.bindUniform(sceneSlotVertex, sceneBufferView);
    pass.bindUniform(materialSlotVertex, materialBufferView); // Feeds modelMatrix to vertex shader
  }

  GpuGeometryBuffers? _createHardwareBuffers() {
    final positionAttr = geometry.attributes['position'] as BufferAttribute?;
    final normalAttr = geometry.attributes['normal'] as BufferAttribute?;
    final uv0Attr = geometry.attributes['uv'] as BufferAttribute?;
    final uv1Attr = geometry.attributes['uv1'] as BufferAttribute?;
    final colorAttr = geometry.attributes['color'] as BufferAttribute?;
    final indexAttr = geometry.index;
    
    if (positionAttr == null || indexAttr == null) return null;

    // ========================================================
    // 1. COMPILE-SAFE INDEX EXTRACTION
    // ========================================================
    // Direct cast to Uint16List represents only this mesh slice's data bounds
    final Uint16List indices = indexAttr.array as Uint16List;
    final ByteData rawIndex = indices.buffer.asByteData();

    // ========================================================
    // 2. INTERLEAVE ATTRIBUTES USING COUNT (Fixes Overlapping Triangles)
    // ========================================================
    final Float32List positions = positionAttr.array as Float32List;
    final Float32List? normals = normalAttr?.array as Float32List?;
    final Float32List? colors = colorAttr?.array as Float32List?;
    final Float32List? uvs0 = uv0Attr?.array as Float32List?;
    final Float32List? uvs1 = uv1Attr?.array as Float32List?;
    final int totalVertices = positionAttr.count; 

    final attri = descriptor.requiredAttributes; 

    // 1. Calculate individual starting float offsets and the total vertex stride
    int stride = 3; // Position is always first and takes 3 floats
    final Map<GeometryAttribute, int> attributeOffsets = {};

    if (attri.contains(GeometryAttribute.normal)) {
      attributeOffsets[GeometryAttribute.normal] = stride;
      stride += 3; // vec3 normal
    }
    if (attri.contains(GeometryAttribute.uv0)) {
      attributeOffsets[GeometryAttribute.uv0] = stride;
      stride += 2; // vec2 uv0
    }
    if (attri.contains(GeometryAttribute.uv1)) {
      attributeOffsets[GeometryAttribute.uv1] = stride;
      stride += 2; // vec2 uv1
    }
    if (attri.contains(GeometryAttribute.color)) {
      attributeOffsets[GeometryAttribute.color] = stride;
      stride += 3; // vec4 color (RGBA)
    }

    final Float32List interleavedData = Float32List(totalVertices * stride);
    int vertexStride = 0;

    // 2. Updated data helpers targeting exact, correct array pools and clean alignments
    void _position(int i) {
      interleavedData[vertexStride + 0] = positions[i * 3 + 0];
      interleavedData[vertexStride + 1] = positions[i * 3 + 1];
      interleavedData[vertexStride + 2] = positions[i * 3 + 2];
    }

    void _normal(int i, int offset) {
      interleavedData[vertexStride + offset + 0] = normals?[i * 3 + 0] ?? 0.0;
      interleavedData[vertexStride + offset + 1] = normals?[i * 3 + 1] ?? 0.0;
      interleavedData[vertexStride + offset + 2] = normals?[i * 3 + 2] ?? 0.0;
    }

    void _uv0(int i, int offset) {
      interleavedData[vertexStride + offset + 0] = uvs0?[i * 2 + 0] ?? 0.0; // Fixed: Reads from uvs0
      interleavedData[vertexStride + offset + 1] = uvs0?[i * 2 + 1] ?? 0.0;
    }

    void _uv1(int i, int offset) {
      interleavedData[vertexStride + offset + 0] = uvs1?[i * 2 + 0] ?? 0.0; // Fixed: Reads from uvs1
      interleavedData[vertexStride + offset + 1] = uvs1?[i * 2 + 1] ?? 0.0;
    }

    void _colors(int i, int offset) {
      interleavedData[vertexStride + offset + 0] = colors?[i * 3 + 0] ?? 1.0; // Fixed: 4 components (RGBA)
      interleavedData[vertexStride + offset + 1] = colors?[i * 3 + 1] ?? 1.0;
      interleavedData[vertexStride + offset + 2] = colors?[i * 3 + 2] ?? 1.0;
      //interleavedData[vertexStride + offset + 3] = colors?[i * 4 + 3] ?? 1.0;
    }

    // 3. Execution Loop
    for (int i = 0; i < totalVertices; i++) {
      _position(i);

      if (attri.contains(GeometryAttribute.normal)) {
        _normal(i, attributeOffsets[GeometryAttribute.normal]!);
      }
      if (attri.contains(GeometryAttribute.uv0)) {
        _uv0(i, attributeOffsets[GeometryAttribute.uv0]!);
      }
      if (attri.contains(GeometryAttribute.uv1)) {
        _uv1(i, attributeOffsets[GeometryAttribute.uv1]!);
      }
      if (attri.contains(GeometryAttribute.color)) {
        _colors(i, attributeOffsets[GeometryAttribute.color]!);
      }

      vertexStride += stride; // Advance by the correct total float stride
    }

    final ByteData rawVertices = interleavedData.buffer.asByteData();

    return GpuGeometryBuffers(
      vertexBuffer: rawVertices,
      indexBuffer: rawIndex,
      indexCount: indexAttr.count, // Total active item connections
      vertexCount: positionAttr.count,  // Use total unique physical vertices
    );
  }
}

class GpuGeometryBuffers {
  GpuGeometryBuffers({
    required this.vertexBuffer,
    required this.indexBuffer,
    required this.indexCount,
    required this.vertexCount
  });

  final ByteData vertexBuffer;
  final ByteData indexBuffer;
  final int indexCount;
  final int vertexCount;
}