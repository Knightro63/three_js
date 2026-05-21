/// Rendering shader stages supported by the material system.
enum ShaderStageType {
  vertex,
  fragment,
  compute,
}

/// Represents a reusable shader chunk. The chunk can optionally be scoped to a specific
/// [ShaderStageType]; when `stage` is `null` the chunk is treated as shared across all stages.
class ShaderChunk {
  const ShaderChunk({
    required this.name,
    required this.source,
    this.stage,
  });

  final String name;
  final String source;
  final ShaderStageType? stage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShaderChunk &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          source == other.source &&
          stage == other.stage;

  @override
  int get hashCode => Object.hash(name, source, stage);
}

/// Registry that stores shader chunks and resolves `#include <chunk>` directives when compiling
/// complete shader modules. Higher level components provide caching and descriptor handling.
abstract class ShaderChunkRegistry {
  // RegExp mapping exactly to Kotlin's inclusion token pattern matcher
  static final RegExp _includeRegex = RegExp(r'#include\s*<([A-Za-z0-9_./-]+)>');
  
  // High-performance direct local map tracker replacing persistent collection primitives
  static final Map<String, List<ShaderChunk>> _chunkRegistry = {};

  static ShaderChunk? _findChunk(String name, ShaderStageType stage) {
    final candidates = _chunkRegistry[name];
    if (candidates == null) return null;

    // Search matching stage explicitly, or fallback onto shared/null configurations
    for (final chunk in candidates) {
      if (chunk.stage == stage) return chunk;
    }
    for (final chunk in candidates) {
      if (chunk.stage == null) return chunk;
    }
    return null;
  }

  /// Registers a shader [chunk]. If a chunk with the same name and stage already exists the
  /// behaviour depends on [replaceExisting].
  static void register(ShaderChunk chunk, {bool replaceExisting = false}) {
    final existing = _chunkRegistry.putIfAbsent(chunk.name, () => <ShaderChunk>[]);
    final index = existing.indexWhere((it) => it.stage == chunk.stage);

    if (index >= 0) {
      if (!replaceExisting) {
        throw StateError("Shader chunk '${chunk.name}' already registered for stage ${chunk.stage}");
      }
      existing[index] = chunk;
    } else {
      existing.add(chunk);
    }
  }

  /// Registers all elements inside [chunkList].
  static void registerAll(Iterable<ShaderChunk> chunkList, {bool replaceExisting = false}) {
    for (final chunk in chunkList) {
      register(chunk, replaceExisting: replaceExisting);
    }
  }

  /// Returns true when a chunk with [name] is registered for [stage].
  static bool contains(String name, [ShaderStageType? stage]) {
    final candidates = _chunkRegistry[name];
    if (candidates == null || candidates.isEmpty) return false;
    if (stage == null) return true;

    return candidates.any((it) => it.stage == stage || it.stage == null);
  }

  /// Clears the registry. Intended for tests; production code should not invoke this directly.
  static void clearForTests() => _chunkRegistry.clear();

  /// Expands the provided [chunkNames] into a complete shader module for the supplied [stage].
  /// Depth-first resolution of `#include` directives while preventing cyclic dependencies.
  static String assemble({
    required List<String> chunkNames,
    required ShaderStageType stage,
    Map<String, String> replacements = const {},
  }) {
    if (chunkNames.isEmpty) {
      throw ArgumentError('At least one shader chunk must be specified for stage $stage');
    }

    final builder = StringBuffer();
    final stack = <String>[];

    for (int i = 0; i < chunkNames.length; i++) {
      final name = chunkNames[i];
      final chunk = _findChunk(name, stage);
      if (chunk == null) {
        throw StateError("Shader chunk '$name' not registered for stage $stage");
      }

      final resolved = _resolveChunk(chunk, stage, stack);
      builder.write(resolved.trim());

      if (i != chunkNames.length - 1) {
        builder.writeln();
        builder.writeln();
      }
    }

    var combined = builder.toString();
    replacements.forEach((key, value) {
      combined = combined.replaceAll('{{$key}}', value);
    });

    return combined;
  }

  static String _resolveChunk(
    ShaderChunk chunk,
    ShaderStageType stage,
    List<String> stack,
  ) {
    final key = '${chunk.name}::${chunk.stage?.name ?? "ANY"}';
    if (stack.contains(key)) {
      throw StateError('Circular shader chunk include detected: ${stack.join(' -> ')} -> ${chunk.name}');
    }

    stack.add(key);
    var source = chunk.source;

    // Emulate Kotlin regex matcher replacement logic via modern Dart closures mapped inline
    source = source.replaceAllMapped(_includeRegex, (match) {
      final includeName = match.group(1)!;
      final includeChunk = _findChunk(includeName, stage);
      
      if (includeChunk == null) {
        throw StateError("Shader chunk '$includeName' referenced from '${chunk.name}' is not registered for stage $stage");
      }
      return _resolveChunk(includeChunk, stage, stack);
    });

    stack.removeLast();
    return source;
  }
}
