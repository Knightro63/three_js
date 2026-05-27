import 'dart:typed_data';
import 'package:gpux/gpux.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import '../descriptors/gpu_buffer_descriptor.dart';
import '../descriptors/gpu_command_encoder_descriptor.dart';
import 'gpu_utils.dart';

// Shared file descriptors initialized from your recently converted files
final GPUBufferDescriptor _bufferDescriptor = GPUBufferDescriptor();
final GPUCommandEncoderDescriptor _commandEncoderDescriptor = GPUCommandEncoderDescriptor();

/// Mapping of Dart Type tags to WebGPU vertex format prefixes.
/// Maps specific native typed list objects directly to their WGSL format alternatives.
final Map<Type, List<String>> _typedArraysToVertexFormatPrefix = {
  Int8List: ['sint8', 'snorm8'],
  Uint8List: ['uint8', 'unorm8'],
  Int16List: ['sint16', 'snorm16'],
  Uint16List: ['uint16', 'unorm16'],
  Int32List: ['sint32', 'snorm32'],
  Uint32List: ['uint32', 'unorm32'],
  Float32List: ['float32'],
  // Float16 handles its type configuration natively under core frameworks, included for parity
  Float64List: ['float16'] 
};

/// Mapping unique typed vertex attributes configurations.
final Map<Type, List<String>> _typedAttributeToVertexFormatPrefix = {
  Float16BufferAttribute: ['float16']
};

/// Mapping overrides optimized for item size 1 parameters layout.
final Map<Type, String> _typeArraysToVertexFormatPrefixForItemSize1 = {
  Int32List: 'sint32',
  Int16List: 'sint32', // Patch for INT16 alignment properties
  Uint32List: 'uint32',
  Uint16List: 'uint32', // Patch for UINT16 alignment properties
  Float32List: 'float32'
};

/// A WebGPU backend utility module for managing shader attributes.
class WebGPUAttributeUtils {
  /// A reference to the WebGPU backend context instance.
  final dynamic backend;

  /// Constructs a new utility object.
  WebGPUAttributeUtils(this.backend);

  /// Creates the GPU buffer for the given buffer attribute.
  /// 
  /// [attribute] - The buffer attribute.
  /// [usage] - A flag that indicates how the buffer may be used after its creation.
  void createAttribute(dynamic attribute, int usage) {
    final dynamic bufferAttribute = this._getBufferAttribute(attribute);
    final dynamic backend = this.backend;
    
    // Enforcing your map directive bracket syntax rules instead of backend.get()
    final dynamic bufferData = backend[bufferAttribute];
    dynamic buffer = bufferData?['buffer'];

    if (buffer == null) {
      final dynamic device = backend.device;
      dynamic array = bufferAttribute.array;

      // Patch for INT8, INT16, UINT8, and UINT16 un-normalized buffer entries alignment
      if (attribute.normalized == false) {
        if (array is Int16List || array is Int8List) {
          array = Int32List.fromList(array);
        } else if (array is Uint16List || array is Uint8List) {
          array = Uint32List.fromList(array);
          
          // Verify against the backend hardware buffer index configuration mask
          if ((usage & GpuBufferUsage.index) != 0) {
            for (int i = 0; i < array.length; i++) {
              if (array[i] == 0xffff) {
                array[i] = 0xffffffff; // Use the correct 32-bit primitive restart index rule
              }
            }
          }
        }
      }

      bufferAttribute.array = array;

      // WebGPU requires standard 4-element vectors for 3-component vec3 data inside storage layouts
      if ((bufferAttribute is StorageBufferAttribute == true || 
           bufferAttribute is StorageInstancedBufferAttribute == true) && 
          bufferAttribute.itemSize == 3) {
        
        // Allocate a new list with 4 slots per item element block
        final int targetCount = bufferAttribute.count * 4;
        dynamic alignedArray;
        
        if (array is Float32List) {
          alignedArray = Float32List(targetCount);
        } else if (array is Int32List) {
          alignedArray = Int32List(targetCount);
        } else if (array is Uint32List) {
          alignedArray = Uint32List(targetCount);
        } else {
          alignedArray = List<num>.filled(targetCount, 0);
        }

        for (int i = 0; i < bufferAttribute.count; i++) {
          final int srcStart = i * 3;
          final int dstStart = i * 4;
          
          // Perform sub-array slice data copying across standard memory blocks
          for (int j = 0; j < 3; j++) {
            alignedArray[dstStart + j] = bufferAttribute.array[srcStart + j];
          }
        }

        // Update the operational parameters tracking descriptions inside bufferAttribute
        bufferAttribute.itemSize = 4;
        bufferAttribute.array = alignedArray;
        array = alignedArray;
        
        bufferData['_force3to4BytesAlignment'] = true;
      }

      // Ensure proper 4-byte padding alignment constraints matching WebGPU specifications
      final int byteLength = array.byteLength;
      final int size = byteLength + ((4 - (byteLength % 4)) % 4);

      _bufferDescriptor.label = bufferAttribute.name ?? '';
      _bufferDescriptor.size = size;
      _bufferDescriptor.usage = usage;
      _bufferDescriptor.mappedAtCreation = true;

      buffer = device.createBuffer(_bufferDescriptor);
      _bufferDescriptor.reset();

      // Unpack raw hardware pointer view maps to copy runtime values directly to memory blocks
      final dynamic mappedRange = buffer.getMappedRange();
      dynamic destinationView;

      if (array is Float32List) {
        destinationView = Float32List.view(mappedRange);
      } else if (array is Int32List) {
        destinationView = Int32List.view(mappedRange);
      } else if (array is Uint32List) {
        destinationView = Uint32List.view(mappedRange);
      } else if (array is Int16List) {
        destinationView = Int16List.view(mappedRange);
      } else if (array is Uint16List) {
        destinationView = Uint16List.view(mappedRange);
      } else if (array is Int8List) {
        destinationView = Int8List.view(mappedRange);
      } else if (array is Uint8List) {
        destinationView = Uint8List.view(mappedRange);
      }

      if (destinationView != null) {
        destinationView.setAll(0, array);
      }
      
      buffer.unmap();
      bufferData['buffer'] = buffer;
    }
  }

  /// Updates the GPU buffer of the given buffer attribute.
  /// 
  /// [attribute] - The buffer attribute.
  void updateAttribute(dynamic attribute) {
    final dynamic bufferAttribute = this._getBufferAttribute(attribute);
    final dynamic backend = this.backend;
    final dynamic device = backend.device;
    
    // Enforcing your map directive bracket syntax rules instead of backend.get()
    final dynamic bufferData = backend[bufferAttribute];
    final dynamic buffer = bufferData?['buffer'];
    dynamic array = bufferAttribute.array;

    // If storage buffer alignment rules forced a 3-to-4 layout, reconstruct data lists
    if (bufferData?['_force3to4BytesAlignment'] == true) {
      final int targetCount = bufferAttribute.count * 4;
      dynamic alignedArray;

      if (array is Float32List) {
        alignedArray = Float32List(targetCount);
      } else if (array is Int32List) {
        alignedArray = Int32List(targetCount);
      } else if (array is Uint32List) {
        alignedArray = Uint32List(targetCount);
      } else {
        alignedArray = List<num>.filled(targetCount, 0);
      }

      for (int i = 0; i < bufferAttribute.count; i++) {
        final int srcStart = i * 3;
        final int dstStart = i * 4;
        for (int j = 0; j < 3; j++) {
          alignedArray[dstStart + j] = bufferAttribute.array[srcStart + j];
        }
      }
      bufferAttribute.array = alignedArray;
      array = alignedArray;
    }

    final List<dynamic> updateRanges = bufferAttribute.updateRanges ?? [];

    if (updateRanges.isEmpty) {
      // Not using partial dirty ranges; overwrite the entire buffer payload
      device.queue.writeBuffer(buffer, 0, array, 0, array.length);
    } else {
      // In Dart, native TypedData buffers always match true arrays, making byteOffsetFactor 1 
      // when addressing elements, or array.elementSizeInBytes for pure hardware byte offsets.
      const int elementOffsetFactor = 1;
      final int bytesPerElement = array.elementSizeInBytes;

      for (int i = 0, l = updateRanges.length; i < l; i++) {
        final dynamic range = updateRanges[i];
        int dataOffset;
        int size;

        if (bufferData?['_force3to4BytesAlignment'] == true) {
          final int vertexStart = (range.start / 3).floor();
          final int vertexCount = (range.count / 3).ceil();
          dataOffset = vertexStart * 4 * elementOffsetFactor;
          size = vertexCount * 4 * elementOffsetFactor;
        } else {
          dataOffset = range.start * elementOffsetFactor;
          size = range.count * elementOffsetFactor;
        }

        // bufferOffset is always passed explicitly in bytes to the hardware encoder
        final int bufferOffset = dataOffset * bytesPerElement;
        
        device.queue.writeBuffer(buffer, bufferOffset, array, dataOffset, size);
      }
      
      bufferAttribute.clearUpdateRanges();
    }
  }

  /// This method creates the vertex buffer layout data which are
  /// required when creating a render pipeline for the given render object.
  /// 
  /// Returns an array holding objects which describe the vertex buffer layout.
  List<Map<String, dynamic>> createShaderVertexBuffers(dynamic renderObject) {
    final List<dynamic> attributes = renderObject.getAttributes() ?? [];
    final Map<dynamic, Map<String, dynamic>> vertexBuffers = {};

    for (int slot = 0; slot < attributes.length; slot++) {
      final dynamic geometryAttribute = attributes[slot];
      final int bytesPerElement = geometryAttribute.array.elementSizeInBytes;
      final dynamic bufferAttribute = this._getBufferAttribute(geometryAttribute);
      
      Map<String, dynamic>? vertexBufferLayout = vertexBuffers[bufferAttribute];

      if (vertexBufferLayout == null) {
        int arrayStride;
        GpuInputStepMode stepMode;

        if (geometryAttribute.isInterleavedBufferAttribute == true) {
          arrayStride = geometryAttribute.data.stride * bytesPerElement;
          stepMode = geometryAttribute.data.isInstancedInterleavedBuffer == true
              ? GpuInputStepMode.instance
              : GpuInputStepMode.vertex;
        } else {
          arrayStride = geometryAttribute.itemSize * bytesPerElement;
          stepMode = geometryAttribute.isInstancedBufferAttribute == true
              ? GpuInputStepMode.instance
              : GpuInputStepMode.vertex;
        }

        // Patch for un-normalized INT16 and UINT16 attributes aligned to 4 bytes
        if (geometryAttribute.normalized == false &&
            (geometryAttribute.array is Int16List || geometryAttribute.array is Uint16List)) {
          arrayStride = 4;
        }

        vertexBufferLayout = {
          'arrayStride': arrayStride,
          'attributes': <Map<String, dynamic>>[],
          'stepMode': stepMode
        };
        vertexBuffers[bufferAttribute] = vertexBufferLayout;
      }

      final String format = this._getVertexFormat(geometryAttribute)!;
      final int offset = (geometryAttribute is InterleavedBufferAttribute == true)
          ? geometryAttribute.offset * bytesPerElement
          : 0;

      final List<Map<String, dynamic>> subAttributes = vertexBufferLayout['attributes'];
      subAttributes.add({
        'shaderLocation': slot,
        'offset': offset,
        'format': format
      });
    }

    // Converts the collection values completely back into a standard Flutter array list
    return vertexBuffers.values.toList();
  }

  /// Destroys the GPU buffer of the given buffer attribute.
  /// 
  /// [attribute] - The buffer attribute.
  void destroyAttribute(dynamic attribute) {
    final dynamic backend = this.backend;
    
    // Enforcing your map directive bracket syntax rules instead of backend.get()
    final dynamic data = backend[this._getBufferAttribute(attribute)];
    
    if (data != null && data['buffer'] != null) {
      data['buffer'].destroy();
    }
    
    // Remove the resource track configuration natively from the backend mapping cache
    backend.remove(attribute);
  }

  /// This method performs a readback operation by moving buffer data from
  /// a storage buffer attribute from the GPU to the CPU. ReadbackBuffer can
  /// be used to retain and reuse handles to the intermediate buffers and prevent
  /// new allocation.
  /// 
  /// Returns a [Future] that resolves with the buffer data when the data are ready.
  Future<dynamic> getArrayBufferAsync(
    dynamic attribute, [
    dynamic target = null, 
    int offset = 0, 
    int count = -1
  ]) async {
    final dynamic backend = this.backend;
    final dynamic device = backend.device;
    
    // Enforcing your map directive bracket syntax rules instead of backend.get()
    final dynamic data = backend[this._getBufferAttribute(attribute)];
    final dynamic bufferGPU = data?['buffer'];
    
    final int byteLength = (count == -1) ? (bufferGPU.size - offset).toInt() : count;
    dynamic readBufferGPU;

    if (target != null && target.isReadbackBuffer == true) {
      final dynamic readbackInfo = backend[target];

      if (target._mapped == true) {
        throw Exception('THREE.WebGPUAttributeUtils: ReadbackBuffer must be released before being used again.');
      }
      target._mapped = true;

      // Initialize the GPU-side read copy buffer if it is not present
      if (readbackInfo['readBufferGPU'] == null) {
        _bufferDescriptor.label = '${target.name}_readback';
        _bufferDescriptor.size = target.maxByteLength;
        _bufferDescriptor.usage = GpuBufferUsage.copyDst | GpuBufferUsage.mapRead;
        
        readBufferGPU = device.createBuffer(_bufferDescriptor);
        _bufferDescriptor.reset();

        // Release/dispose structural lifecycle callbacks
        dynamic readBufferGPUToCapture = readBufferGPU;
        
        void releaseCallback(dynamic event) {
          target.buffer = null;
          target._mapped = false;
          readBufferGPUToCapture.unmap();
        }

        void disposeCallback(dynamic event) {
          target.buffer = null;
          target._mapped = false;
          readBufferGPUToCapture.destroy();
          backend.remove(target); // Replaces backend.delete
          
          target.removeEventListener('release', releaseCallback);
          target.removeEventListener('dispose', disposeCallback);
        }

        target.addEventListener('release', releaseCallback);
        target.addEventListener('dispose', disposeCallback);

        // Register the newly created hardware buffer references inside state maps
        readbackInfo['readBufferGPU'] = readBufferGPU;
      } else {
        readBufferGPU = readbackInfo['readBufferGPU'];
      }
    } else {
      // Create a temporary staging buffer for dynamic array readbacks
      _bufferDescriptor.label = '${attribute.name}_readback';
      _bufferDescriptor.size = byteLength;
      _bufferDescriptor.usage = GpuBufferUsage.copyDst | GpuBufferUsage.mapRead;
      
      readBufferGPU = device.createBuffer(_bufferDescriptor);
      _bufferDescriptor.reset();
    }

    // Record and dispatch the hardware memory copy operations
    _commandEncoderDescriptor.label = 'readback_encoder_${attribute.name}';
    final dynamic cmdEncoder = device.createCommandEncoder(_commandEncoderDescriptor);
    _commandEncoderDescriptor.reset();
    
    cmdEncoder.copyBufferToBuffer(bufferGPU, offset, readBufferGPU, 0, byteLength);
    
    final dynamic gpuCommands = cmdEncoder.finish();
    submit(device, gpuCommands);

    // Map the GPU memory asynchronously into CPU space
    await readBufferGPU.mapAsync(GpuMapMode.read, 0, byteLength);

    if (target == null) {
      // Return a new cloned array slice buffer and clean up the GPU staging handles
      final dynamic arrayBuffer = readBufferGPU.getMappedRange(0, byteLength);
      
      // Mimic slice() via native memory views replication inside standard Dart memory
      final ByteData result = ByteData(byteLength);
      final ByteData sourceView = ByteData.view(arrayBuffer);
      
      for (int i = 0; i < byteLength; i++) {
        result.setUint8(i, sourceView.getUint8(i));
      }

      readBufferGPU.destroy();
      return result.buffer; // Returns the underlying ByteBuffer layout
    } else if (target.isReadbackBuffer == true) {
      // Assign the unmanaged hardware memory pointer to the readback handle
      target.buffer = readBufferGPU.getMappedRange(0, byteLength);
      return target;
    } else {
      // Copy data directly into the pre-allocated destination buffer context
      final dynamic arrayBuffer = readBufferGPU.getMappedRange(0, byteLength);
      
      final ByteData srcView = ByteData.view(arrayBuffer);
      final ByteData dstView =ByteData.view(target is ByteBuffer ? target : target.buffer);
      
      for (int i = 0; i < byteLength; i++) {
        dstView.setUint8(i, srcView.getUint8(i));
      }
      
      readBufferGPU.destroy();
      return target;
    }
  }

  /// Returns the vertex format of the given buffer attribute.
  /// 
  /// Returns the vertex format string (e.g. 'float32x3').
  String? _getVertexFormat(dynamic geometryAttribute) {
    final int itemSize = geometryAttribute.itemSize ?? 1;
    final bool normalized = geometryAttribute.normalized ?? false;
    
    final dynamic array = geometryAttribute.array;
    final Type arrayType = array.runtimeType;
    final Type attributeType = geometryAttribute.runtimeType;
    
    String? format;

    if (itemSize == 1) {
      format = _typeArraysToVertexFormatPrefixForItemSize1[arrayType];
    } else {
      final List<String>? prefixOptions = _typedAttributeToVertexFormatPrefix[attributeType] ?? 
          _typedArraysToVertexFormatPrefix[arrayType];
          
      if (prefixOptions != null) {
        final int index = normalized ? 1 : 0;
        // Safeguard array bounds if the prefix list only contains an un-normalized format configuration
        final String? prefix = index < prefixOptions.length ? prefixOptions[index] : prefixOptions[0];

        if (prefix != null) {
          final int bytesPerElement = array.elementSizeInBytes;
          final int bytesPerUnit = bytesPerElement * itemSize;
          final int paddedBytesPerUnit = ((bytesPerUnit + 3) / 4).floor() * 4;
          
          final double paddedItemSize = paddedBytesPerUnit / bytesPerElement;

          // Check if the calculation yields a non-integer fractional padding mismatch
          if (paddedItemSize % 1 != 0) {
            throw Exception('THREE.WebGPUAttributeUtils: Bad vertex format item size.');
          }

          format = '${prefix}x${paddedItemSize.toInt()}';
        }
      }
    }

    if (format == null) {
      console.error('WebGPUAttributeUtils: Vertex format not supported yet.');
    }

    return format;
  }

  /// Utility method for handling interleaved buffer attributes correctly.
  /// To process them, their `InterleavedBuffer` is returned.
  dynamic _getBufferAttribute(dynamic attribute) {
    if (attribute.isInterleavedBufferAttribute == true) {
      attribute = attribute.data;
    }
    return attribute;
  }
}