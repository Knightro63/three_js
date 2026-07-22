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
  instanceId,
}

class GeometryBindings{
  final gpux.GpuContext context;
  final Object3D object;
  final BufferGeometry geometry;
  final MaterialDescriptor descriptor;
  final Material material;

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
    final bool isInstanced = object is InstancedMesh;
    final int instanceCount = isInstanced ? (object.count ?? 1) : 1;

    final GpuGeometryBuffers? hardwareBuffers = _createHardwareBuffers(instanceCount);
    if (hardwareBuffers == null) return;

    final gpux.HostBuffer host = context.createHostBuffer();
    _bindMaterialUniforms(host, pass, vertex, fragment ,materialData);
    if(descriptor.useSceneData){
      _bindSceneUniforms(host, pass, vertex, fragment, sceneData);
    }
    _bindTextures(pass,vertex,fragment);

    bool needsUpdate = hardwareBuffers.needsUpdate;
    String uuidVert = '${material.uuid}_${geometry.uuid}_vert';
    String uuidIndex = '${material.uuid}_${geometry.uuid}_index';

    if(material.userData[uuidVert] == null || needsUpdate){
      material.userData[uuidVert] = host.emplace(hardwareBuffers.vertexBuffer);
    }
    if(material.userData[uuidIndex] == null || needsUpdate){
      material.userData[uuidIndex] = host.emplace(hardwareBuffers.indexBuffer);
    }

    void bind(int i,bool isInstance){
      pass.bindVertexBuffer( 
        material.userData[uuidVert], 
        hardwareBuffers.vertexCount
      );
      if(hardwareBuffers.indexCount != 0){
        pass.bindIndexBuffer( 
          material.userData[uuidIndex],
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
      if (skeleton.boneTexture == null ){
        skeleton.computeBoneTexture();
      }

      final text = skeleton.boneTexture!;
      final texture = _createTexture(text.image, '');
      final texSlot = vertex.getUniformSlot('unifiedTransformationTexture');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(text));
    }

    if (geometry.morphAttributes["position"] != null && activeBindings.contains(TextureType.morphTexture)) { // Reusing slot 2
      final morphPositions = geometry.morphAttributes["position"];

      if (morphPositions != null && morphPositions.isNotEmpty) {
        final int vertexCount = geometry.attributes["position"].count;
        final int morphTargetsCount = morphPositions.length;

        // 1. Define clean 2D Matrix dimensions: Columns = targets, Rows = unique vertices
        final int texWidth = morphTargetsCount;
        final int texHeight = vertexCount;

        // 2. Allocate flat contiguous Float32 list layout matching the grid exactly
        final Float32List morphBuffer = Float32List(texWidth * texHeight * 4);
        final _tempMorphVector = Vector4.zero(); // Reusable allocation guard

        // 3. Fast linear data transfer pass
        for (int vIdx = 0; vIdx < vertexCount; vIdx++) {
          final int rowOffset = vIdx * texWidth * 4;

          for (int tIdx = 0; tIdx < morphTargetsCount; tIdx++) {
            final BufferAttribute targetAttribute = morphPositions[tIdx];
            _tempMorphVector.fromBuffer(targetAttribute, vIdx);

            final int pixelOffset = rowOffset + (tIdx * 4);
            morphBuffer[pixelOffset + 0] = _tempMorphVector.x; // Delta X
            morphBuffer[pixelOffset + 1] = _tempMorphVector.y; // Delta Y
            morphBuffer[pixelOffset + 2] = _tempMorphVector.z; // Delta Z
            morphBuffer[pixelOffset + 3] = 0.0;                // Padding Channel
          }
        }

        final image = ImageElement(
          width: texWidth,
          height: texHeight,
          data: morphBuffer,
        );

        // 5. Upload and bind seamlessly to uniform slot layout index 2 (boneTexture)
        final texture = _createTexture(image, '');
        final texSlot = vertex.getUniformSlot('unifiedTransformationTexture'); // Reused target name
        pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler());
      }
    }

    if (object is InstancedMesh && 
        (object as InstancedMesh).instanceMatrix != null && 
        activeBindings.contains(TextureType.instanceTexture)
    ) {
      
      final data = (object as InstancedMesh).instanceMatrix!.array as Float32List;
      final color = (object as InstancedMesh).instanceColor?.array as Float32List?;

      const int floatsPerRow = 16; // 16 floats per row

      final int rawTotalFloats = data.length + (color?.length ?? 0); // e.g., 1000 floats
      final int texHeight = (rawTotalFloats / floatsPerRow).ceil();
      final int paddedTotalFloats = texHeight * floatsPerRow;
      final Float32List combined = Float32List(paddedTotalFloats); 

      combined.setAll(0, data);
      if (color != null) {
        combined.setAll(data.length, color);
      }

      final image = ImageElement(
        width: 4,
        height: texHeight, // 63
        data: combined,    // Now exactly 4,032 bytes!
      );
      final texture = _createTexture(image, '');
      final texSlot = vertex.getUniformSlot('instanceTexture');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler());
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
      String uuid = material.aoMap?.uuid ?? material.roughnessMap?.uuid ?? material.metalnessMap!.uuid;
      gpux.Texture? texture = material.userData[uuid];
      if(texture == null){
        final ImageElement? ieo = material.aoMap?.image;
        final ImageElement? ier = material.roughnessMap?.image;
        final ImageElement? iem = material.metalnessMap?.image;

        final o = ieo?.data as Uint8List?;
        final r = ier?.data as Uint8List?;
        final m = iem?.data as Uint8List?;
        //final int l = o?.length ?? r?.length ?? m?.length ?? 0;

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
        
        texture = _createTexture(
          ImageElement(
            data: packedData,
            width: w,
            height: h
          ),
          uuid
        );
      }
  
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
        descriptor.bindings.contains(TextureType.clearcoatRoughnessMap))
    ) {
      String uuid = material.clearcoatMap?.uuid ?? material.clearcoatRoughnessMap!.uuid;
      gpux.Texture? texture = material.userData[uuid];
      if(texture == null){
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

        texture = _createTexture(ImageElement(data: packedData, width: w, height: h));
      }

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

  gpux.Texture _createTexture(
    ImageElement element,
    [String? cacheName]
  ){
    //print(material.userData.keys.length);
    if(material.userData[element.uuid] != null){
      return material.userData[element.uuid]!;
    }
    
    final sampledTexture = context.createTexture(
      gpux.StorageMode.hostVisible,
      element.width.toInt(), 
      element.height.toInt(),
      sampleCount: 1,
      //textureType: gpux.TextureType.texture2D,
      format: element.data is Uint8List?
        gpux.PixelFormat.r8g8b8a8UNormInt:
        element.data is Float32List?
        gpux.PixelFormat.r32g32b32a32Float:gpux.PixelFormat.r16g16b16a16Float,
    );
    if(cacheName == null && element.uuid == null){
      element.uuid = MathUtils.generateUUID();
    }
    if(cacheName != '' && element.uuid != null){
      material.userData[element.uuid!] = sampledTexture;
    }

    if(element.data != null) sampledTexture.overwrite(element.data.buffer.asByteData());

    return sampledTexture;
  }

  void _bindMaterialUniforms(
    gpux.HostBuffer host,
    gpux.RenderPass pass,
    gpux.Shader vertex,
    gpux.Shader fragment,
    Float32List materialData,
  ){
    // Emplace raw Float32 data segments straight into the host-visible staging memory
    final gpux.BufferView materialBufferView = host.emplace(materialData.buffer.asByteData());

    //Map uniform buffer blocks to specific shader string properties
    final vertexSlot = vertex.getUniformSlot('MaterialBlock');
    final materialSlotFragment = fragment.getUniformSlot('MaterialBlock');
    
    if (vertexSlot.sizeInBytes != null) {
      pass.bindUniform(vertexSlot, materialBufferView);
    }
    if (materialSlotFragment.sizeInBytes != null) {
      pass.bindUniform(materialSlotFragment, materialBufferView);
    }
  }
  void _bindSceneUniforms(
    gpux.HostBuffer host,
    gpux.RenderPass pass,
    gpux.Shader vertex,
    gpux.Shader fragment,
    Float32List sceneData,
  ){
    // Emplace raw Float32 data segments straight into the host-visible staging memory
    final gpux.BufferView sceneBufferView = host.emplace(sceneData.buffer.asByteData());

    //Map uniform buffer blocks to specific shader string properties
    final sceneSlotFragment = fragment.getUniformSlot('SceneBlock');
    
    if (sceneSlotFragment.sizeInBytes != null) {
      pass.bindUniform(sceneSlotFragment, sceneBufferView);
    }
  }
  
  GpuGeometryBuffers? _createHardwareBuffers(int instanceCount) {
    String uuid = '${material.uuid}_${geometry.uuid}';
    if (material.userData[uuid]?.version == material.version) {
      material.userData[uuid].needsUpdate = false;
      _updateBuffer(material.userData[uuid]);
      return material.userData[uuid];
    }

    final positionAttr = geometry.attributes['position'] as BufferAttribute?;
    final normalAttr = geometry.attributes['normal'] as BufferAttribute?;
    final uv0Attr = geometry.attributes['uv'] as BufferAttribute?;
    final uv1Attr = geometry.attributes['uv1'] as BufferAttribute?;
    final colorAttr = geometry.attributes['color'] as BufferAttribute?;
    final skinIndexAttr = geometry.attributes['skinIndex'] as BufferAttribute?;
    final skinWeightAttr = geometry.attributes['skinWeight'] as BufferAttribute?;
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

    final attri = descriptor.requiredAttributes;

    // 2. Configure float layout step strides and dynamic slot offset positions
    int stride = 3; 
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
    // LOCK IN SLOT: Instance ID Attribute Location Layout
    if (attri.contains(GeometryAttribute.instanceId)) {
      attributeOffsets[GeometryAttribute.instanceId] = stride;
      stride += 1;
    }

    final Float32List interleavedData = Float32List(finalVertexCount * stride);
    int vertexStride = 0;

    // ========================================================
    // 3. FLATTENED MASTER INFLATION LOOP (Unnested & Optimized)
    // ========================================================

    // Cache map lookups and attribute states outside the loop
    final bool hasNormal = attri.contains(GeometryAttribute.normal);
    final bool hasUv0 = uvs0 != null && attri.contains(GeometryAttribute.uv0);
    final bool hasUv1 = attri.contains(GeometryAttribute.uv1);
    final bool hasColor = attri.contains(GeometryAttribute.color);
    final bool hasSkinIndex = attri.contains(GeometryAttribute.skinIndex);
    final bool hasSkinWeight = attri.contains(GeometryAttribute.skinWeight);
    final bool hasInstanceId = attri.contains(GeometryAttribute.instanceId);

    final int normalOff = attributeOffsets[GeometryAttribute.normal] ?? 0;
    final int uv0Off = attributeOffsets[GeometryAttribute.uv0] ?? 0;
    final int uv1Off = attributeOffsets[GeometryAttribute.uv1] ?? 0;
    final int colorOff = attributeOffsets[GeometryAttribute.color] ?? 0;
    final int skinIdxOff = attributeOffsets[GeometryAttribute.skinIndex] ?? 0;
    final int skinWgtOff = attributeOffsets[GeometryAttribute.skinWeight] ?? 0;
    final int instanceIdOff = attributeOffsets[GeometryAttribute.instanceId] ?? 0;

    final double matRed = material.color.red;
    final double matGreen = material.color.green;
    final double matBlue = material.color.blue;

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
    
    material.userData[uuid] = GpuGeometryBuffers(
      vertexFloatArray: interleavedData,
      indexBuffer: finalIndices.buffer.asByteData(),
      indexCount: finalIndexCount, 
      vertexCount: finalVertexCount, 
      version: material.version,
      needsUpdate: true,
      indexType: finalIndices is Uint32List ? gpux.IndexType.int32 : gpux.IndexType.int16,
      instanceCount: effectiveInstances
    );

    return material.userData[uuid];
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

    if (attri.contains(GeometryAttribute.normal)) {
      normalOff = stride;
      stride += 3;
    }
    if (attri.contains(GeometryAttribute.uv0)) stride += 2;
    if (attri.contains(GeometryAttribute.uv1)) stride += 2;
    if (attri.contains(GeometryAttribute.color)) stride += 3;
    if (attri.contains(GeometryAttribute.skinIndex)) stride += 4;
    if (attri.contains(GeometryAttribute.skinWeight)) stride += 4;
    if (attri.contains(GeometryAttribute.instanceId)) stride += 1;

    final int totalVerts = positionAttr.count;
    final bool hasNormal = currentNormals != null && attri.contains(GeometryAttribute.normal);

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
  final int version;
  final int instanceCount;
  final gpux.IndexType indexType;
  bool needsUpdate;
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

  static gpux.SamplerOptions getSampler([Texture? text]){
    if(text == null){
      return gpux.SamplerOptions();
    }
    final GpuFilterPair minf = fromGlMinFilter(text.minFilter);

    return gpux.SamplerOptions(
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