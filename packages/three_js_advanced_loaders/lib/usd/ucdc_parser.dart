import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';

// Pre-computed half-float exponent lookup table for fast conversion
// math.pow(2, exp - 15) for exp = 0..31
final Float32List halfExponentTable = Float32List(32)..initTable();

extension on Float32List {
  void initTable() {
    for (int i = 0; i < 32; i++) {
      this[i] = math.pow(2, i - 15).toDouble();
    }
  }
}

// Pre-computed constant for denormalized half-floats: 2^-14
final double halfDenormScale = math.pow(2, -14).toDouble();

// Field set terminator marker
const int fieldSetTerminator = 0xFFFFFFFF;

// Float compression type codes
const int floatCompressionInt = 0x69; // 'i' - compressed as integers
const int floatCompressionLut = 0x74; // 't' - lookup table

/// Type enum values from crateDataTypes.h
enum TypeEnum {
  invalid(0),
  boolean(1), // Renamed from 'Bool' to avoid conflict with Dart 'bool' type keyword
  uChar(2),
  integer(3), // Renamed from 'Int' to avoid conflict with Dart 'int' type keyword
  uInt(4),
  int64(5),
  uInt64(6),
  half(7),
  float(8),
  doubleType(9), // Renamed from 'Double' to avoid conflict with Dart 'double' type keyword
  string(10),
  token(11),
  assetPath(12),
  matrix2d(13),
  matrix3d(14),
  matrix4d(15),
  quatd(16),
  quatf(17),
  quath(18),
  vec2d(19),
  vec2f(20),
  vec2h(21),
  vec2i(22),
  vec3d(23),
  vec3f(24),
  vec3h(25),
  vec3i(26),
  vec4d(27),
  vec4f(28),
  vec4h(29),
  vec4i(30),
  dictionary(31),
  tokenListOp(32),
  stringListOp(33),
  pathListOp(34),
  referenceListOp(35),
  intListOp(36),
  int64ListOp(37),
  uIntListOp(38),
  uInt64ListOp(39),
  pathVector(40),
  tokenVector(41),
  specifier(42),
  permission(43),
  variability(44),
  variantSelectionMap(45),
  timeSamples(46),
  payload(47),
  doubleVector(48),
  layerOffsetVector(49),
  stringVector(50),
  valueBlock(51),
  val(52),
  unregisteredValue(53),
  unregisteredValueListOp(54),
  payloadListOp(55),
  timeCode(56),
  pathExpression(57),
  relocates(58),
  spline(59),
  animationBlock(60);

  final int value;
  const TypeEnum(this.value);
}

/// LZ4 Decompression (minimal implementation for USD)
/// Based on LZ4 block format specification
int lz4DecompressBlock(
  Uint8List input,
  int inputOffset,
  int inputEnd,
  Uint8List output,
  int outputOffset,
  int outputEnd,
) {
  while (inputOffset < inputEnd) {
    // Read token
    final int token = input[inputOffset++];
    if (inputOffset > inputEnd) break;

    // Literal length
    int literalLength = token >> 4;
    if (literalLength == 15) {
      int b;
      do {
        if (inputOffset >= inputEnd) break;
        b = input[inputOffset++];
        literalLength += b;
      } while (b == 255 && inputOffset < inputEnd);
    }

    // Copy literals
    if (literalLength > 0) {
      if (inputOffset + literalLength > inputEnd) {
        literalLength = inputEnd - inputOffset;
      }
      for (int i = 0; i < literalLength; i++) {
        if (outputOffset >= outputEnd) break;
        output[outputOffset++] = input[inputOffset++];
      }
    }

    // Check if we're at the end (last sequence has no match)
    if (inputOffset >= inputEnd) break;

    // Read match offset (little-endian 16-bit)
    if (inputOffset + 2 > inputEnd) break;
    final int matchOffset = input[inputOffset++] | (input[inputOffset++] << 8);
    if (matchOffset == 0) {
      // Invalid offset
      break;
    }

    // Match length
    int matchLength = (token & 0x0F) + 4;
    if (matchLength == 19) {
      int b;
      do {
        if (inputOffset >= inputEnd) break;
        b = input[inputOffset++];
        matchLength += b;
      } while (b == 255 && inputOffset < inputEnd);
    }

    // Copy match (byte-by-byte to handle overlapping)
    final int matchPos = outputOffset - matchOffset;
    if (matchPos < 0) {
      // Invalid match position
      break;
    }
    for (int i = 0; i < matchLength; i++) {
      if (outputOffset >= outputEnd) break;
      output[outputOffset++] = output[matchPos + i];
    }
  }
  return outputOffset;
}



/// USD uses TfFastCompression which wraps LZ4 with chunk headers
Uint8List decompressLZ4(Uint8List input, int uncompressedSize) {
  // TfFastCompression format (used by OpenUSD):
  // Single chunk (byte 0 == 0): [0] + LZ4 data
  // Multi chunk (byte 0 > 0): [numChunks] + [compressedSizes...] + [chunkData...]
  final Uint8List output = Uint8List(uncompressedSize);
  final int numChunks = input[0];

  if (numChunks == 0) {
    // Single chunk - all remaining bytes are LZ4 compressed
    lz4DecompressBlock(input, 1, input.length, output, 0, uncompressedSize);
    return output;
  } else {
    // Multiple chunks - each chunk decompresses to max 65536 bytes
    const int chunkSize = 65536;

    // First, read all chunk sizes
    int headerOffset = 1;
    final List<int> compressedSizes = [];

    for (int i = 0; i < numChunks; i++) {
      // (val >>> 0) in JS is forced to 32-bit unsigned int. 
      // In Dart, we replicate this with standard bit shifts masked with 0xFFFFFFFF.
      final int size = (input[headerOffset] |
              (input[headerOffset + 1] << 8) |
              (input[headerOffset + 2] << 16) |
              (input[headerOffset + 3] << 24)) &
          0xFFFFFFFF;
          
      compressedSizes.add(size);
      headerOffset += 4;
    }

    // Decompress each chunk
    int inputOffset = headerOffset;
    int outputOffset = 0;

    for (int i = 0; i < numChunks; i++) {
      final int chunkCompressedSize = compressedSizes[i];
      final int chunkOutputSize = math.min(chunkSize, uncompressedSize - outputOffset);

      lz4DecompressBlock(
        input,
        inputOffset,
        inputOffset + chunkCompressedSize,
        output,
        outputOffset,
        outputOffset + chunkOutputSize,
      );

      inputOffset += chunkCompressedSize;
      outputOffset += chunkOutputSize;
    }

    return output;
  }
}

/// Integer Decompression (USD-specific delta + variable-width encoding)
Int32List decompressIntegers32(dynamic compressedData, int numInts) {
  Uint8List inputBytes;
  
  if (compressedData is Uint8List) {
    inputBytes = compressedData;
  } else if (compressedData is ByteBuffer) {
    inputBytes = compressedData.asUint8List();
  } else if (compressedData is List<int>) {
    inputBytes = Uint8List.fromList(compressedData);
  } else {
    throw ArgumentError('Unsupported compressedData binary representation');
  }

  // First decompress with LZ4
  final int encodedSize = (numInts * 4) + (((numInts * 2) + 7) >> 3) + 4;
  final Uint8List encoded = decompressLZ4(inputBytes, encodedSize);

  // Then decode
  return decodeIntegers32(encoded, numInts);
}

Int32List decodeIntegers32(Uint8List data, int numInts) {
  // ByteData acts exactly like JavaScript's DataView
  final ByteData view = ByteData.sublistView(data);
  int offset = 0;

  // Read common value (signed 32-bit little-endian)
  final int commonValue = view.getInt32(offset, Endian.little);
  offset += 4;

  final int numCodesBytes = ((numInts * 2) + 7) >> 3;
  final int codesStart = offset;
  final int vintsStart = offset + numCodesBytes;
  
  final Int32List result = Int32List(numInts);
  
  int prevVal = 0;
  int codesOffset = codesStart;
  int vintsOffset = vintsStart;

  for (int i = 0; i < numInts;) {
    final int codeByte = data[codesOffset++];
    
    for (int j = 0; j < 4 && i < numInts; j++, i++) {
      final int code = (codeByte >> (j * 2)) & 3;
      int delta = 0;

      switch (code) {
        case 0:
          // Common value
          delta = commonValue;
          break;
        case 1:
          // 8-bit signed integer
          delta = view.getInt8(vintsOffset);
          vintsOffset += 1;
          break;
        case 2:
          // 16-bit signed little-endian integer
          delta = view.getInt16(vintsOffset, Endian.little);
          vintsOffset += 2;
          break;
        case 3:
          // 32-bit signed little-endian integer
          delta = view.getInt32(vintsOffset, Endian.little);
          vintsOffset += 4;
          break;
      }

      prevVal += delta;
      
      // Force 32-bit signed integer overflow arithmetic to mirror JS behavior safely
      prevVal = prevVal.toSigned(32); 
      
      result[i] = prevVal;
    }
  }

  return result;
}

/// Binary Reader Helper
class BinaryReader {
  final ByteBuffer buffer;
  final ByteData view;
  int offset = 0;

  BinaryReader(ByteBuffer input)
      : buffer = input,
        view = ByteData.view(input) {
    offset = 0;
  }

  void seek(int offset) {
    this.offset = offset;
  }

  int tell() {
    return offset;
  }

  int readUint8() {
    final int value = view.getUint8(offset);
    offset += 1;
    return value;
  }

  int readInt8() {
    final int value = view.getInt8(offset);
    offset += 1;
    return value;
  }

  int readUint16() {
    final int value = view.getUint16(offset, Endian.little);
    offset += 2;
    return value;
  }

  int readInt16() {
    final int value = view.getInt16(offset, Endian.little);
    offset += 2;
    return value;
  }

  int readUint32() {
    final int value = view.getUint32(offset, Endian.little);
    offset += 4;
    return value;
  }

  int readInt32() {
    final int value = view.getInt32(offset, Endian.little);
    offset += 4;
    return value;
  }

  int readUint64() {
    // Dart natively supports 64-bit integers. No manual high/low splitting math required.
    final int value = view.getUint64(offset, Endian.little);
    offset += 8;
    return value;
  }

  int readInt64() {
    final int value = view.getInt64(offset, Endian.little);
    offset += 8;
    return value;
  }

  double readFloat32() {
    final double value = view.getFloat32(offset, Endian.little);
    offset += 4;
    return value;
  }

  double readFloat64() {
    final double value = view.getFloat64(offset, Endian.little);
    offset += 8;
    return value;
  }

  Uint8List readBytes(int length) {
    final Uint8List bytes = Uint8List.view(buffer, offset, length);
    offset += length;
    return bytes;
  }

  String readString(int length) {
    final Uint8List bytes = readBytes(length);
    int end = 0;
    while (end < length && bytes[end] != 0) {
      end++;
    }
    // sublistView handles slicing cleanly without memory cloning
    return utf8.decode(Uint8List.sublistView(bytes, 0, end));
  }
}

/// ValueRep - 64-bit packed value representation
class ValueRep {
  /// The full 64-bit raw packed value
  final int value;

  ValueRep(this.value);

  /// Alternative constructor if you still receive lo/hi chunks from external sources
  ValueRep.fromLoHi(int lo, int hi)
      : value = ((hi & 0xFFFFFFFF) << 32) | (lo & 0xFFFFFFFF);

  bool get isArray => (value & 0x8000000000000000) != 0;

  bool get isInlined => (value & 0x4000000000000000) != 0;

  bool get isCompressed => (value & 0x2000000000000000) != 0;

  int get typeEnum => (value >> 48) & 0xFF;

  int get payload {
    // 48-bit payload: extracted directly via a bitwise mask
    return value & 0xFFFFFFFFFFFF;
  }

  int getInlinedValue() {
    // For inlined scalars, the value is in the lower 32 bits.
    // We cast to 32-bit signed integer to match JavaScript's bitwise return behavior.
    return (value & 0xFFFFFFFF).toSigned(32);
  }
}

class UsdcSpec {
  final int pathIndex;
  final int fieldSetIndex;
  final int specType;

  UsdcSpec({
    required this.pathIndex,
    required this.fieldSetIndex,
    required this.specType,
  });
}


// ============================================================================
// USDC Parser
// ============================================================================
class USDCParser {
  ByteBuffer buffer = Uint8List(0).buffer;
  late BinaryReader reader = BinaryReader(buffer);
  final Map<String,dynamic> version = {'major': 0, 'minor': 0, 'patch': 0};
  int tocOffset = 0;
  List<String> tokens = [];
  List<int> strings = [];
  List<String> paths = [];
  Map<String, dynamic> sections = {};
  Map<String, dynamic> specsByPath = {};
  List<Map<String, dynamic>> fields = [];
  List<int> fieldSets = [];
  List<UsdcSpec> specs = [];

  ByteData conversionView = ByteData(0);

  /// Parse USDC file and return raw spec data without building Three.js scene.
  /// Used by USDComposer for unified scene composition.
  Map<String, Map<String, dynamic>> parseData(Uint8List inputBuffer) {
    buffer = inputBuffer.buffer;
    reader = BinaryReader(buffer);

    // Pre-allocate conversion tools for fast local computations
    final conversionBuffer = Uint8List(4);
    conversionView = ByteData.view(conversionBuffer.buffer);

    // Read internal USDC structure tables sequential steps
    _readBootstrap();
    _readTOC();
    _readTokens();
    _readStrings();
    _readFields();
    _readFieldSets();
    _readPaths();
    _readSpecs();

    // Build specsByPath without building scene
    final Map<String, Map<String, dynamic>> specsByPathLocal = {};

    for (final dynamic spec in specs) {
      // Safety verification check on indices bounds
      final int pathIndex = spec.pathIndex as int;
      if (pathIndex < 0 || pathIndex >= paths.length) continue;

      final String path = paths[pathIndex];
      final Map<String, dynamic> fields = _getFieldsForSpec(spec);

      specsByPathLocal[path] = {
        'specType': spec.specType, // Maps to your SpecType configuration parameters
        'fields': fields,
      };
    }

    specsByPath = specsByPathLocal;
    return {'specsByPath': specsByPathLocal};
  }

  void _readBootstrap() {
    final BinaryReader localReader = reader;
    localReader.seek(0);

    // Read magic "PXR-USDC"
    final String magic = localReader.readString(8);
    if (magic != 'PXR-USDC') {
      throw const FormatException('THREE.USDCParser: Not a valid USDC file.');
    }

    // Read version
    version['major'] = localReader.readUint8();
    version['minor'] = localReader.readUint8();
    version['patch'] = localReader.readUint8();

    localReader.readBytes(5); // Skip remaining version bytes

    // Read TOC offset
    tocOffset = localReader.readUint64();

    // Skip reserved bytes (rest of 128-byte header)
    // Already at offset 24, skip to end of bootstrap (88 bytes total for bootstrap struct)
  }

  void _readTOC() {
    final BinaryReader localReader = reader;
    localReader.seek(tocOffset);

    // Read number of sections
    final int numSections = localReader.readUint64();
    
    final Map<String, Map<String, int>> sectionsLocal = {};

    for (int i = 0; i < numSections; i++) {
      final String name = localReader.readString(16);
      final int start = localReader.readUint64();
      final int size = localReader.readUint64();
      
      sectionsLocal[name] = {
        'start': start,
        'size': size,
      };
    }

    sections = sectionsLocal;
  }

  void _readTokens() {
    final Map<String, int>? section = sections['TOKENS'];
    if (section == null) return;

    final BinaryReader localReader = reader;
    localReader.seek(section['start'] ?? 0);

    final int numTokens = localReader.readUint64();
    final List<String> tokensLocal = [];

    final int major = version['major'] ?? 0;
    final int minor = version['minor'] ?? 0;

    if (major == 0 && minor < 4) {
      // Uncompressed tokens (version < 0.4.0)
      final int tokensNumBytes = localReader.readUint64();
      final Uint8List tokensData = localReader.readBytes(tokensNumBytes);
      
      int strStart = 0;
      for (int i = 0; i < numTokens; i++) {
        int strEnd = strStart;
        while (strEnd < tokensData.length && tokensData[strEnd] != 0) {
          strEnd++;
        }
        
        tokensLocal.add(utf8.decode(Uint8List.sublistView(tokensData, strStart, strEnd)));
        strStart = strEnd + 1;
      }
    } else {
      // Compressed tokens (version >= 0.4.0)
      final int uncompressedSize = localReader.readUint64();
      final int compressedSize = localReader.readUint64();
      final Uint8List compressedData = localReader.readBytes(compressedSize);
      
      final Uint8List tokensData = decompressLZ4(compressedData, uncompressedSize);
      
      int strStart = 0;
      for (int i = 0; i < numTokens; i++) {
        int strEnd = strStart;
        while (strEnd < tokensData.length && tokensData[strEnd] != 0) {
          strEnd++;
        }
        
        tokensLocal.add(utf8.decode(Uint8List.sublistView(tokensData, strStart, strEnd)));
        strStart = strEnd + 1;
      }
    }

    tokens = tokensLocal;
  }

  void _readStrings() {
    final Map<String, int>? section = sections['STRINGS'];
    if (section == null) {
      strings = [];
      return;
    }

    final BinaryReader localReader = reader;
    localReader.seek(section['start'] ?? 0);

    // Strings section has an 8-byte count prefix, but string indices stored
    // elsewhere in the file are relative to the section start (not the data).
    // So we read the entire section as uint32 values to maintain correct indexing.
    final int sectionSize = section['size'] ?? 0;
    final int numStrings = sectionSize ~/ 4; // Truncating integer division

    final List<int> stringsLocal = [];
    for (int i = 0; i < numStrings; i++) {
      stringsLocal.add(localReader.readUint32());
    }

    strings = stringsLocal;
  }

  void _readFields() {
    final Map<String, int>? section = sections['FIELDS'];
    if (section == null) return;

    final BinaryReader localReader = reader;
    localReader.seek(section['start'] ?? 0);
    
    final List<Map<String, dynamic>> fieldsLocal = [];
    final int major = version['major'] ?? 0;
    final int minor = version['minor'] ?? 0;

    if (major == 0 && minor < 4) {
      // Uncompressed fields
      final int sectionSize = section['size'] ?? 0;
      final int numFields = sectionSize ~/ 12; // 4 bytes token index + 8 bytes value rep

      for (int i = 0; i < numFields; i++) {
        final int tokenIndex = localReader.readUint32();
        
        // We can take advantage of reading a 64-bit integer directly for ValueRep
        final int rawRep64 = localReader.readUint64();
        
        fieldsLocal.add({
          'tokenIndex': tokenIndex,
          'valueRep': ValueRep(rawRep64),
        });
      }
    } else {
      // Compressed fields (version >= 0.4.0)
      final int numFields = localReader.readUint64();

      // Read compressed token indices
      final int tokenIndicesCompressedSize = localReader.readUint64();
      final Uint8List tokenIndicesCompressed = localReader.readBytes(tokenIndicesCompressedSize);
      
      // Decompress into 32-bit integer array
      final Int32List tokenIndices = decompressIntegers32(
        Uint8List.sublistView(tokenIndicesCompressed, 0, tokenIndicesCompressedSize),
        numFields,
      );

      // Read compressed value reps (LZ4 only, no integer encoding)
      final int repsCompressedSize = localReader.readUint64();
      final Uint8List repsCompressed = localReader.readBytes(repsCompressedSize);
      final Uint8List repsData = decompressLZ4(repsCompressed, numFields * 8);
      
      final ByteData repsView = ByteData.sublistView(repsData);

      for (int i = 0; i < numFields; i++) {
        // Reconstruct the 64-bit int from two 32-bit little endian reads to mimic layout safely
        final int repLo = repsView.getUint32(i * 8, Endian.little);
        final int repHi = repsView.getUint32(i * 8 + 4, Endian.little);
        
        fieldsLocal.add({
          'tokenIndex': tokenIndices[i],
          'valueRep': ValueRep.fromLoHi(repLo, repHi),
        });
      }
    }

    fields = fieldsLocal;
  }

  void _readFieldSets() {
    final Map<String, int>? section = sections['FIELDSETS'];
    if (section == null) return;

    final BinaryReader localReader = reader;
    localReader.seek(section['start'] ?? 0);
    
    final List<int> fieldSetsLocal = [];
    final int major = version['major'] ?? 0;
    final int minor = version['minor'] ?? 0;

    if (major == 0 && minor < 4) {
      // Uncompressed field sets
      final int sectionSize = section['size'] ?? 0;
      final int numFieldSets = sectionSize ~/ 4;
      
      for (int i = 0; i < numFieldSets; i++) {
        fieldSetsLocal.add(localReader.readUint32());
      }
    } else {
      // Compressed field sets
      final int numFieldSets = localReader.readUint64();
      final int compressedSize = localReader.readUint64();
      final Uint8List compressed = localReader.readBytes(compressedSize);
      
      // Decompress the index stream safely without buffer cloning
      final Int32List indices = decompressIntegers32(
        Uint8List.sublistView(compressed, 0, compressedSize),
        numFieldSets,
      );
      
      for (int i = 0; i < numFieldSets; i++) {
        fieldSetsLocal.add(indices[i]);
      }
    }

    fieldSets = fieldSetsLocal;
  }

  void _readPaths() {
    final Map<String, int>? section = sections['PATHS'];
    if (section == null) return;

    final BinaryReader localReader = reader;
    localReader.seek(section['start'] ?? 0);

    final int numPaths = localReader.readUint64();
    
    // Allocate the paths list dynamically with a pre-filled value
    paths = List<String>.filled(numPaths, '');

    final int major = version['major'] ?? 0;
    final int minor = version['minor'] ?? 0;

    if (major == 0 && minor < 4) {
      // Uncompressed paths - recursive tree structure
      _readPathsRecursive('');
    } else {
      // Compressed paths (version >= 0.4.0)
      // Read duplicate numPaths value (matches numPaths above)
      localReader.readUint64();

      final int compressedSize1 = localReader.readUint64();
      final Uint8List pathIndicesCompressed = localReader.readBytes(compressedSize1);
      final Int32List pathIndices = decompressIntegers32(
        Uint8List.sublistView(pathIndicesCompressed, 0, compressedSize1),
        numPaths,
      );

      final int compressedSize2 = localReader.readUint64();
      final Uint8List elementTokenIndicesCompressed = localReader.readBytes(compressedSize2);
      final Int32List elementTokenIndices = decompressIntegers32(
        Uint8List.sublistView(elementTokenIndicesCompressed, 0, compressedSize2),
        numPaths,
      );

      final int compressedSize3 = localReader.readUint64();
      final Uint8List jumpsCompressed = localReader.readBytes(compressedSize3);
      final Int32List jumps = decompressIntegers32(
        Uint8List.sublistView(jumpsCompressed, 0, compressedSize3),
        numPaths,
      );

      // Build paths from compressed data
      _buildPathsFromCompressed(pathIndices, elementTokenIndices, jumps);
    }
  }

  void _readPathsRecursive(String parentPath, [int depth = 0]) {
    final BinaryReader localReader = reader;
    
    // Prevent infinite recursion
    if (depth > 1000) return;

    // Read path item header
    final int index = localReader.readUint32();
    final int elementTokenIndex = localReader.readUint32();
    final int bits = localReader.readUint8();
    
    final bool hasChild = (bits & 1) != 0;
    final bool hasSibling = (bits & 2) != 0;
    final bool isPrimProperty = (bits & 4) != 0;

    // Build path
    String path;
    if (parentPath.isEmpty) {
      path = '/';
    } else {
      // Safely look up token bounds
      final String elemToken = (elementTokenIndex >= 0 && elementTokenIndex < tokens.length)
          ? tokens[elementTokenIndex]
          : '';
          
      if (isPrimProperty) {
        path = '$parentPath.$elemToken';
      } else {
        path = parentPath == '/' ? '/$elemToken' : '$parentPath/$elemToken';
      }
    }

    // Assign to our pre-allocated array space safely
    if (index >= 0 && index < paths.length) {
      paths[index] = path;
    }

    // Process children and siblings
    if (hasChild && hasSibling) {
      // Read sibling offset
      final int siblingOffset = localReader.readUint64();
      
      // Read child
      _readPathsRecursive(path, depth + 1);
      
      // Read sibling
      localReader.seek(siblingOffset);
      _readPathsRecursive(parentPath, depth + 1);
    } else if (hasChild) {
      _readPathsRecursive(path, depth + 1);
    } else if (hasSibling) {
      _readPathsRecursive(parentPath, depth + 1);
    }
  }

  void _buildPathsFromCompressed(
    Int32List pathIndices,
    Int32List elementTokenIndices,
    Int32List jumps,
  ) {
    // Jump encoding from USD:
    //  0 = only sibling (no child), next entry is sibling
    // -1 = only child (no sibling), next entry is child
    // -2 = leaf (no child, no sibling)
    // >0 = has both child and sibling, value is offset to sibling

    void buildPaths(int startIndex, String parentPath) {
      int curIndex = startIndex;
      String currentParentPath = parentPath;

      while (curIndex < pathIndices.length) {
        final int thisIndex = curIndex++;
        final int pathIndex = pathIndices[thisIndex];
        final int elementTokenIndex = elementTokenIndices[thisIndex];
        final int jump = jumps[thisIndex];

        // Build path
        String path;
        if (currentParentPath.isEmpty) {
          path = '/';
          currentParentPath = path;
        } else {
          final int tokenIndex = elementTokenIndex.abs();
          final String elemToken = (tokenIndex >= 0 && tokenIndex < tokens.length)
              ? tokens[tokenIndex]
              : '';
              
          final bool isPrimProperty = elementTokenIndex < 0;
          
          if (isPrimProperty) {
            path = '$currentParentPath.$elemToken';
          } else {
            path = currentParentPath == '/' ? '/$elemToken' : '$currentParentPath/$elemToken';
          }
        }

        if (pathIndex >= 0 && pathIndex < paths.length) {
          paths[pathIndex] = path;
        }

        // Determine children and siblings
        final bool hasChild = jump > 0 || jump == -1;
        final bool hasSibling = jump >= 0;

        if (hasChild) {
          if (hasSibling) {
            // Has both child and sibling
            // Recursively process sibling subtree
            final int siblingIndex = thisIndex + jump;
            buildPaths(siblingIndex, currentParentPath);
          }
          // Child is next entry, continue with new parent path
          currentParentPath = path;
        } else if (hasSibling) {
          // Only sibling, next entry is sibling with same parent
          // Just continue loop with curIndex and same currentParentPath
        } else {
          // Leaf node, exit loop
          break;
        }
      }
    }

    buildPaths(0, '');
  }

  void _readSpecs() {
    final Map<String, int>? section = sections['SPECS'];
    if (section == null) return;

    final BinaryReader localReader = reader;
    localReader.seek(section['start'] ?? 0);

    final List<UsdcSpec> specsLocal = [];
    final int major = version['major'] ?? 0;
    final int minor = version['minor'] ?? 0;
    final int patch = version['patch'] ?? 0;

    if (major == 0 && minor < 4) {
      // Uncompressed specs
      // Each spec: pathIndex (4), fieldSetIndex (4), specType (4) = 12 bytes
      // For version 0.0.1 there may be different padding
      final int specSize = (minor == 0 && patch == 1) ? 16 : 12;
      final int sectionSize = section['size'] ?? 0;
      final int numSpecs = sectionSize ~/ specSize;

      for (int i = 0; i < numSpecs; i++) {
        final int pathIndex = localReader.readUint32();
        final int fieldSetIndex = localReader.readUint32();
        final int specType = localReader.readUint32();
        
        if (specSize == 16) {
          localReader.readUint32(); // skip padding
        }
        
        specsLocal.add(UsdcSpec(
          pathIndex: pathIndex,
          fieldSetIndex: fieldSetIndex,
          specType: specType,
        ));
      }
    } else {
      // Compressed specs
      final int numSpecs = localReader.readUint64();

      final int compressedSize1 = localReader.readUint64();
      final Uint8List pathIndicesCompressed = localReader.readBytes(compressedSize1);
      final Int32List pathIndices = decompressIntegers32(
        Uint8List.sublistView(pathIndicesCompressed, 0, compressedSize1),
        numSpecs,
      );

      final int compressedSize2 = localReader.readUint64();
      final Uint8List fieldSetIndicesCompressed = localReader.readBytes(compressedSize2);
      final Int32List fieldSetIndices = decompressIntegers32(
        Uint8List.sublistView(fieldSetIndicesCompressed, 0, compressedSize2),
        numSpecs,
      );

      final int compressedSize3 = localReader.readUint64();
      final Uint8List specTypesCompressed = localReader.readBytes(compressedSize3);
      final Int32List specTypes = decompressIntegers32(
        Uint8List.sublistView(specTypesCompressed, 0, compressedSize3),
        numSpecs,
      );

      for (int i = 0; i < numSpecs; i++) {
        specsLocal.add(UsdcSpec(
          pathIndex: pathIndices[i],
          fieldSetIndex: fieldSetIndices[i],
          specType: specTypes[i],
        ));
      }
    }

    specs = specsLocal;
  }

  dynamic _readValue(ValueRep valueRep) {
    final int type = valueRep.typeEnum;
    final bool isArray = valueRep.isArray;
    final bool isInlined = valueRep.isInlined;

    // Handle TimeSamples specially - they have their own format
    if (type == TypeEnum.timeSamples.value) {
      return _readTimeSamples(valueRep);
    }

    if (isInlined) {
      return _readInlinedValue(valueRep);
    }

    // Seek to payload offset and read value
    final int offset = valueRep.payload;
    if (offset == 0 && isArray) {
      // Spec 16.3.9.3: Array payload 0 is an explicit empty-array sentinel.
      return [];
    }

    if (offset < 0 || offset >= buffer.lengthInBytes) {
      throw RangeError('USDCParser: Invalid payload offset $offset for type $type.');
    }

    final int savedOffset = reader.tell();
    reader.seek(offset);

    dynamic value;
    if (isArray) {
      value = _readArrayValue(valueRep);
    } else {
      value = _readScalarValue(type);
    }

    reader.seek(savedOffset);
    return value;
  }

  dynamic _readInlinedValue(ValueRep valueRep) {
    final int type = valueRep.typeEnum;
    final int payload = valueRep.getInlinedValue();
    final ByteData view = conversionView;

    if (type == TypeEnum.boolean.value) {
      return payload != 0;
    } else if (type == TypeEnum.uChar.value) {
      return payload & 0xFF;
    } else if (type == TypeEnum.integer.value || type == TypeEnum.uInt.value) {
      return payload;
    } else if (type == TypeEnum.float.value) {
      view.setUint32(0, payload, Endian.little);
      return view.getFloat32(0, Endian.little);
    } else if (type == TypeEnum.doubleType.value) {
      // When a double is inlined, it's stored as float32 bits in the payload
      view.setUint32(0, payload, Endian.little);
      return view.getFloat32(0, Endian.little);
    } else if (type == TypeEnum.token.value) {
      return (payload >= 0 && payload < tokens.length) ? tokens[payload] : '';
    } else if (type == TypeEnum.string.value) {
      final int stringIdx = (payload >= 0 && payload < strings.length) ? strings[payload] : -1;
      return (stringIdx >= 0 && stringIdx < tokens.length) ? tokens[stringIdx] : '';
    } else if (type == TypeEnum.assetPath.value) {
      return (payload >= 0 && payload < tokens.length) ? tokens[payload] : '';
    } else if (type == TypeEnum.specifier.value) {
      return payload; // 0=def, 1=over, 2=class
    } else if (type == TypeEnum.permission.value || type == TypeEnum.variability.value) {
      return payload;
    } else if (type == TypeEnum.vec2h.value) {
      // Vec2h: Two half-floats fit in 4 bytes, stored directly
      view.setUint32(0, payload, Endian.little);
      return [
        _halfToFloat(view.getUint16(0, Endian.little)),
        _halfToFloat(view.getUint16(2, Endian.little))
      ];
    } else if (type == TypeEnum.vec2f.value || type == TypeEnum.vec2i.value) {
      view.setUint32(0, payload, Endian.little);
      return [view.getInt8(0), view.getInt8(1)];
    } else if (type == TypeEnum.vec3f.value || type == TypeEnum.vec3i.value) {
      view.setUint32(0, payload, Endian.little);
      return [view.getInt8(0), view.getInt8(1), view.getInt8(2)];
    } else if (type == TypeEnum.vec4f.value || type == TypeEnum.vec4i.value) {
      view.setUint32(0, payload, Endian.little);
      return [view.getInt8(0), view.getInt8(1), view.getInt8(2), view.getInt8(3)];
    } else if (type == TypeEnum.matrix2d.value) {
      // Inlined Matrix2d stores diagonal values as 2 signed int8 values
      view.setUint32(0, payload, Endian.little);
      final int d0 = view.getInt8(0);
      final int d1 = view.getInt8(1);
      return [d0, 0, 0, d1];
    } else if (type == TypeEnum.matrix3d.value) {
      // Inlined Matrix3d stores diagonal values as 3 signed int8 values
      view.setUint32(0, payload, Endian.little);
      final int d0 = view.getInt8(0);
      final int d1 = view.getInt8(1);
      final int d2 = view.getInt8(2);
      return [d0, 0, 0, 0, d1, 0, 0, 0, d2];
    } else if (type == TypeEnum.matrix4d.value) {
      // Inlined Matrix4d stores diagonal values as 4 signed int8 values
      view.setUint32(0, payload, Endian.little);
      final int d0 = view.getInt8(0);
      final int d1 = view.getInt8(1);
      final int d2 = view.getInt8(2);
      final int d3 = view.getInt8(3);
      return [d0, 0, 0, 0, 0, d1, 0, 0, 0, 0, d2, 0, 0, 0, 0, d3];
    } else {
      return payload;
    }
  }

  Map<String, dynamic> _readTimeSamples(ValueRep valueRep) {
    final BinaryReader localReader = reader;
    final int offset = valueRep.payload;
    final int savedOffset = localReader.tell();
    
    localReader.seek(offset);

    // TimeSamples format uses RELATIVE offsets (from OpenUSD _RecursiveRead):
    // _RecursiveRead: read int64 relativeOffset at current position, then seek to start + relativeOffset
    // After reading timesRep, continue reading from current position (after timesRep)
    // Layout at TimeSamples location:
    // - int64 timesOffset (relative from start of this int64)
    // At (start + timesOffset): timesRep ValueRep, then int64 valuesOffset, then numValues + ValueReps
    
    // Read times relative offset and resolve
    final int timesStart = localReader.tell();
    final int timesRelOffset = localReader.readInt64();
    localReader.seek(timesStart + timesRelOffset);
    
    // Read the 64-bit packed ValueRep for times in a single read
    final int rawTimesRep64 = localReader.readUint64();
    final ValueRep timesRep = ValueRep(rawTimesRep64);

    // Resolve times array recursively
    final dynamic times = _readValue(timesRep);

    // Continue reading from current position (after timesRep)
    // The second _RecursiveRead reads from CURRENT position, not from the beginning
    final int afterTimesRep = timesStart + timesRelOffset + 8;
    localReader.seek(afterTimesRep);

    // Read values relative offset
    final int valuesStart = localReader.tell();
    final int valuesRelOffset = localReader.readInt64();
    localReader.seek(valuesStart + valuesRelOffset);

    // Read number of values
    final int numValues = localReader.readUint64();

    // Read all ValueReps
    final List<ValueRep> valueReps = [];
    for (int i = 0; i < numValues; i++) {
      final int rawRep64 = localReader.readUint64();
      valueReps.add(ValueRep(rawRep64));
    }

    // Resolve each value
    final List<dynamic> values = [];
    for (int i = 0; i < numValues; i++) {
      values.add(_readValue(valueReps[i]));
    }

    localReader.seek(savedOffset);

    // Convert times to a standard List<dynamic> if needed
    List<dynamic> timesArray;
    if (times is List) {
      timesArray = times;
    } else {
      timesArray = [times];
    }

    return {
      'times': timesArray,
      'values': values,
    };
  }

  dynamic _readScalarValue(int type) {
    final BinaryReader localReader = reader;

    if (type == TypeEnum.invalid.value) {
      return null;
    } else if (type == TypeEnum.boolean.value) {
      return localReader.readUint8() != 0;
    } else if (type == TypeEnum.uChar.value) {
      return localReader.readUint8();
    } else if (type == TypeEnum.integer.value) {
      return localReader.readInt32();
    } else if (type == TypeEnum.uInt.value) {
      return localReader.readUint32();
    } else if (type == TypeEnum.int64.value) {
      return localReader.readInt64();
    } else if (type == TypeEnum.uInt64.value) {
      return localReader.readUint64();
    } else if (type == TypeEnum.half.value) {
      return _readHalf();
    } else if (type == TypeEnum.float.value) {
      return localReader.readFloat32();
    } else if (type == TypeEnum.doubleType.value) {
      return localReader.readFloat64();
    } else if (type == TypeEnum.string.value || type == TypeEnum.token.value) {
      final int index = localReader.readUint32();
      return (index >= 0 && index < tokens.length) ? tokens[index] : '';
    } else if (type == TypeEnum.assetPath.value) {
      final int index = localReader.readUint32();
      return (index >= 0 && index < tokens.length) ? tokens[index] : '';
    } else if (type == TypeEnum.vec2f.value) {
      return [localReader.readFloat32(), localReader.readFloat32()];
    } else if (type == TypeEnum.vec2d.value) {
      return [localReader.readFloat64(), localReader.readFloat64()];
    } else if (type == TypeEnum.vec2i.value) {
      return [localReader.readInt32(), localReader.readInt32()];
    } else if (type == TypeEnum.vec3f.value) {
      return [localReader.readFloat32(), localReader.readFloat32(), localReader.readFloat32()];
    } else if (type == TypeEnum.vec3d.value) {
      return [localReader.readFloat64(), localReader.readFloat64(), localReader.readFloat64()];
    } else if (type == TypeEnum.vec3i.value) {
      return [localReader.readInt32(), localReader.readInt32(), localReader.readInt32()];
    } else if (type == TypeEnum.vec4f.value) {
      return [localReader.readFloat32(), localReader.readFloat32(), localReader.readFloat32(), localReader.readFloat32()];
    } else if (type == TypeEnum.vec4d.value) {
      return [localReader.readFloat64(), localReader.readFloat64(), localReader.readFloat64(), localReader.readFloat64()];
    } else if (type == TypeEnum.quatf.value) {
      return [localReader.readFloat32(), localReader.readFloat32(), localReader.readFloat32(), localReader.readFloat32()];
    } else if (type == TypeEnum.quatd.value) {
      return [localReader.readFloat64(), localReader.readFloat64(), localReader.readFloat64(), localReader.readFloat64()];
    } else if (type == TypeEnum.matrix4d.value) {
      final List<double> m = [];
      for (int i = 0; i < 16; i++) {
        m.add(localReader.readFloat64());
      }
      return m;
    } else if (type == TypeEnum.tokenVector.value) {
      final int count = localReader.readUint64();
      final List<String> tokenVec = [];
      for (int i = 0; i < count; i++) {
        final int index = localReader.readUint32();
        tokenVec.add((index >= 0 && index < tokens.length) ? tokens[index] : '');
      }
      return tokenVec;
    } else if (type == TypeEnum.pathVector.value) {
      final int count = localReader.readUint64();
      final List<String> pathVec = [];
      for (int i = 0; i < count; i++) {
        final int index = localReader.readUint32();
        pathVec.add((index >= 0 && index < paths.length) ? paths[index] : '');
      }
      return pathVec;
    } else if (type == TypeEnum.doubleVector.value) {
      final int count = localReader.readUint64();
      final Float64List arr = Float64List(count);
      for (int i = 0; i < count; i++) {
        arr[i] = localReader.readFloat64();
      }
      return arr;
    } else if (type == TypeEnum.dictionary.value) {
      final int elementCount = localReader.readUint64();
      final Map<String, dynamic> dict = {};

      for (int i = 0; i < elementCount; i++) {
        final int keyIdx = localReader.readUint32();
        final String key = (keyIdx >= 0 && keyIdx < tokens.length) ? tokens[keyIdx] : '';

        // Reader layout expects tracking using .tell() and .seek()
        final int currentPos = localReader.tell();
        final int valueOffset = localReader.readInt64();
        final int valuePos = currentPos + valueOffset;

        final int savedPos = localReader.tell();
        localReader.seek(valuePos);

        final int valueRepData = localReader.readUint64();
        final ValueRep valueRep = ValueRep(valueRepData);

        dynamic value;
        if (valueRep.isInlined) {
          value = _readInlinedValue(valueRep);
        } else if (valueRep.isArray) {
          localReader.seek(valueRep.payload);
          value = _readArrayValue(valueRep);
        } else {
          localReader.seek(valueRep.payload);
          value = _readScalarValue(valueRep.typeEnum);
        }

        localReader.seek(savedPos);

        if (key.isNotEmpty && value != null) {
          dict[key] = value;
        }
      }
      return dict;
    } else if (type == TypeEnum.tokenListOp.value ||
              type == TypeEnum.stringListOp.value ||
              type == TypeEnum.intListOp.value ||
              type == TypeEnum.int64ListOp.value ||
              type == TypeEnum.uIntListOp.value ||
              type == TypeEnum.uInt64ListOp.value) {
      return null; // Skip complex non-geometry operational types silently
    } else if (type == TypeEnum.pathListOp.value) {
      final int flags = localReader.readUint8();
      final bool hasExplicitItems = (flags & 0x02) != 0;
      final bool hasAddItems = (flags & 0x04) != 0;
      final bool hasDeleteItems = (flags & 0x08) != 0;
      final bool hasReorderItems = (flags & 0x10) != 0;
      final bool hasPrependItems = (flags & 0x20) != 0;
      final bool hasAppendItems = (flags & 0x40) != 0;

      List<String> readPathList() {
        final int itemCount = localReader.readUint64();
        final List<String> pathList = [];
        for (int i = 0; i < itemCount; i++) {
          final int pathIdx = localReader.readUint32();
          if (pathIdx >= 0 && pathIdx < paths.length) {
            pathList.add(paths[pathIdx]);
          }
        }
        return pathList;
      }

      List<String>? explicitPaths;
      List<String>? addPaths;
      List<String>? prependPaths;
      List<String>? appendPaths;

      if (hasExplicitItems) explicitPaths = readPathList();
      if (hasAddItems) addPaths = readPathList();
      if (hasPrependItems) prependPaths = readPathList();
      if (hasAppendItems) appendPaths = readPathList();
      if (hasDeleteItems) readPathList(); // Skip delete data stream block
      if (hasReorderItems) readPathList(); // Skip reorder data stream block

      if (prependPaths != null && prependPaths.isNotEmpty) return prependPaths;
      if (explicitPaths != null && explicitPaths.isNotEmpty) return explicitPaths;
      if (appendPaths != null && appendPaths.isNotEmpty) return appendPaths;
      if (addPaths != null && addPaths.isNotEmpty) return addPaths;
      return null;
    } else if (type == TypeEnum.variantSelectionMap.value) {
      final int elementCount = localReader.readUint64();
      final Map<String, String> variantMap = {};

      for (int i = 0; i < elementCount; i++) {
        final int keyIdx = localReader.readUint32();
        final int valueIdx = localReader.readUint32();

        final int stringKeyIdx = (keyIdx >= 0 && keyIdx < strings.length) ? strings[keyIdx] : -1;
        final int stringValIdx = (valueIdx >= 0 && valueIdx < strings.length) ? strings[valueIdx] : -1;

        final String key = (stringKeyIdx >= 0 && stringKeyIdx < tokens.length) ? tokens[stringKeyIdx] : '';
        final String value = (stringValIdx >= 0 && stringValIdx < tokens.length) ? tokens[stringValIdx] : '';

        if (key.isNotEmpty && value.isNotEmpty) {
          variantMap[key] = value;
        }
      }
      return variantMap;
    } else {
      console.warning('USDCParser: Unsupported scalar type: $type'); // Replaces console.warn
      return null;
    }
  }

  dynamic _readArrayValue(ValueRep valueRep) {
    final BinaryReader localReader = reader;
    final int type = valueRep.typeEnum;
    final bool isCompressed = valueRep.isCompressed;

    // Read array size
    int size;
    final int major = version['major'] ?? 0;
    final int minor = version['minor'] ?? 0;

    if (major == 0 && minor < 7) {
      size = localReader.readUint32();
    } else {
      size = localReader.readUint64();
    }

    // Dart's max integer limit on native platforms is 2^63 - 1, 
    // so we check against standard 32-bit architecture limits.
    if (size < 0 || size > 0x7FFFFFFF) {
      throw RangeError('USDCParser: Invalid or unsupported array size $size for type $type.');
    }

    if (size == 0) return [];

    // Handle compressed arrays
    if (isCompressed) {
      return _readCompressedArray(type, size);
    }

    // Read uncompressed array
    if (type == TypeEnum.integer.value) {
      final Int32List arr = Int32List(size);
      for (int i = 0; i < size; i++) {
        arr[i] = localReader.readInt32();
      }
      return arr;
    } else if (type == TypeEnum.uInt.value) {
      final Uint32List arr = Uint32List(size);
      for (int i = 0; i < size; i++) {
        arr[i] = localReader.readUint32();
      }
      return arr;
    } else if (type == TypeEnum.float.value) {
      final Float32List arr = Float32List(size);
      for (int i = 0; i < size; i++) {
        arr[i] = localReader.readFloat32();
      }
      return arr;
    } else if (type == TypeEnum.doubleType.value) {
      final Float64List arr = Float64List(size);
      for (int i = 0; i < size; i++) {
        arr[i] = localReader.readFloat64();
      }
      return arr;
    } else if (type == TypeEnum.vec2f.value) {
      final Float32List arr = Float32List(size * 2);
      for (int i = 0; i < size * 2; i++) {
        arr[i] = localReader.readFloat32();
      }
      return arr;
    } else if (type == TypeEnum.vec3f.value) {
      final Float32List arr = Float32List(size * 3);
      for (int i = 0; i < size * 3; i++) {
        arr[i] = localReader.readFloat32();
      }
      return arr;
    } else if (type == TypeEnum.vec4f.value) {
      final Float32List arr = Float32List(size * 4);
      for (int i = 0; i < size * 4; i++) {
        arr[i] = localReader.readFloat32();
      }
      return arr;
    } else if (type == TypeEnum.vec3h.value) {
      // Half-precision vec3 array (used for scales in skeletal animation)
      final Float32List arr = Float32List(size * 3);
      for (int i = 0; i < size * 3; i++) {
        arr[i] = _readHalf();
      }
      return arr;
    } else if (type == TypeEnum.quatf.value) {
      final Float32List arr = Float32List(size * 4);
      for (int i = 0; i < size * 4; i++) {
        arr[i] = localReader.readFloat32();
      }
      return arr;
    } else if (type == TypeEnum.quath.value) {
      // Half-precision quaternion array
      final Float32List arr = Float32List(size * 4);
      for (int i = 0; i < size * 4; i++) {
        arr[i] = _readHalf();
      }
      return arr;
    } else if (type == TypeEnum.matrix4d.value) {
      // 4x4 matrix array (16 doubles per matrix, row-major)
      final Float64List arr = Float64List(size * 16);
      for (int i = 0; i < size * 16; i++) {
        arr[i] = localReader.readFloat64();
      }
      return arr;
    } else if (type == TypeEnum.token.value) {
      final List<String> arr = [];
      for (int i = 0; i < size; i++) {
        final int index = localReader.readUint32();
        arr.add((index >= 0 && index < tokens.length) ? tokens[index] : '');
      }
      return arr;
    } else if (type == TypeEnum.half.value) {
      final Float32List arr = Float32List(size);
      for (int i = 0; i < size; i++) {
        arr[i] = _readHalf();
      }
      return arr;
    } else {
      console.warning('USDCParser: Unsupported array type: $type');
      return [];
    }
  }

  dynamic _readCompressedArray(int type, int size) {
    final BinaryReader localReader = reader;

    if (type == TypeEnum.integer.value || type == TypeEnum.uInt.value) {
      final int compressedSize = localReader.readUint64();
      final Uint8List compressed = localReader.readBytes(compressedSize);
      
      return decompressIntegers32(
        Uint8List.sublistView(compressed, 0, compressedSize), 
        size,
      );
    } else if (type == TypeEnum.float.value) {
      // Float compression: 'i' = compressed as ints, 't' = lookup table
      final int code = localReader.readInt8();

      if (code == floatCompressionInt) {
        final int compressedSize = localReader.readUint64();
        final Uint8List compressed = localReader.readBytes(compressedSize);
        
        final Int32List ints = decompressIntegers32(
          Uint8List.sublistView(compressed, 0, compressedSize), 
          size,
        );
        
        final Float32List floats = Float32List(size);
        for (int i = 0; i < size; i++) {
          floats[i] = ints[i].toDouble();
        }
        return floats;
      } else if (code == floatCompressionLut) {
        final int lutSize = localReader.readUint32();
        final Float32List lut = Float32List(lutSize);
        for (int i = 0; i < lutSize; i++) {
          lut[i] = localReader.readFloat32();
        }

        final int compressedSize = localReader.readUint64();
        final Uint8List compressed = localReader.readBytes(compressedSize);
        
        final Int32List indices = decompressIntegers32(
          Uint8List.sublistView(compressed, 0, compressedSize), 
          size,
        );

        final Float32List floats = Float32List(size);
        for (int i = 0; i < size; i++) {
          final int index = indices[i];
          if (index >= 0 && index < lutSize) {
            floats[i] = lut[index];
          }
        }
        return floats;
      }

      console.warning('USDCParser: Unknown float compression code $code');
      return Float32List(size);
    } else {
      console.warning('USDCParser: Unsupported compressed array type $type');
      return [];
    }
  }

  double _readHalf() {
    return _halfToFloat(reader.readUint16());
  }

  double _halfToFloat(int h) {
    final int sign = (h & 0x8000) >> 15;
    final int exp = (h & 0x7C00) >> 10;
    final int frac = h & 0x03FF;

    if (exp == 0) {
      // Zero or denormalized number
      if (frac == 0) {
        return sign != 0 ? -0.0 : 0.0;
      }
      // Denormalized: value = ±2^-14 × (frac/1024)
      return (sign != 0 ? -1.0 : 1.0) * halfDenormScale * (frac / 1024.0);
    } else if (exp == 31) {
      return frac != 0
          ? double.nan
          : (sign != 0 ? double.negativeInfinity : double.infinity);
    }

    // Pre-computed lookup table check for fast float extraction
    final double expVal = (exp >= 0 && exp < halfExponentTable.length) 
        ? halfExponentTable[exp] 
        : 0.0;

    return (sign != 0 ? -1.0 : 1.0) * expVal * (1.0 + frac / 1024.0);
  }

  Map<String, dynamic> _getFieldsForSpec(UsdcSpec spec) {
    final Map<String, dynamic> specFields = {};
    int fieldSetIndex = spec.fieldSetIndex;

    // Field sets are terminated by fieldSetTerminator
    // Limit iterations to prevent infinite loops from malformed data
    const int maxIterations = 10000;
    int iterations = 0;

    while (fieldSetIndex < fieldSets.length && iterations < maxIterations) {
      final int fieldIndex = fieldSets[fieldSetIndex];

      // Terminator marker evaluation
      if (fieldIndex == fieldSetTerminator || fieldIndex == -1) break;

      if (fieldIndex >= 0 && fieldIndex < fields.length) {
        final Map<String, dynamic> field = fields[fieldIndex];
        final int tokenIndex = field['tokenIndex'] as int;

        if (tokenIndex >= 0 && tokenIndex < tokens.length) {
          final String name = tokens[tokenIndex];
          final dynamic value = _readValue(field['valueRep'] as ValueRep);
          specFields[name] = value;
        }
      }

      fieldSetIndex++;
      iterations++;
    }

    return specFields;
  }
}