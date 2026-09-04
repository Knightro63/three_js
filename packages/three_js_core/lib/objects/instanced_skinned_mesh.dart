import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

final Matrix4 _instanceLocalMatrix = Matrix4.identity();
final Matrix4 _instanceWorldMatrix = Matrix4.identity();
final List<Intersection> _instanceIntersects = [];
bool patchedChunks = false;

class InstancedSkinnedMesh extends SkinnedMesh{
  Float32List? instanceBones;
  SkinnedMesh? _mesh;
  DataTexture? morphTexture;

  bool useIVAT = false;

  int get byteSize{
    // This property evaluates to true ONLY when the modern Impeller pipeline is handling execution
    return kIsWeb?3:ui.ImageFilter.isShaderFilterSupported?4:3;
  }

  InstancedSkinnedMesh(
    BufferGeometry geometry,
    Material material, [
    int count = 1,
  ]) : super(geometry, material) {
    this.count = count;
    instanceMatrix = InstancedBufferAttribute(Float32List(count * 16), 16, false);
    instanceColor = null;
    frustumCulled = false;
    _mesh = null;

    if(useIVAT){
      material.defines!['USE_IVAT'] = '';
    }

    if (!patchedChunks) {
      patchedChunks = true;

      if (shaderChunk['points_vert'] != null) {
        shaderChunk['points_vert'] = shaderChunk['points_vert']!.replaceAll(
          "#include <clipping_planes_pars_vertex>",
          "#include <clipping_planes_pars_vertex>\n#include <skinning_pars_vertex>"
        );
        shaderChunk['points_vert'] = shaderChunk['points_vert']!.replaceAll(
          "#include <morphtarget_vertex>",
          "#include <skinbase_vertex>\n#include <morphtarget_vertex>\n#include <skinning_vertex>"
        );
      }

      // Update PointsMaterial shader blueprint
      if (shaderLib['points'] != null) {
        shaderLib['points']['vertexShader'] = shaderChunk['points_vert'];
      }

      shaderChunk['skinning_pars_vertex'] = '''
        #ifdef USE_SKINNING

        #ifdef USE_IVAT
          attribute float aFrameIndex;
          attribute float uNumBones;
          uniform vec2 uTextureSize;
        #endif

        uniform mat4 bindMatrix;
        uniform mat4 bindMatrixInverse;
        uniform highp sampler2D boneTexture;

        mat4 getBoneMatrix( const in float boneIndex ) {
        #ifdef USE_INSTANCING
          #ifdef USE_IVAT
            ivec2 texSize = textureSize(boneTexture, 0);
            int texWidth = texSize.x;

            // Fallback to avoid division-by-zero, but do NOT return identity mat4(1.0)!
            int bones = 23;//int(uNumBones);//uNumBones > 0 ? uNumBones : 1;

            int frameIdx = int(floor(aFrameIndex + 0.5));
            int baseTexelIndex = (frameIdx * bones * 4) + (int(boneIndex) * 4);

            ivec2 uv0 = ivec2(baseTexelIndex % texWidth, baseTexelIndex / texWidth);
            ivec2 uv1 = ivec2((baseTexelIndex + 1) % texWidth, (baseTexelIndex + 1) / texWidth);
            ivec2 uv2 = ivec2((baseTexelIndex + 2) % texWidth, (baseTexelIndex + 2) / texWidth);
            ivec2 uv3 = ivec2((baseTexelIndex + 3) % texWidth, (baseTexelIndex + 3) / texWidth);

            vec4 v1 = texelFetch(boneTexture, uv0, 0);
            vec4 v2 = texelFetch(boneTexture, uv1, 0);
            vec4 v3 = texelFetch(boneTexture, uv2, 0);
            vec4 v4 = texelFetch(boneTexture, uv3, 0);
          #else
            int j = 4 * int(boneIndex);
            vec4 v1 = texelFetch(boneTexture, ivec2( j, gl_InstanceID ), 0);
            vec4 v2 = texelFetch(boneTexture, ivec2( j + 1, gl_InstanceID ), 0);
            vec4 v3 = texelFetch(boneTexture, ivec2( j + 2, gl_InstanceID ), 0);
            vec4 v4 = texelFetch(boneTexture, ivec2( j + 3, gl_InstanceID ), 0);
          #endif
        #else
          int size = textureSize( boneTexture, 0 ).x;
          int j = int( boneIndex ) * 4;
          int x = j % size;
          int y = j / size;
          vec4 v1 = texelFetch( boneTexture, ivec2( x, y ), 0 );
          vec4 v2 = texelFetch( boneTexture, ivec2( x + 1, y ), 0 );
          vec4 v3 = texelFetch( boneTexture, ivec2( x + 2, y ), 0 );
          vec4 v4 = texelFetch( boneTexture, ivec2( x + 3, y ), 0 );
        #endif
          return mat4( v1, v2, v3, v4 );
        }
        #endif
      ''';
    }
  }

  void initOverride(){
    skeleton!.computeBoneTexture = (){
      if(!useIVAT){
        skeleton!.boneTexture = DataTexture(
          instanceBones!,
          skeleton!.bones.length * 4,
          count,
          RGBAFormat,
          FloatType,
        );

        skeleton!.boneTexture?.name = "DataTexture from Skeleton.computeInstancedBoneTexture";
        skeleton!.boneTexture?.needsUpdate = true;
      }

      return skeleton!;
    };
  }

  @override
  InstancedSkinnedMesh copy(Object3D source, [bool? recursive]) {
    super.copy(source, recursive);
    if (source is InstancedSkinnedMesh) {
      instanceMatrix?.copy(source.instanceMatrix!);
      if (source.instanceColor != null) {
        instanceColor = source.instanceColor!.clone();
      }
      count = source.count;
    }
    return this;
  }

  Color getColorAt(int index, Color color) {
    if (instanceColor == null) {
      return color;
    }
    color.fromUnknown(instanceColor!.array, index * 3);
    return color;
  }

  Matrix4 getMatrixAt(int index, Matrix4 matrix) {
    return matrix.fromNativeArray(instanceMatrix!.array, index * 16);
  }

  @override
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    final Matrix4 matrixWorld = this.matrixWorld;
    final int raycastTimes = count ?? 0;

    if (_mesh == null) {
      _mesh = SkinnedMesh(geometry, material);
      _mesh!.copy(this);
    }

    final SkinnedMesh activeMesh = _mesh!;
    if (activeMesh.material == null) return;

    for (int instanceId = 0; instanceId < raycastTimes; instanceId++) {
      // calculate the world matrix for each instance
      getMatrixAt(instanceId, _instanceLocalMatrix);
      _instanceWorldMatrix.multiply2(matrixWorld, _instanceLocalMatrix);

      // the mesh represents this single instance
      activeMesh.matrixWorld = _instanceWorldMatrix;
      activeMesh.raycast(raycaster, _instanceIntersects);

      // process the result of raycast
      for (int i = 0; i < _instanceIntersects.length; i++) {
        final intersect = _instanceIntersects[i];
        intersect.instanceId = instanceId;
        intersect.object = this;
        intersects.add(intersect);
      }
      _instanceIntersects.clear();
    }
  }

  void setColorAt(int index, Color color) {
    if (instanceColor == null) {
      instanceColor = InstancedBufferAttribute(
        Float32List((instanceMatrix!.count * 3).toInt()), 
        3, 
        false
      );
    }
    color.copyIntoArray(instanceColor!.array, index * 3);
  }

  void setMatrixAt(int index, Matrix4 matrix) {
    matrix.copyIntoList(instanceMatrix!.array, index * 16);
  }

  void setBonesAt(int index, Skeleton skeleton) {
    final int size = skeleton.bones.length * 16;
    if (instanceBones == null) {
      instanceBones = Float32List(size * count!);
    }

    skeleton.updateInstanced(this.instanceBones!, index);
  }

  @override
  void updateMorphTargets() {}

  @override
  void dispose() {
    dispatchEvent(Event(type: "removed"));
    super.dispose();
  }
}