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
  skinIndex,
  skinWeight,
}

class GeometryBindings{
  final gpux.GpuContext context;
  final Object3D object;
  final BufferGeometry geometry;
  final MaterialDescriptor descriptor;
  final Material material;
  final Map<String, GpuGeometryBuffers> _cachedBuffer = {};

  GeometryBindings(
    this.context, 
    this.object,
    this.geometry,
    this.material,
    this.descriptor,
  );

  void bind(
    gpux.RenderPass pass,
    gpux.Shader vertex,
    gpux.Shader fragment,
    Float32List sceneData,
    Float32List materialData,
  ){
    final GpuGeometryBuffers? hardwareBuffers = _createHardwareBuffers(material);
    if (hardwareBuffers == null) return;

    final gpux.HostBuffer host = context.createHostBuffer();
    _bindUniforms(host, pass, vertex, fragment, sceneData, materialData);
    _bindTextures(pass,vertex,fragment);

    // Bind and draw using the correct calculated indices count
    pass.bindVertexBuffer( host.emplace(hardwareBuffers.vertexBuffer), hardwareBuffers.vertexCount);
    if(hardwareBuffers.indexCount != 0) pass.bindIndexBuffer( host.emplace(hardwareBuffers.indexBuffer), hardwareBuffers.indexType, hardwareBuffers.indexCount);
  }

  void _bindTextures(
    gpux.RenderPass pass,
    gpux.Shader vertex,
    gpux.Shader fragment
  ){
    final List<TextureType> activeBindings = descriptor.bindings;

    // ========================================================
    // 1. VERTEX SHADER PIPELINE BINDINGS
    // ========================================================
    if (material.displacementMap != null && activeBindings.contains(TextureType.displacementMap)) {
      final texture = _createTexture(material.displacementMap!.image);
      final texSlot = vertex.getUniformSlot('displacementMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.displacementMap!));
    }
    
    if (object is SkinnedMesh && object.skeleton != null && activeBindings.contains(TextureType.boneTexture)) {
      final skeleton = object.skeleton!;
      if (skeleton.boneTexture == null ) skeleton.computeBoneTexture();

      final texture = _createTexture(skeleton.boneTexture!.image);
      final texSlot = vertex.getUniformSlot('boneTexture');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(skeleton.boneTexture!));
    }
    
    // ========================================================
    // 2. FRAGMENT SHADER PIPELINE BINDINGS
    // ========================================================
    if(material.map != null && descriptor.bindings.contains(TextureType.map)){
      final texture = _createTexture(material.map!.image);
      final texSlot = fragment.getUniformSlot('map');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.map!));
    }

    if(material.alphaMap != null && descriptor.bindings.contains(TextureType.alphaMap)){
      final texture = _createTexture(material.alphaMap!.image);
      final texSlot = fragment.getUniformSlot('alphaMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.alphaMap!));
    }

    if(material.normalMap != null && descriptor.bindings.contains(TextureType.normalMap)){
      final texture = _createTexture(material.normalMap!.image);
      final texSlot = fragment.getUniformSlot('normalMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.normalMap!));
    }

    if(material.bumpMap != null && descriptor.bindings.contains(TextureType.bumpMap)){
      final texture = _createTexture(material.bumpMap!.image);
      final texSlot = fragment.getUniformSlot('bumpMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.bumpMap!));
    }

    if(
      (material.roughnessMap != null || 
      material.metalnessMap != null || 
      material.aoMap != null) &&
      (
        descriptor.bindings.contains(TextureType.roughnessMap) ||
        descriptor.bindings.contains(TextureType.metalnessMap) ||
        descriptor.bindings.contains(TextureType.aoMap)
      )
    ){
      final ImageElement? ieo = material.aoMap?.image;
      final ImageElement? ier = material.roughnessMap?.image;
      final ImageElement? iem = material.metalnessMap?.image;

      final o = ieo?.data as Uint8List?;
      final r = ier?.data as Uint8List?;
      final m = iem?.data as Uint8List?;
      final int l = o?.length ?? r?.length ?? m?.length ?? 0;

      final int w = (ieo?.width ?? ier?.width ?? iem?.width ?? 0).toInt();
      final int h = (ieo?.height ?? ier?.height ?? iem?.height ?? 0).toInt();

      final int totalPixels = w * h;
      final Uint8List packedData = Uint8List(totalPixels * 4);

      // 3. FIXED: Robust multi-stride unpacking.
      // This automatically adjusts if three.js textures use 3 or 4 components natively.
      final int oStride = (o != null && o.length >= totalPixels * 4) ? 4 : 3;
      final int rStride = (r != null && r.length >= totalPixels * 4) ? 4 : 3;
      final int mStride = (m != null && m.length >= totalPixels * 4) ? 4 : 3;

      for (int i = 0; i < totalPixels; i++) {
        int outIdx = i * 4;

        // Red Channel = Ambient Occlusion (Defaults to full white if missing)
        packedData[outIdx + 0] = o != null ? o[i * oStride + 0] : 255;
        
        // Green Channel = Roughness (Three.js standard reads green)
        // If your roughness maps are purely grayscale single-channel, reading component +0 is completely safe
        packedData[outIdx + 1] = r != null ? r[i * rStride + 0] : 255;
        
        // Blue Channel = Metalness (Three.js standard reads blue)
        packedData[outIdx + 2] = m != null ? m[i * mStride + 0] : 0;
        
        // Alpha Channel = Padding required by Vulkan/Metal formats
        packedData[outIdx + 3] = 255; 
      }

      final texture = _createTexture(
        ImageElement(
          data: packedData,
          width: w,
          height: h
        )
      );
      final texSlot = fragment.getUniformSlot('ormMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.aoMap ?? material.roughnessMap ?? material.metalnessMap!));
    }

    if(material.specularMap != null && descriptor.bindings.contains(TextureType.specularMap)){
      final texture = _createTexture(material.specularMap!.image);
      final texSlot = fragment.getUniformSlot('specularMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.specularMap!));
    }

    if(material.lightMap != null && descriptor.bindings.contains(TextureType.lightMap)){
      final texture = _createTexture(material.lightMap!.image);
      final texSlot = fragment.getUniformSlot('lightMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.lightMap!));
    }

    if(material.emissiveMap != null && descriptor.bindings.contains(TextureType.emissiveMap)){
      final texture = _createTexture(material.emissiveMap!.image);
      final texSlot = fragment.getUniformSlot('emissiveMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.emissiveMap!));
    }


    if(material.clearcoatNormalMap != null && descriptor.bindings.contains(TextureType.clearcoatNormalMap)){
      final texture = _createTexture(material.clearcoatNormalMap!.image);
      final texSlot = fragment.getUniformSlot('clearcoatNormalMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.clearcoatNormalMap!));
    }

    if ((material.clearcoatMap != null || material.clearcoatRoughnessMap != null) &&
        (descriptor.bindings.contains(TextureType.clearcoatMap) ||
        descriptor.bindings.contains(TextureType.clearcoatRoughnessMap))) {
      
      final ImageElement? iec = material.clearcoatMap?.image;
      final ImageElement? ier = material.clearcoatRoughnessMap?.image;

      final c = iec?.data as Uint8List?;
      final r = ier?.data as Uint8List?;

      final int w = (iec?.width ?? ier?.width ?? 0).toInt();
      final int h = (iec?.height ?? ier?.height ?? 0).toInt();
      
      final int totalPixels = w * h;
      final Uint8List packedData = Uint8List(totalPixels * 4);

      final int cStride = (c != null && c.length >= totalPixels * 4) ? 4 : 3;
      final int rStride = (r != null && r.length >= totalPixels * 4) ? 4 : 3;

      for (int i = 0; i < totalPixels; i++) {
        int outIdx = i * 4;

        // Red Channel = Clearcoat Intensity Factor (Default to 0 if missing)
        packedData[outIdx + 0] = c != null ? c[i * cStride + 0] : 0;
        
        // Green Channel = Clearcoat Roughness Vector (Default to full rough if missing)
        packedData[outIdx + 1] = r != null ? r[i * rStride + 0] : 255;
        
        // Blue & Alpha = Standard padding bytes required by the hardware backend
        packedData[outIdx + 2] = 255;
        packedData[outIdx + 3] = 255; 
      }

      final texture = _createTexture(ImageElement(data: packedData, width: w, height: h));
      
      final texSlot = fragment.getUniformSlot('clearcoatParamsMap');
      
      final targetMap = material.clearcoatMap ?? material.clearcoatRoughnessMap!;
      final sampler = GpuSamplerConverter.getSampler(targetMap);

      pass.bindTexture(texSlot, texture, sampler: sampler);
    }

    if(material.sheenColorMap != null && descriptor.bindings.contains(TextureType.sheenColorMap)){
      final texture = _createTexture(material.sheenColorMap!.image);
      final texSlot = fragment.getUniformSlot('sheenColorMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.sheenColorMap!));
    }

    if(material.sheenRoughnessMap != null && descriptor.bindings.contains(TextureType.sheenRoughnessMap)){
      final texture = _createTexture(material.sheenRoughnessMap!.image);
      final texSlot = fragment.getUniformSlot('sheenRoughnessMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.sheenRoughnessMap!));
    }

    if ((material.transmissionMap != null || material.thicknessMap != null || material.iridescenceMap != null) &&
        (descriptor.bindings.contains(TextureType.transmissionMap) ||
        descriptor.bindings.contains(TextureType.thicknessMap) ||
        descriptor.bindings.contains(TextureType.iridescenceMap))) {
      
      final ImageElement? iet = material.transmissionMap?.image;
      final ImageElement? ieh = material.thicknessMap?.image;
      final ImageElement? iei = material.iridescenceMap?.image;

      final t = iet?.data as Uint8List?;
      final h = ieh?.data as Uint8List?;
      final r = iei?.data as Uint8List?;

      final int w = (iet?.width ?? ieh?.width ?? iei?.width ?? 0).toInt();
      final int hDim = (iet?.height ?? ieh?.height ?? iei?.height ?? 0).toInt();
      
      final int totalPixels = w * hDim;
      final Uint8List packedData = Uint8List(totalPixels * 4);

      final int tStride = (t != null && t.length >= totalPixels * 4) ? 4 : 3;
      final int hStride = (h != null && h.length >= totalPixels * 4) ? 4 : 3;
      final int rStride = (r != null && r.length >= totalPixels * 4) ? 4 : 3;

      for (int i = 0; i < totalPixels; i++) {
        int outIdx = i * 4;

        // Red Channel = Transmission Intensity (Default to 0 if missing)
        packedData[outIdx + 0] = t != null ? t[i * tStride + 0] : 0;
        
        // Green Channel = Volumetric Thickness Scale (Default to full white if missing)
        packedData[outIdx + 1] = h != null ? h[i * hStride + 0] : 255;
        
        // Blue Channel = Thin-Film Iridescence Intensity (Default to 0 if missing)
        packedData[outIdx + 2] = r != null ? r[i * rStride + 0] : 0;
        
        // Alpha Channel = Structural hardware pad vector
        packedData[outIdx + 3] = 255; 
      }

      final texture = _createTexture(ImageElement(data: packedData, width: w, height: hDim));
      
      // Connects directly to uniform sampler2D advancedPhysicalMap inside physical.frag
      final texSlot = fragment.getUniformSlot('advancedPhysicalMap');
      
      final targetMap = material.transmissionMap ?? material.thicknessMap ?? material.iridescenceMap!;
      final sampler = GpuSamplerConverter.getSampler(targetMap);

      pass.bindTexture(texSlot, texture, sampler: sampler);
    }

    if(material.iridescenceThicknessMap != null && descriptor.bindings.contains(TextureType.iridescenceThicknessMap)){
      final texture = _createTexture(material.iridescenceThicknessMap!.image);
      final texSlot = fragment.getUniformSlot('iridescenceThicknessMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.iridescenceThicknessMap!));
    }

    if(material.gradientMap != null && descriptor.bindings.contains(TextureType.gradientMap)){
      final texture = _createTexture(material.gradientMap!.image);
      final texSlot = fragment.getUniformSlot('gradientMap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.gradientMap!));
    }

    if(material.matcap != null && descriptor.bindings.contains(TextureType.matcap)){
      final texture = _createTexture(material.matcap!.image);
      final texSlot = fragment.getUniformSlot('matcap');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(material.matcap!));
    }
  }

  gpux.Texture _createTexture(ImageElement element){
    if(_cachedTextures.containsKey(element.uuid)){
      return _cachedTextures[element.uuid]!;
    }
    
    final sampledTexture = context.createTexture(
      gpux.StorageMode.hostVisible,
      element.width.toInt(), 
      element.height.toInt(),
      sampleCount: 1,
      //textureType: gpux.TextureType.texture2D,
      format: element.data is Uint8List?gpux.PixelFormat.r8g8b8a8UNormInt:gpux.PixelFormat.r32g32b32a32Float,
      enableShaderReadUsage: true
    );
    element.uuid = MathUtils.generateUUID();
    _cachedTextures[element.uuid!] = sampledTexture;

    if(element.data != null) sampledTexture.overwrite(element.data.buffer.asByteData());

    return sampledTexture;
  }

  Map<String,gpux.Texture> _cachedTextures = {};


  void _bindUniforms(
    gpux.HostBuffer host,
    gpux.RenderPass pass,
    gpux.Shader vertex,
    gpux.Shader fragment,
    Float32List sceneData,
    Float32List materialData,
  ){
    // Emplace raw Float32 data segments straight into the host-visible staging memory
    final gpux.BufferView sceneBufferView = host.emplace(sceneData.buffer.asByteData());
    final gpux.BufferView materialBufferView = host.emplace(materialData.buffer.asByteData());

    //Map uniform buffer blocks to specific shader string properties
    final sceneSlotVertex = vertex.getUniformSlot('SceneBlock');
    final materialSlotVertex = vertex.getUniformSlot('MaterialBlock');

    final sceneSlotFragment = fragment.getUniformSlot('SceneBlock');
    final materialSlotFragment = fragment.getUniformSlot('MaterialBlock');
    
    if (sceneSlotVertex.sizeInBytes != null) {
      pass.bindUniform(sceneSlotVertex, sceneBufferView);
    }
    if (materialSlotVertex.sizeInBytes != null) {
      pass.bindUniform(materialSlotVertex, materialBufferView);
    }
    if (sceneSlotFragment.sizeInBytes != null) {
      pass.bindUniform(sceneSlotFragment, sceneBufferView);
    }
    if (materialSlotFragment.sizeInBytes != null) {
      pass.bindUniform(materialSlotFragment, materialBufferView);
    }
  }

  GpuGeometryBuffers? _createHardwareBuffers(Material material) {
    String uuid = '${material.uuid}_${geometry.uuid}';
    if(_cachedBuffer[uuid] != null && _cachedBuffer[uuid]!.version == material.version){
      return _cachedBuffer[uuid];
    }

    final positionAttr = geometry.attributes['position'] as BufferAttribute?;
    final tangetAttr = geometry.attributes['tanget'] as BufferAttribute?;
    final normalAttr = geometry.attributes['normal'] as BufferAttribute?;
    final uv0Attr = geometry.attributes['uv'] as BufferAttribute?;
    final uv1Attr = geometry.attributes['uv1'] as BufferAttribute?;
    final colorAttr = geometry.attributes['color'] as BufferAttribute?;
    final skinIndexAttr = geometry.attributes['skinIndex'] as BufferAttribute?;
    final skinWeightAttr = geometry.attributes['skinWeight'] as BufferAttribute?;
    final indexAttr = geometry.index;
    
    if (
      positionAttr == null
    ){
      return null;
    }

    final int totalVertices = positionAttr.count;
    int totalIndex = 0;
    bool overwrite = false;

    if(
      indexAttr == null //&&
      // material is! LineDashedMaterial &&
      // geometry is! LineSegments &&
      // material is! LineBasicMaterial
    ){
      overwrite = true;
      totalIndex = totalVertices;
    }

    // ========================================================
    // 1. COMPILE-SAFE INDEX EXTRACTION
    // ========================================================
    // Direct cast to Uint16List represents only this mesh slice's data bounds
    final TypedDataList indices = (indexAttr != null) 
        ? indexAttr.array// Safely converts Uint32List or standard List<int>
        : Uint16List(totalVertices);

    // ========================================================
    // 2. INTERLEAVE ATTRIBUTES USING COUNT (Fixes Overlapping Triangles)
    // ========================================================
    final Float32List positions = positionAttr.array.buffer.asFloat32List();
    final Float32List? normals = normalAttr?.array.buffer.asFloat32List();
    final Float32List? colors = colorAttr?.array.buffer.asFloat32List();
    final Float32List? uvs0 = uv0Attr?.array.buffer.asFloat32List();
    final Float32List? uvs1 = uv1Attr?.array.buffer.asFloat32List();
    final Float32List? skinIndices = skinIndexAttr?.array.buffer.asFloat32List();
    final Float32List? skinWeights = skinWeightAttr?.array.buffer.asFloat32List();

    final attri = descriptor.requiredAttributes; 

    // 1. Calculate individual starting float offsets and the total vertex stride
    int stride = 3; // Position is always first and takes 3 floats
    final int colorItemSize = colorAttr?.itemSize ?? 3;
    final Map<GeometryAttribute, int> attributeOffsets = {};

    if (attri.contains(GeometryAttribute.normal)) {
      attributeOffsets[GeometryAttribute.normal] = stride;
      stride += 3;
    }
    if (attri.contains(GeometryAttribute.uv0)) {
      attributeOffsets[GeometryAttribute.uv0] = stride;
      stride += 2;
    }
    if (attri.contains(GeometryAttribute.uv1)) {
      attributeOffsets[GeometryAttribute.uv1] = stride;
      stride += 2;
    }
    if (attri.contains(GeometryAttribute.color)) {
      attributeOffsets[GeometryAttribute.color] = stride;
      stride += 3;
    }
    if (attri.contains(GeometryAttribute.skinIndex)) {
      attributeOffsets[GeometryAttribute.skinIndex] = stride;
      stride += 4;
    }
    if (attri.contains(GeometryAttribute.skinWeight)) {
      attributeOffsets[GeometryAttribute.skinWeight] = stride;
      stride += 4;
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
      // If explicit UVs exist, map them normally
      interleavedData[vertexStride + offset + 0] = uvs0?[i * 2 + 0] ?? 0.0;
      interleavedData[vertexStride + offset + 1] = uvs0?[i * 2 + 1] ?? 0.0;
    }

    void _uv1(int i, int offset) {
      interleavedData[vertexStride + offset + 0] = uvs1?[i * 2 + 0] ?? 0.0; // Fixed: Reads from uvs1
      interleavedData[vertexStride + offset + 1] = uvs1?[i * 2 + 1] ?? 0.0;
    }

    void _colors(int i, int offset) {
      interleavedData[vertexStride + offset + 0] = ((colors?.length ?? 0) > i*colorItemSize?(colors?[i * colorItemSize + 0]):null) ?? material.color.red;
      interleavedData[vertexStride + offset + 1] = ((colors?.length ?? 0) > i*colorItemSize+1?(colors?[i * colorItemSize + 1]):null) ?? material.color.green;
      interleavedData[vertexStride + offset + 2] = ((colors?.length ?? 0) > i*colorItemSize+2?(colors?[i * colorItemSize + 2]):null) ?? material.color.blue;
    }

    void _skinIndex(int i, int offset) {
      // itemSize for skin indices is always 4
      interleavedData[vertexStride + offset + 0] = ((skinIndices?.length ?? 0) > i * 4 + 0 ? (skinIndices?[i * 4 + 0]) : null) ?? 0.0;
      interleavedData[vertexStride + offset + 1] = ((skinIndices?.length ?? 0) > i * 4 + 1 ? (skinIndices?[i * 4 + 1]) : null) ?? 0.0;
      interleavedData[vertexStride + offset + 2] = ((skinIndices?.length ?? 0) > i * 4 + 2 ? (skinIndices?[i * 4 + 2]) : null) ?? 0.0;
      interleavedData[vertexStride + offset + 3] = ((skinIndices?.length ?? 0) > i * 4 + 3 ? (skinIndices?[i * 4 + 3]) : null) ?? 0.0;
    }

    void _skinWeight(int i, int offset) {
      // itemSize for skin weights is always 4
      // Note: Channel 0 defaults to 1.0 so unskinned vertices bind to the first root bone instead of collapsing to scale 0
      interleavedData[vertexStride + offset + 0] = ((skinWeights?.length ?? 0) > i * 4 + 0 ? (skinWeights?[i * 4 + 0]) : null) ?? 1.0;
      interleavedData[vertexStride + offset + 1] = ((skinWeights?.length ?? 0) > i * 4 + 1 ? (skinWeights?[i * 4 + 1]) : null) ?? 0.0;
      interleavedData[vertexStride + offset + 2] = ((skinWeights?.length ?? 0) > i * 4 + 2 ? (skinWeights?[i * 4 + 2]) : null) ?? 0.0;
      interleavedData[vertexStride + offset + 3] = ((skinWeights?.length ?? 0) > i * 4 + 3 ? (skinWeights?[i * 4 + 3]) : null) ?? 0.0;
    }

    // 3. Execution Loop
    for (int i = 0; i < totalVertices; i++) {
      _position(i);

      if (attri.contains(GeometryAttribute.normal)) {
        _normal(i, attributeOffsets[GeometryAttribute.normal]!);
      }
      
      if (uvs0 != null && attri.contains(GeometryAttribute.uv0)) {
        _uv0(i, attributeOffsets[GeometryAttribute.uv0]!);
      }

      if (attri.contains(GeometryAttribute.uv1)) {
        _uv1(i, attributeOffsets[GeometryAttribute.uv1]!);
      }

      if (attri.contains(GeometryAttribute.color)) {
        _colors(i, attributeOffsets[GeometryAttribute.color]!);
      }

      if (attri.contains(GeometryAttribute.skinIndex)) {
        _skinIndex(i, attributeOffsets[GeometryAttribute.skinIndex]!);
      }
      
      if (attri.contains(GeometryAttribute.skinWeight)) {
        _skinWeight(i, attributeOffsets[GeometryAttribute.skinWeight]!);
      }


      vertexStride += stride; // Advance by the correct total float stride

      if(overwrite){
        indices[i] = i;
      }
    }

    final ByteData rawVertices = interleavedData.buffer.asByteData();

    _cachedBuffer[uuid] = GpuGeometryBuffers(
      vertexBuffer: rawVertices,
      indexBuffer: indices.buffer.asByteData(),
      indexCount: indexAttr?.count ?? totalIndex, // Total active item connections
      vertexCount: totalVertices,  // Use total unique physical vertices
      version: material.version,
      indexType: indices is Uint32List || indices is Int32List?gpux.IndexType.int32:gpux.IndexType.int16
    );

    return _cachedBuffer[uuid];
  }
}

class GpuGeometryBuffers {
  GpuGeometryBuffers({
    required this.vertexBuffer,
    required this.indexBuffer,
    required this.indexCount,
    required this.vertexCount,
    required this.version,
    required this.indexType
  });

  final ByteData vertexBuffer;
  final ByteData indexBuffer;
  final int indexCount;
  final int vertexCount;
  final int version;
  final gpux.IndexType indexType;
}

class GpuFilterPair {
  final gpux.MinMagFilter minFilter;
  final gpux.MipFilter mipFilter;
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

  static gpux.SamplerOptions getSampler(Texture text){
    final GpuFilterPair minf = fromGlMinFilter(text.minFilter);

    return gpux.SamplerOptions(
      // minFilter: minf.minFilter,
      // magFilter: fromGlMagFilter(text.magFilter),
      // mipFilter: minf.mipFilter, 
      // widthAddressMode: fromGlWrapMode(text.wrapS),
      // heightAddressMode: fromGlWrapMode(text.wrapT),
    );
  }

  /// Converts OpenGL `GL_TEXTURE_MIN_FILTER` values to a Flutter GPU pair.
  static GpuFilterPair fromGlMinFilter(int glValue) {
    switch (glValue) {
      case GL_NEAREST:
        return const GpuFilterPair(gpux.MinMagFilter.nearest, gpux.MipFilter.nearest);
      case GL_LINEAR:
        return const GpuFilterPair(gpux.MinMagFilter.linear, gpux.MipFilter.nearest);
      case GL_NEAREST_MIPMAP_NEAREST:
        return const GpuFilterPair(gpux.MinMagFilter.nearest, gpux.MipFilter.nearest);
      case GL_LINEAR_MIPMAP_NEAREST:
        return const GpuFilterPair(gpux.MinMagFilter.linear, gpux.MipFilter.nearest);
      case GL_NEAREST_MIPMAP_LINEAR:
        return const GpuFilterPair(gpux.MinMagFilter.nearest, gpux.MipFilter.linear);
      case GL_TEXTURE_MIN_FILTER:
      case GL_LINEAR_MIPMAP_LINEAR:
      default:
        return const GpuFilterPair(gpux.MinMagFilter.linear, gpux.MipFilter.linear);
    }
  }

  /// Converts OpenGL `GL_TEXTURE_MAG_FILTER` values to a Flutter GPU filter enum.
  static gpux.MinMagFilter fromGlMagFilter(int glValue) {
    switch (glValue) {
      case GL_NEAREST:
        return gpux.MinMagFilter.nearest;
      case GL_LINEAR:
      default:
        return gpux.MinMagFilter.linear;
    }
  }

  static gpux.SamplerAddressMode fromGlWrapMode(int glValue) {
    switch (glValue) {
      case GL_REPEAT:
        return gpux.SamplerAddressMode.repeat;
      case GL_MIRRORED_REPEAT:
        return gpux.SamplerAddressMode.mirror;
      case GL_CLAMP_TO_EDGE:
      default:
        return gpux.SamplerAddressMode.clampToEdge;
    }
  }
}