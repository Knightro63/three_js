part of three_webgl;

class WebGLAttributes {
  dynamic gl;
  WebGLCapabilities capabilities;

  bool isWebGL2 = true;

  WeakMap buffers = WeakMap();

  WebGLAttributes(this.gl, this.capabilities) {
    isWebGL2 = capabilities.isWebGL2;
  }

  Map<String, dynamic> createBuffer(BufferAttribute<NativeArray<num>> attribute, int bufferType, {String? name}) {
    final array = attribute.array;
    final usage = attribute.usage;

    dynamic type = gl.FLOAT;
    int bytesPerElement = 4;

    final buffer = gl.createBuffer();

    gl.bindBuffer(bufferType, buffer);

    gl.bufferData(bufferType, array.lengthInBytes, array, usage);

    if (attribute.onUploadCallback != null) {
      attribute.onUploadCallback!();
    }

    if (attribute is Float32BufferAttribute) {
      type = gl.FLOAT;
      bytesPerElement = Float32List.bytesPerElement;
    } 
    else if (attribute is Float64BufferAttribute) {
      console.error('WebGLAttributes: Unsupported data buffer format: Float64Array.');
    } 
    else if (attribute is Float16BufferAttribute) {
      if (isWebGL2) {
        bytesPerElement = 2;
        type = gl.HALF_FLOAT;
      } else {
        console.error('WebGLAttributes: Usage of Float16BufferAttribute requires WebGL2.');
      }
    } else if (attribute is Uint16BufferAttribute) {
      bytesPerElement = Uint16List.bytesPerElement;
      type = gl.UNSIGNED_SHORT;
    } else if (attribute is Int16BufferAttribute) {
      bytesPerElement = Int16List.bytesPerElement;

      type = gl.SHORT;
    } else if (attribute is Uint32BufferAttribute) {
      bytesPerElement = Uint32List.bytesPerElement;

      type = gl.UNSIGNED_INT;
    } else if (attribute is Int32BufferAttribute) {
      bytesPerElement = Int32List.bytesPerElement;
      type = gl.INT;
    } else if (attribute is Int8BufferAttribute) {
      bytesPerElement = Int8List.bytesPerElement;
      type = gl.BYTE;
    } else if (attribute is Uint8BufferAttribute) {
      bytesPerElement = Uint8List.bytesPerElement;
      type = gl.UNSIGNED_BYTE;
    }

    return {
      "buffer": buffer,
      "type": type,
      "bytesPerElement": bytesPerElement,
      "array": array,
      "version": attribute.version
    };
  }

  void updateBuffer(buffer, attribute, bufferType) {
    final array = attribute.array;
    final updateRange = attribute.updateRange;

    gl.bindBuffer(bufferType, buffer);

    if (updateRange["count"] == -1) {
      // Not using update ranges
      gl.bufferSubData(bufferType, 0, array, 0, array.lengthInBytes);
    } else {
      print(" WebGLAttributes.dart gl.bufferSubData need debug confirm.... ");
      gl.bufferSubData(bufferType, updateRange["offset"] * attribute.itemSize, array, updateRange["offset"], updateRange["count"]);

      updateRange["count"] = -1; // reset range

    }
  }

  dynamic get(BaseBufferAttribute attribute) {
    if (attribute.type == "InterleavedBufferAttribute") {
      return buffers.get(attribute.data!);
    } 
    else {
      return buffers.get(attribute);
    }
  }

  void remove(BufferAttribute attribute) {
    if (attribute.type == "InterleavedBufferAttribute") {
      final data = buffers.get(attribute.data);

      if (data) {
        gl.deleteBuffer(data.buffer);

        buffers.delete(attribute.data);
      }
    } else {
      final data = buffers.get(attribute);

      if (data != null) {
        gl.deleteBuffer(data["buffer"]);

        buffers.delete(attribute);
      }
    }
  }

  void update(attribute, bufferType, {String? name}) {
    if (attribute.type == "GLBufferAttribute") {
      final cached = buffers.get(attribute);

      if (cached == null || cached["version"] < attribute.version) {
        buffers.add(key: attribute, value: createBuffer(attribute, bufferType, name: name));
      }

      return;
    }

    if (attribute.type == "InterleavedBufferAttribute") {
      attribute = attribute.data;
    }

    final data = buffers.get(attribute);

    if (data == null) {
      buffers.add(key: attribute, value: createBuffer(attribute, bufferType, name: name));
    } else if (data["version"] < attribute.version) {
      updateBuffer(data["buffer"], attribute, bufferType);
      data["version"] = attribute.version;
    }
  }
}
