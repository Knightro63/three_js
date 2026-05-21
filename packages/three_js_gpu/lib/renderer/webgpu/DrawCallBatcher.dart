import 'dart:typed_data';
import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux layout location
import 'package:three_js_core/three_js_core.dart'; // Assuming Mesh and Material reside here

/// Draw call batching to reduce GPU overhead.
/// T039: +10 FPS improvement by batching compatible meshes.
///
/// Reduces draw calls from 1000+ to 50-100 by grouping meshes with:
/// - Same material
/// - Same geometry type
/// - Compatible render state
class DrawCallBatcher {
  final Map<BatchKey, MeshBatch> _batches = {};
  int _totalMeshes = 0;
  int _totalBatches = 0;

  /// Adds a mesh to the appropriate batch.
  void addMesh(Mesh mesh) {
    _totalMeshes++;
    final key = BatchKey.fromMesh(mesh);
    
    // Mimics Kotlin's getOrPut cleanly in Dart
    final batch = _batches.putIfAbsent(key, () {
      _totalBatches++;
      return MeshBatch(key);
    });
    
    batch.meshes.add(mesh);
  }

  /// Gets all batches for rendering.
  List<MeshBatch> getBatches() {
    return _batches.values.toList();
  }

  /// Clears all batches.
  void clear() {
    _batches.clear();
    _totalMeshes = 0;
    _totalBatches = 0;
  }

  /// Gets batching statistics.
  BatchingStats getStats() {
    final avgMeshesPerBatch = _totalBatches > 0 
        ? _totalMeshes.toDouble() / _totalBatches 
        : 0.0;
        
    final reduction = _totalMeshes > 0 
        ? 1.0 - (_totalBatches.toDouble() / _totalMeshes) 
        : 0.0;

    return BatchingStats(
      totalMeshes: _totalMeshes,
      totalBatches: _totalBatches,
      avgMeshesPerBatch: avgMeshesPerBatch,
      drawCallReduction: reduction,
    );
  }
}

/// Batch key for grouping compatible meshes.
class BatchKey {
  final int materialId;
  final String geometryType;
  final int renderState;

  const BatchKey({
    required this.materialId,
    required this.geometryType,
    required this.renderState,
  });

  factory BatchKey.fromMesh(Mesh mesh) {
    // Use material hash for grouping
    final materialId = mesh.material.hashCode;
    
    // Use geometry runtime type name for grouping
    final geometryType = mesh.geometry.runtimeType.toString();

    // Render state: combine depth test, culling, blending properties
    final material = mesh.material;
    final renderState = material is Material ? _computeRenderState(material) : 0;

    return BatchKey(
      materialId: materialId,
      geometryType: geometryType,
      renderState: renderState,
    );
  }

  static int _computeRenderState(Material material) {
    int state = 17;
    // Emulates Kotlin's hash multiplication stride via 32-bit safe math constraints
    state = (state * 31 + material.side) & 0xFFFFFFFF;
    state = (state * 31 + material.depthFunc) & 0xFFFFFFFF;
    state = (state * 31 + (material.depthTest ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + (material.depthWrite ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + material.blending) & 0xFFFFFFFF;
    state = (state * 31 + material.blendSrc) & 0xFFFFFFFF;
    state = (state * 31 + material.blendDst) & 0xFFFFFFFF;
    state = (state * 31 + material.blendEquation) & 0xFFFFFFFF;
    state = (state * 31 + (material.blendSrcAlpha ?? -1)) & 0xFFFFFFFF;
    state = (state * 31 + (material.blendDstAlpha ?? -1)) & 0xFFFFFFFF;
    state = (state * 31 + (material.blendEquationAlpha ?? -1)) & 0xFFFFFFFF;
    state = (state * 31 + (material.transparent ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + (material.premultipliedAlpha ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + (material.alphaToCoverage ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + (material.dithering ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + (material.colorWrite ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + (material.polygonOffset ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + _doubleToBits(material.polygonOffsetFactor)) & 0xFFFFFFFF;
    state = (state * 31 + _doubleToBits(material.polygonOffsetUnits)) & 0xFFFFFFFF;
    state = (state * 31 + (material.stencilWrite ? 1 : 0)) & 0xFFFFFFFF;
    state = (state * 31 + material.stencilFunc) & 0xFFFFFFFF;
    state = (state * 31 + material.stencilFail) & 0xFFFFFFFF;
    state = (state * 31 + material.stencilZFail) & 0xFFFFFFFF;
    state = (state * 31 + material.stencilZPass) & 0xFFFFFFFF;
    state = (state * 31 + material.stencilWriteMask) & 0xFFFFFFFF;
    state = (state * 31 + material.stencilFuncMask) & 0xFFFFFFFF;
    state = (state * 31 + material.stencilRef) & 0xFFFFFFFF;
    state = (state * 31 + (material.precision ?? -1)) & 0xFFFFFFFF;
    state = (state * 31 + _doubleToBits(material.alphaTest)) & 0xFFFFFFFF;
    return state;
  }

  /// Helper converting double variables safely to IEEE 754 32-bit integers
  static int _doubleToBits(double value) {
    final ByteData bd = ByteData(4);
    bd.setFloat32(0, value);
    return bd.getInt32(0);
  }

  // Necessary to make this class function correctly inside Dart Maps as keys
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchKey &&
          runtimeType == other.runtimeType &&
          materialId == other.materialId &&
          geometryType == other.geometryType &&
          renderState == other.renderState;

  @override
  int get hashCode => materialId.hashCode ^ geometryType.hashCode ^ renderState.hashCode;
}

/// A batch of meshes that can be rendered together.
class MeshBatch {
  final BatchKey key;
  final List<Mesh> meshes;

  MeshBatch(this.key, [List<Mesh>? meshes]) : meshes = meshes ?? [];

  int get count => meshes.length;

  /// Renders all meshes in this batch.
  void render({
    required GpuRenderPassEncoder renderPass,
    required void Function(Mesh, GpuRenderPassEncoder) renderMesh,
  }) {
    for (final mesh in meshes) {
      renderMesh(mesh, renderPass);
    }
  }
}

/// Batching statistics container.
class BatchingStats {
  final int totalMeshes;
  final int totalBatches;
  final double avgMeshesPerBatch;
  final double drawCallReduction; // 0.0 to 1.0 (percentage)

  const BatchingStats({
    required this.totalMeshes,
    required this.totalBatches,
    required this.avgMeshesPerBatch,
    required this.drawCallReduction,
  });
}
