import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_impeller_renderer/renderer/material/material_description_registry.dart';
import 'package:three_js_math/three_js_math.dart'; // Adjust based on your exact gpux library paths

class MaterialBindings{
  final gpux.GpuContext context;
  final Object3D object;
  final MaterialDescriptor descriptor;
  final Material material;

  MaterialBindings(
    this.context, 
    this.object,
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
    final gpux.HostBuffer host = context.createHostBuffer();

    if(material is ShaderMaterial){
      if(material.uniforms.isNotEmpty && material.uniforms['ShaderParameters'] != null){
        final data = _createUniformBuffers(material.uniforms,vertex,fragment,pass);
        if(data[0].isNotEmpty && material.uniforms['ShaderParameters']['vertex'] != null) _bindUniforms( host, pass, vertex, material.uniforms['ShaderParameters']['vertex'], data[0]);
        if(data[1].isNotEmpty && material.uniforms['ShaderParameters']['fragment'] != null) _bindUniforms( host, pass, fragment, material.uniforms['ShaderParameters']['fragment'], data[1]);
      }
    }
    else if(material is! ShaderMaterial){
      _bindMaterialUniforms(host, pass, vertex, fragment ,materialData);
    }

    if(descriptor.useSceneData){
      _bindUniforms(host, pass, fragment, 'SceneBlock', sceneData);
    }

    _bindTextures(pass,vertex,fragment);
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
      final texSlot = vertex.getUniformSlot('boneTexture');
      pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(text));
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
    [
      String? cacheName,
      gpux.TextureType type = gpux.TextureType.texture2D
    ]
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
      textureType: type,
      format: element.data is Uint8List?
        gpux.PixelFormat.r8g8b8a8UNormInt:
        element.data is Float32List?
        gpux.PixelFormat.r32g32b32a32Float:gpux.PixelFormat.r16g16b16a16Float,
      enableShaderReadUsage: true
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

  gpux.Texture _createCubeTexture(
    List<ImageElement> elements, {
    String? cacheName,
  }) {
    // 1. Enforce that a valid cubemap requires exactly 6 structural image faces
    if (elements.length != 6) {
      throw ArgumentError('Impeller Error: Cubemaps must provide exactly 6 sequential ImageElements.');
    }

    // Generate a distinct unique ID fallback pattern to prevent cache collisions
    final String uniqueId = cacheName ?? MathUtils.generateUUID();
    if (material.userData[uniqueId] != null) {
      return material.userData[uniqueId]!;
    }

    final primaryElement = elements[0];
    final int width = primaryElement.width.toInt();
    final int height = primaryElement.height.toInt();

    // 2. Allocate ONE single multi-layered texture container using the textureCube flag
    final cubeTexture = context.createTexture(
      gpux.StorageMode.hostVisible, // Required for host data overwrite calls
      width,
      height,
      sampleCount: 1,
      textureType: gpux.TextureType.textureCube, // Informs Impeller this has 6 face slices
      coordinateSystem: gpux.TextureCoordinateSystem.uploadFromHost, // Matches WebGL rules natively
      format: primaryElement.data is Uint8List
          ? gpux.PixelFormat.r8g8b8a8UNormInt
          : primaryElement.data is Float32List
              ? gpux.PixelFormat.r32g32b32a32Float
              : gpux.PixelFormat.r16g16b16a16Float,
    );

    // 3. FIXED: Grab the precise total base buffer budget directly from Impeller
    // This already accounts for all 6 faces combined! (e.g., 524288 bytes)
    final int totalCubeBytesLength = cubeTexture.getBaseMipLevelSizeInBytes(); 
    
    // Calculate the specific size constraint allocated per individual face
    final int singleFaceStride = totalCubeBytesLength ~/ 6;
    
    // Allocate the exact size buffer target matching the base mip level expectation
    final Uint8List combinedCubeBytes = Uint8List(totalCubeBytesLength);
    int currentByteOffset = 0;

    // 4. Statically append every individual face data slice into the linear queue buffer
    // Order follows standard WebGL/ThreeJS layout expectations:
    // 0:+X, 1:-X, 2:+Y, 3:-Y, 4:+Z, 5:-Z
    for (int faceIndex = 0; faceIndex < 6; faceIndex++) {
      final element = elements[faceIndex];
      if (element.data != null) {
        final Uint8List faceView = element.data.buffer.asUint8List(
          element.data.offsetInBytes,
          element.data.lengthInBytes,
        );
        
        // Copy the entire face pixel array chunk directly into its sequential slot segment
        combinedCubeBytes.setRange(
          currentByteOffset, 
          currentByteOffset + faceView.length, 
          faceView,
        );
      }
      // Step forward by the single face byte length stride
      currentByteOffset += singleFaceStride;
    }

    // 5. Fire a single batch overwrite command that perfectly maps to the 524288 byte limit
    cubeTexture.overwrite(combinedCubeBytes.buffer.asByteData());

    // Cache the generated multi-surface texture
    material.userData[uniqueId] = cubeTexture;
    return cubeTexture;
  }

  void _bindMaterialUniforms(
    gpux.HostBuffer host,
    gpux.RenderPass pass,
    gpux.Shader vertex,
    gpux.Shader fragment,
    Float32List materialData,
  ){
    // 1. CRITICAL PROTECTION FIX: Bound the byte space exactly to the Float32 view window!
    final int offset = materialData.offsetInBytes;
    final int length = materialData.lengthInBytes;
    final ByteData materialView = materialData.buffer.asByteData(offset, length);

    // 2. Emplace only the clean, isolated uniform range slice
    final gpux.BufferView materialBufferView = host.emplace(materialView);

    final vertexSlot = vertex.getUniformSlot('MaterialBlock');
    final materialSlotFragment = fragment.getUniformSlot('MaterialBlock');

    if (vertexSlot.sizeInBytes != null) {
      pass.bindUniform(vertexSlot, materialBufferView);
    }
    if (materialSlotFragment.sizeInBytes != null) {
      pass.bindUniform(materialSlotFragment, materialBufferView);
    }
  }

  void _bindUniforms(
    gpux.HostBuffer host,
    gpux.RenderPass pass,
    gpux.Shader shader,
    String name,
    Float32List data,
  ){
    final int offset = data.offsetInBytes;
    final int length = data.lengthInBytes;
    final ByteData sceneView = data.buffer.asByteData(offset, length);

    final gpux.BufferView sceneBufferView = host.emplace(sceneView);

    final sceneSlotFragment = shader.getUniformSlot(name);
    if (sceneSlotFragment.sizeInBytes != null) {
      pass.bindUniform(sceneSlotFragment, sceneBufferView);
    }
  }

  List<Float32List> _createUniformBuffers(
    Map<String, dynamic> uniforms, 
    gpux.Shader vertex, 
    gpux.Shader fragment, 
    gpux.RenderPass pass
  ) {
    if (material.userData['hostBuffers'] != null) {
      //return material.userData['hostBuffers'];
    }

    final List<double> hostvB = [];
    final List<double> hostfB = [];

    for (final key in uniforms.keys) {
      final uniformEntry = uniforms[key];
      final type = uniformEntry['value'];
      final String shader = uniformEntry['shader'] ?? 'vertex';
      final List<double> currentBuffer = (shader == 'vertex') ? hostvB : hostfB;

      if (type is Matrix4 || type is Vector4 || type == Color) {
        // Perfectly aligned types. Safe to add directly.
        currentBuffer.addAll(type.storage);
      } 
      else if (type is Matrix3 || type is Matrix2 || type is Vector3 || type is Vector2 || type is num) {
        // Throw an explicit alignment error detailing why this type is blocked
        throw ArgumentError(
          'Impeller Material Error: Uniform "$key" uses an unaligned type (${type.runtimeType}). '
          'To prevent std140 layout shifting, only Matrix4 (mat4) and Vector4 (vec4) are allowed. '
          'Please pack smaller types (like float, vec2, or vec3) inside a Vector4 on both Dart and GLSL sides.'
        );
      } 
      else if (type is Texture) {
        if(type.image is List){
          final texture = _createCubeTexture(type.image);
          final texSlot = (shader == 'fragment') 
              ? fragment.getUniformSlot(key) 
              : vertex.getUniformSlot(key);
          pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(type));
        }
        else{
          final texture = _createTexture(type.image);
          final texSlot = (shader == 'fragment') 
              ? fragment.getUniformSlot(key) 
              : vertex.getUniformSlot(key);
          pass.bindTexture(texSlot, texture, sampler: GpuSamplerConverter.getSampler(type));
        }
      }
    }

    material.userData['hostBuffers'] = [
      Float32List.fromList(hostvB),
      Float32List.fromList(hostfB)
    ];

    return material.userData['hostBuffers'];
  }
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