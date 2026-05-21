import 'dart:collection';
import 'dart:core';

/// Render statistics tracking.
/// T041: Track draw calls, triangles, and GPU memory usage.
///
/// Provides detailed performance metrics for tracking resource state lifecycles.
class RenderStatsTracker {
  // Use a native Stopwatch instance for precise cross-platform CPU hardware frame clocks
  final Stopwatch _stopwatch = Stopwatch()..start();

  // Frame counters
  int frameNumber = 0;
  int drawCalls = 0;
  int triangles = 0;
  int vertices = 0;
  int points = 0;
  int lines = 0;

  // Resource counters
  int geometryCount = 0;
  int textureCount = 0;
  int shaderCount = 0;
  int programCount = 0;

  // Memory tracking
  int bufferMemory = 0; // Using Dart's native 64-bit safe signed int
  int textureMemory = 0;
  int totalMemory = 0;
  double iblCpuMs = 0.0;
  int iblPrefilterMipCount = 0;
  double iblLastRoughness = 0.0;

  // Frame timing
  double frameStartTime = 0.0;
  double frameEndTime = 0.0;
  double lastFrameTime = 0.0;
  double avgFrameTime = 0.0;
  
  // Dart's Queue provides an identical O(1) buffer replacement for Kotlin's ArrayDeque
  final Queue<double> _frameTimeHistory = Queue<double>();

  /// Called at the start of each frame layer loop execution window.
  void frameStart() {
    frameStartTime = _getPerformanceNow();
    
    // Reset per-frame tracking metrics
    drawCalls = 0;
    triangles = 0;
    vertices = 0;
    points = 0;
    lines = 0;
  }

  /// Called at the end of each frame layer loop execution window.
  void frameEnd() {
    frameEndTime = _getPerformanceNow();
    frameNumber++;
    
    // Calculate fractional frame time
    lastFrameTime = frameEndTime - frameStartTime;
    
    // Update active rolling queue history metrics window bounds
    _frameTimeHistory.addLast(lastFrameTime);
    if (_frameTimeHistory.length > 60) {
      _frameTimeHistory.removeFirst();
    }
    
    avgFrameTime = _calculateQueueAverage(_frameTimeHistory);
  }

  /// Records a single geometry draw loop execution call instance.
  /// @param triangleCount Number of primitives contained within the batch
  void recordDrawCall(int triangleCount) {
    drawCalls++;
    triangles += triangleCount;
    vertices += triangleCount * 3;
  }

  /// Records single-point layout asset render drawing steps.
  void recordPoints(int pointCount) {
    points += pointCount;
    drawCalls++;
  }

  /// Records linear line trace asset drawing steps.
  void recordLines(int lineCount) {
    lines += lineCount;
    drawCalls++;
  }

  /// Records mesh spatial buffer geometry structure assembly.
  void recordGeometryCreated() {
    geometryCount++;
  }

  /// Records mesh spatial buffer geometry system allocations removal.
  void recordGeometryDisposed() {
    geometryCount--;
  }

  /// Records asset texture graphics memory resource tracking states.
  void recordTextureCreated(int memorySize) {
    textureCount++;
    textureMemory += memorySize;
    totalMemory += memorySize;
  }

  /// Records asset texture graphics memory resource deletion steps.
  void recordTextureDisposed(int memorySize) {
    textureCount--;
    textureMemory -= memorySize;
    totalMemory -= memorySize;
  }

  /// Records shader module construction.
  void recordShaderCreated() {
    shaderCount++;
    programCount++;
  }

  /// Records shader module system disposal.
  void recordShaderDisposed() {
    shaderCount--;
    programCount--;
  }

  /// Records buffer structure array space storage allocation metrics tracking.
  void recordBufferAllocated(int size) {
    bufferMemory += size;
    totalMemory += size;
  }

  /// Records buffer structure array space memory cleanup pipeline tracking.
  void recordBufferDeallocated(int size) {
    bufferMemory -= size;
    totalMemory -= size;
  }

  /// Gets current extracted render metrics values snapshots.
  RenderStats getStats() {
    final historyAverage = _calculateQueueAverage(_frameTimeHistory);
    final avgFps = historyAverage > 0.0 ? 1000.0 / historyAverage : 0.0;

    return RenderStats(
      fps: avgFps,
      frameTime: historyAverage,
      triangles: triangles,
      drawCalls: drawCalls,
      textureMemory: textureMemory,
      bufferMemory: bufferMemory,
      iblCpuMs: iblCpuMs,
      iblPrefilterMipCount: iblPrefilterMipCount,
      iblLastRoughness: iblLastRoughness,
    );
  }

  /// Completely flushes tracking states.
  void reset() {
    frameNumber = 0;
    drawCalls = 0;
    triangles = 0;
    vertices = 0;
    points = 0;
    lines = 0;
    geometryCount = 0;
    textureCount = 0;
    shaderCount = 0;
    programCount = 0;
    bufferMemory = 0;
    textureMemory = 0;
    totalMemory = 0;
    _frameTimeHistory.clear();
    avgFrameTime = 0.0;
    lastFrameTime = 0.0;
    iblCpuMs = 0.0;
    iblPrefilterMipCount = 0;
    iblLastRoughness = 0.0;
  }

  void recordIBLConvolution(IBLConvolutionMetrics metrics) {
    iblCpuMs = metrics.prefilterMs + metrics.irradianceMs;
    if (metrics.prefilterMipCount >= 0) {
      iblPrefilterMipCount = metrics.prefilterMipCount;
    }
  }

  void recordIBLMaterial(double roughness, int mipCount) {
    iblLastRoughness = roughness;
    if (mipCount >= 0) {
      iblPrefilterMipCount = mipCount;
    }
  }

  /// Gets a clean, formatted text dashboard summary of active runtime indicators.
  String getSummary() {
    final stats = getStats();
    final fpsDisplay = (stats.fps * 10).toInt() / 10.0;
    final frameTimeDisplay = (stats.frameTime * 100).toInt() / 100.0;

    final buffer = StringBuffer()
      ..writeln("=== Render Statistics ===")
      ..writeln("Frame: $frameNumber")
      ..writeln("FPS: $fpsDisplay")
      ..writeln("Frame Time: ${frameTimeDisplay}ms")
      ..writeln("Draw Calls: ${stats.drawCalls}")
      ..writeln("Triangles: ${stats.triangles}")
      ..writeln("Vertices: $vertices")
      ..writeln("Geometries: $geometryCount")
      ..writeln("Textures: $textureCount")
      ..writeln("Shaders: $shaderCount")
      ..writeln("Memory:")
      ..writeln(" - Buffers: ${_formatBytes(bufferMemory)}")
      ..writeln(" - Textures: ${_formatBytes(textureMemory)}")
      ..writeln(" - Total: ${_formatBytes(totalMemory)}");

    return buffer.toString();
  }

  double _getPerformanceNow() {
    return _stopwatch.elapsedMicroseconds / 1000.0;
  }

  double _calculateQueueAverage(Queue<double> queue) {
    if (queue.isEmpty) return 0.0;
    final totalSum = queue.fold<double>(0.0, (sum, current) => sum + current);
    return totalSum / queue.length;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).truncate()} KB";
    return "${(bytes / (1024 * 1024)).truncate()} MB";
  }
}

// ==========================================
// DATA STRUCTURE DEPENDENCY BLOCKS
// ==========================================

class RenderStats {
  final double fps;
  final double frameTime;
  final int triangles;
  final int drawCalls;
  final int textureMemory;
  final int bufferMemory;
  final double iblCpuMs;
  final int iblPrefilterMipCount;
  final double iblLastRoughness;

  const RenderStats({
    required this.fps,
    required this.frameTime,
    required this.triangles,
    required this.drawCalls,
    required this.textureMemory,
    required this.bufferMemory,
    required this.iblCpuMs,
    required this.iblPrefilterMipCount,
    required this.iblLastRoughness,
  });
}

class ExtendedRenderStats {
  final RenderStats base;
  final double frameTime;
  final double avgFrameTime;
  final double fps;
  final int bufferMemory;
  final int textureMemory;
  final int totalMemory;
  final int vertices;

  const ExtendedRenderStats({
    required this.base,
    required this.frameTime,
    required this.avgFrameTime,
    required this.fps,
    required this.bufferMemory,
    required this.textureMemory,
    required this.totalMemory,
    required this.vertices,
  });
}

class IBLConvolutionMetrics {
  final double prefilterMs;
  final double irradianceMs;
  final int prefilterMipCount;
  const IBLConvolutionMetrics({required this.prefilterMs, required this.irradianceMs, required this.prefilterMipCount});
}
