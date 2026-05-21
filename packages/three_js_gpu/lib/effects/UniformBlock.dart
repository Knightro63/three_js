import 'dart:typed_data';

/// Uniform types with size and alignment constraints matching WGSL requirements.
enum UniformType {
  float(4, 4, 'f32'),
  Int(4, 4, 'i32'),
  uint(4, 4, 'u32'),
  vec2(8, 8, 'vec2<f32>'),
  vec3(12, 16, 'vec3<f32>'), // vec3 aligns to 16 in WGSL
  vec4(16, 16, 'vec4<f32>'),
  mat3(48, 16, 'mat3x3<f32>'), // 3 x vec4 (padded)
  mat4(64, 16, 'mat4x4<f32>'),
  
  // Array types - element alignment is 16 for scalars
  floatArray(0, 16, 'array<f32>'),
  intArray(0, 16, 'array<i32>'),
  vec2Array(0, 16, 'array<vec2<f32>>'),
  vec3Array(0, 16, 'array<vec3<f32>>'),
  vec4Array(0, 16, 'array<vec4<f32>>'),
  mat4Array(0, 16, 'array<mat4x4<f32>>');

  const UniformType(this.byteSize, this.alignment, this.wgslType);

  final int byteSize;
  final int alignment;
  final String wgslType;

  static UniformType arrayTypeFor(UniformType elementType) {
    return switch (elementType) {
      UniformType.float => UniformType.floatArray,
      UniformType.Int => UniformType.intArray,
      UniformType.vec2 => UniformType.vec2Array,
      UniformType.vec3 => UniformType.vec3Array,
      UniformType.vec4 => UniformType.vec4Array,
      UniformType.mat4 => UniformType.mat4Array,
      _ => throw ArgumentError('Arrays of $elementType not supported'),
    };
  }

  static int elementSizeFor(UniformType elementType, int count) {
    return switch (elementType) {
      UniformType.float || UniformType.Int || UniformType.uint => count * 16, // Padded to 16 bytes
      UniformType.vec2 => count * 16, // vec2 padded to 16 bytes in array
      UniformType.vec3 => count * 16, // vec3 already 16 bytes aligned
      UniformType.vec4 => count * 16, // vec4 is 16 bytes
      UniformType.mat4 => count * 64, // mat4 is 64 bytes
      _ => throw ArgumentError('Arrays of $elementType not supported'),
    };
  }
}

/// Represents a single field in the uniform block
class UniformField {
  const UniformField({
    required this.name,
    required this.type,
    required this.offset,
    required this.size,
    this.arraySize = 0,
  });

  final String name;
  final UniformType type;
  final int offset;
  final int size;
  final int arraySize;

  /// WGSL type declaration
  String get wgslType {
    if (arraySize > 0) {
      // Strips wrapping to cleanly shape array expressions
      final cleanType = type.wgslType.replaceAll('array<', '').replaceAll('>', '');
      return 'array<$cleanType, $arraySize>';
    }
    return type.wgslType;
  }
}

/// Represents a padding field for WGSL generation
class PaddingField {
  const PaddingField({
    required this.name,
    required this.offset,
    required this.size,
  });

  final String name;
  final int offset;
  final int size;
}

/// Immutable uniform block layout with automatic alignment handling
class UniformBlock {
  UniformBlock({
    required this.layout,
    required this.size,
    required this.paddingFields,
  });

  final List<UniformField> layout;
  final int size;
  final List<PaddingField> paddingFields;

  bool get isEmpty => size == 0;
  bool get isNotEmpty => size != 0;

  /// Get a field by name
  UniformField? field(String name) {
    for (final f in layout) {
      if (f.name == name) return f;
    }
    return null;
  }

  /// Create a float buffer sized to hold all uniform data
  Float32List createBuffer() => Float32List(size ~/ 4);

  /// Create an updater for the given buffer
  UniformUpdater createUpdater(Float32List buffer) => UniformUpdater(this, buffer);

  /// Generate WGSL struct definition
  String toWGSL(String structName) {
    final buffer = StringBuffer();
    buffer.writeln('struct $structName {');

    // Combine fields and padding, sort by offset
    final allFields = <_StructFieldEntry>[];

    for (final field in layout) {
      allFields.add(_StructFieldEntry(field.offset, field.name, field.wgslType));
    }

    for (final padding in paddingFields) {
      final paddingType = switch (padding.size) {
        4 => 'f32',
        8 => 'vec2<f32>',
        12 => 'vec3<f32>',
        _ => 'f32',
      };
      allFields.add(_StructFieldEntry(padding.offset, padding.name, paddingType));
    }

    // Sort entries structurally by offset
    allFields.sort((a, b) => a.offset.compareTo(b.offset));

    for (final entry in allFields) {
      buffer.writeln('  ${entry.name}: ${entry.type},');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  static UniformBlock empty() => UniformBlock(layout: const [], size: 0, paddingFields: const []);

  /// Build a uniform block using the DSL builder
  static UniformBlock build(void Function(UniformBlockBuilder) block) {
    final builder = UniformBlockBuilder();
    block(builder);
    return builder.build();
  }
}

/// Helper container class replacing Kotlin's Triple for fields sorting
class _StructFieldEntry {
  const _StructFieldEntry(this.offset, this.name, this.type);
  final int offset;
  final String name;
  final String type;
}

/// DSL builder for UniformBlock
class UniformBlockBuilder {
  final List<_PendingField> _fields = [];

  void float(String name) => _fields.add(_PendingField(name, UniformType.float));
  void Int(String name) => _fields.add(_PendingField(name, UniformType.Int));
  void uint(String name) => _fields.add(_PendingField(name, UniformType.uint));
  void vec2(String name) => _fields.add(_PendingField(name, UniformType.vec2));
  void vec3(String name) => _fields.add(_PendingField(name, UniformType.vec3));
  void vec4(String name) => _fields.add(_PendingField(name, UniformType.vec4));
  void mat3(String name) => _fields.add(_PendingField(name, UniformType.mat3));
  void mat4(String name) => _fields.add(_PendingField(name, UniformType.mat4));

  void array(String name, UniformType elementType, int count) {
    final arrayType = UniformType.arrayTypeFor(elementType);
    _fields.add(_PendingField(name, arrayType, arraySize: count));
  }

  UniformBlock build() {
    if (_fields.isEmpty) {
      return UniformBlock.empty();
    }

    final layoutFields = <UniformField>[];
    final paddingFieldsList = <PaddingField>[];
    int currentOffset = 0;
    int paddingIndex = 0;

    for (final pending in _fields) {
      final alignment = pending.type.alignment;
      final int size;

      if (pending.arraySize > 0) {
        final baseType = switch (pending.type) {
          UniformType.floatArray => UniformType.float,
          UniformType.intArray => UniformType.Int,
          UniformType.vec2Array => UniformType.vec2,
          UniformType.vec3Array => UniformType.vec3,
          UniformType.vec4Array => UniformType.vec4,
          UniformType.mat4Array => UniformType.mat4,
          _ => pending.type,
        };
        size = UniformType.elementSizeFor(baseType, pending.arraySize);
      } else {
        size = pending.type.byteSize;
      }

      // Calculate aligned offset
      final alignedOffset = _alignTo(currentOffset, alignment);

      // Add padding if needed
      if (alignedOffset > currentOffset) {
        final paddingSize = alignedOffset - currentOffset;
        paddingFieldsList.add(PaddingField(
          name: '_pad$paddingIndex',
          offset: currentOffset,
          size: paddingSize,
        ));
        paddingIndex++;
      }

      layoutFields.add(UniformField(
        name: pending.name,
        type: pending.type,
        offset: alignedOffset,
        size: size,
        arraySize: pending.arraySize,
      ));

      currentOffset = alignedOffset + size;
    }

    return UniformBlock(
      layout: layoutFields,
      size: currentOffset,
      paddingFields: paddingFieldsList,
    );
  }

  int _alignTo(int offset, int alignment) {
    final remainder = offset % alignment;
    return remainder == 0 ? offset : offset + (alignment - remainder);
  }
}

class _PendingField {
  const _PendingField(this.name, this.type, {this.arraySize = 0});
  final String name;
  final UniformType type;
  final int arraySize;
}

class UniformUpdater {
  UniformUpdater(this._block, this._buffer);

  final UniformBlock _block;
  final Float32List _buffer;

  // Reusable byte view buffer overlay to map integers on top of the Float32 representation
  late final ByteData _view = ByteData.sublistView(_buffer);

  /// Set a float uniform value
  void setFloat(String name, double value) {
    final field = _block.field(name);
    if (field == null) throw ArgumentError('Unknown uniform: $name');
    _buffer[field.offset ~/ 4] = value;
  }

  /// Set a vec2 uniform value
  void setVec2(String name, double x, double y) {
    final field = _block.field(name);
    if (field == null) throw ArgumentError('Unknown uniform: $name');
    final index = field.offset ~/ 4;
    _buffer[index] = x;
    _buffer[index + 1] = y;
  }

  /// Set a vec3 uniform value
  void setVec3(String name, double x, double y, double z) {
    final field = _block.field(name);
    if (field == null) throw ArgumentError('Unknown uniform: $name');
    final index = field.offset ~/ 4;
    _buffer[index] = x;
    _buffer[index + 1] = y;
    _buffer[index + 2] = z;
  }

  /// Set a vec4 uniform value
  void setVec4(String name, double x, double y, double z, double w) {
    final field = _block.field(name);
    if (field == null) throw ArgumentError('Unknown uniform: $name');
    final index = field.offset ~/ 4;
    _buffer[index] = x;
    _buffer[index + 1] = y;
    _buffer[index + 2] = z;
    _buffer[index + 3] = w;
  }

  /// Set an integer uniform value by mapping bits directly onto the float buffer
  void setInt(String name, int value) {
    final field = _block.field(name);
    if (field == null) throw ArgumentError('Unknown uniform: $name');
    _view.setInt32(field.offset, value, Endian.host);
  }

  /// Set a mat3 uniform value from a float array.
  /// Expands to 3 vec4s (12 floats) in the buffer due to WGSL std140 layout requirements.
  void setMat3(String name, Float32List matrix) {
    assert(matrix.length >= 9, 'Mat3 requires 9 float values');
    final field = _block.field(name);
    if (field == null) throw ArgumentError('Unknown uniform: $name');
    final index = field.offset ~/ 4;

    // Column 0
    _buffer[index + 0] = matrix[0];
    _buffer[index + 1] = matrix[1];
    _buffer[index + 2] = matrix[2];
    _buffer[index + 3] = 0.0; // padding
    // Column 1
    _buffer[index + 4] = matrix[3];
    _buffer[index + 5] = matrix[4];
    _buffer[index + 6] = matrix[5];
    _buffer[index + 7] = 0.0; // padding
    // Column 2
    _buffer[index + 8] = matrix[6];
    _buffer[index + 9] = matrix[7];
    _buffer[index + 10] = matrix[8];
    _buffer[index + 11] = 0.0; // padding
  }

  /// Set a mat3 uniform value from individual components (column-major order).
  void setMat3Values(
    String name,
    double m00, double m01, double m02,
    double m10, double m11, double m12,
    double m20, double m21, double m22,
  ) {
    setMat3(name, Float32List.fromList([m00, m01, m02, m10, m11, m12, m20, m21, m22]));
  }

  /// Set a mat4 uniform value from a float array
  void setMat4(String name, Float32List matrix) {
    assert(matrix.length >= 16, 'Mat4 requires 16 float values');
    final field = _block.field(name);
    if (field == null) throw ArgumentError('Unknown uniform: $name');
    final index = field.offset ~/ 4;

    for (int i = 0; i < 16; i++) {
      _buffer[index + i] = matrix[i];
    }
  }
}

/// DSL function to create a uniform block
UniformBlock uniformBlock(void Function(UniformBlockBuilder) block) {
  return UniformBlock.build(block);
}
