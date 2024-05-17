part of three_webgl;

final emptyTexture = Texture();
final emptyArrayTexture = DataArrayTexture();
final empty3dTexture = Data3DTexture();
final emptyCubeTexture = CubeTexture();

// --- Utilities ---

// Array Caches (provide typed arrays for temporary by size)

Map<int, Float32Array> arrayCacheF32 = {};
Map arrayCacheI32 = {};

// Float32List caches used for uploading Matrix uniforms

final mat4array = Float32Array(16);
final mat3array = Float32Array(9);
final mat2array = Float32Array(4);

// --- Uniform Classes ---

class SingleUniform with WebGLUniformsHelper {
  late Function setValue;
  late int activeInfoType;
  late dynamic activeInfo;

  SingleUniform(id, this.activeInfo, addr) {
    this.id = id;
    this.addr = addr;
    activeInfoType = activeInfo.type;
    setValue = getSingularSetter(id, activeInfo);
  }

  // for DEBUG
  // setValue( gl, value, textures ) {

  //   String vt = value.runtimeType.toString();

  //   if(vt == "Color" || vt == "Matrix4" || vt == "Vector3" || vt == "Vector2" || vt == "Matrix3") {
  //     print("SingleUniform. setValue id: ${id} value: ${value.toJson()}  type: ${activeInfo.type} ");
  //   } else if(value.runtimeType.toString().indexOf("List<") >= 0) {
  //     final v0 = value[0];
  //     String v0t = v0.runtimeType.toString();
  //     if(v0t == "Matrix4" || v0t == "Vector3" || v0t == "Vector2" || v0t == "Matrix3" ) {
  //       print("SingleUniform. setValue id: ${id} value: ${value.map((e) => e.toJson())}  type: ${activeInfo.type} ");
  //     } else {
  //       print("SingleUniform. setValue id: ${id} value: ${value}  type: ${activeInfo.type} ");
  //     }
  //   } else {
  //     print("SingleUniform. setValue id: ${id} value: ${value} type: ${activeInfo.type} ");
  //   }

  //   Function fn = getSingularSetter( id, activeInfo );
  //   fn(gl, value, textures);
  // }

  // this.path = activeInfo.name; // DEBUG

}

class PureArrayUniform with WebGLUniformsHelper {
  late Function setValue;
  late int activeInfoType;
  late dynamic activeInfo;

  PureArrayUniform(id, this.activeInfo, addr) {
    this.id = id;
    this.addr = addr;
    cache = {};
    size = activeInfo.size;
    activeInfoType = activeInfo.type;
    setValue = getPureArraySetter(id, activeInfo);
  }

  // for DEBUG
  // setValue( gl, value, textures ) {
  //   String vt = value.runtimeType.toString();

  //   if(vt == "Color" || vt == "Matrix4" || vt == "Vector3" || vt == "Vector2" || vt == "Matrix3") {
  //     print("PureArrayUniform. setValue id: ${id} value: ${value.toJson()} type: ${activeInfo.type}");
  //   } else if(value.runtimeType.toString().indexOf("List<") >= 0) {
  //     final v0 = value[0];
  //     String v0t = v0.runtimeType.toString();
  //     if(v0t == "Matrix4" || v0t == "Vector3" || v0t == "Vector2" || v0t == "Matrix3") {
  //       print("PureArrayUniform. setValue id: ${id} value: ${value.map((e) => e.toJson())} type: ${activeInfo.type}");
  //     } else {
  //       print("PureArrayUniform. setValue id: ${id} value: ${value} type: ${activeInfo.type}");
  //     }

  //   } else {
  //     print("PureArrayUniform. setValue id: ${id} value: ${value} type: ${activeInfo.type}");
  //   }

  //   Function fn = getPureArraySetter( id, activeInfo );
  //   fn(gl, value, textures);
  // }

  // this.path = activeInfo.name; // DEBUG

  void updateCache(data) {
    final cache = this.cache;

    // if ( data is Float32Array && cache.length != data.length ) {
    //   this.cache = Float32Array( data.length );
    // }

    copyArray(cache, data);
  }
}

mixin WebGLUniform {
  late List seq;
  late Map map;
}

class StructuredUniform with WebGLUniformsHelper, WebGLUniform {
  late int activeInfoType;

  StructuredUniform(id) {
    this.id = id;
    seq = [];
    map = {};
  }

  void setValue(gl, value, textures) {
    final seq = this.seq;

    for (int i = 0, n = seq.length; i != n; ++i) {
      final u = seq[i];
      u.setValue(gl, value[u.id], textures);
    }
  }
}

// --- Top-level ---

// Parser - builds up the property tree from the path strings

final rePathPart = RegExp(r"(\w+)(\])?(\[|\.)?"); //g;

// extracts
// 	- the identifier (member name or array index)
//  - followed by an optional right bracket (found when array index)
//  - followed by an optional left bracket or dot (type of subscript)
//
// Note: These portions can be read in a non-overlapping fashion and
// allow straightforward parsing of the hierarchy that WebGL encodes
// in the uniform names.

void addUniform(WebGLUniform container, uniformObject) {
  container.seq.add(uniformObject);
  container.map[uniformObject.id] = uniformObject;
}

void parseUniform(activeInfo, addr, WebGLUniform container) {
  final path = activeInfo.name;
  final pathLength = path.length;

  // print("WebGLUniformsHelper.parseUniform path: ${path} addr: ${addr} ");

  // reset RegExp object, because of the early exit of a previous run
  // RePathPart.lastIndex = 0;

  final matches = rePathPart.allMatches(path);

  for (final match in matches) {
    dynamic id = match.group(1);
    final idIsIndex = match.group(2) == ']';
    final subscript = match.group(3);

    if (idIsIndex) id = int.parse(id); // convert to integer

    final matchEnd = match.end;

    if (subscript == null || subscript == '[' && matchEnd + 2 == pathLength) {
      // bare name or "pure" bottom-level array "[0]" suffix
      addUniform(container, subscript == null ? SingleUniform(id, activeInfo, addr) : PureArrayUniform(id, activeInfo, addr));
      break;
    } 
    else {
      // step into inner node / create it in case it doesn't exist

      final map = container.map;
      StructuredUniform? next = map[id];

      if (next == null) {
        next = StructuredUniform(id);
        addUniform(container, next);
      }

      container = next;
    }
  }
}

mixin WebGLUniformsHelper {
  // Flattening for arrays of vectors and matrices
  // id string || int
  late dynamic id;
  Map<int, dynamic> cache = <int, dynamic>{};
  dynamic addr = 0;
  late int size;

  Float32Array flatten(List array, int nBlocks, int blockSize) {
    final firstElem = array[0];

    if (firstElem is num || firstElem is double || firstElem is int) {
      List<double> array2 = [];

      for (final element in array) {
        array2.add(element.toDouble());
      }

      return Float32Array.from(array2);
    }

    // // unoptimized: ! isNaN( firstElem )
    // // see http://jacksondunstan.com/articles/983

    final n = nBlocks * blockSize;
    Float32Array? r = arrayCacheF32[n];

    if (r == null) {
      r = Float32Array(n);
      arrayCacheF32[n] = r;
    }

    if (nBlocks != 0) {
      // firstElem.toArray( r.data, 0 );

      // for ( final i = 1, offset = 0; i != nBlocks; ++ i ) {

      //   offset += blockSize;
      //   array[ i ].toArray( r.data, offset );

      // }

      for (int i = 0; i < nBlocks; i++) {
        // print(" i: ${i} this: ${this} nBlocks: ${nBlocks} ");

        List<num> data = array[i].storage.toList();

        data.asMap().forEach((index, element) {
          int idx = i * blockSize + index;
          r![idx] = element.toDouble();
        });
      }

      // bool stringKey = false;

      // if(array[0] == null) {
      //   stringKey = true;
      // }

      // if(!stringKey) {
      //   for ( final i = 0; i < nBlocks; i++ ) {
      //     List<num> _data = array[ i ].toJson();

      //     _data.asMap().forEach((index, element) {
      //       int _idx = i * blockSize + index;
      //       r[_idx] = element;
      //     });
      //   }
      // } else {
      //   for ( final i = 0; i < nBlocks; i++ ) {
      //     List<num> _data = array[ i.toString() ].toJson();

      //     _data.asMap().forEach((index, element) {
      //       int _idx = i * blockSize + index;
      //       r[_idx] = element;
      //     });
      //   }
      // }

    }

    return r;
  }

  bool arraysEqual(Map<int, dynamic> a, b) {
    if (a.keys.length != b.length) return false;

    for (int i = 0, l = a.keys.length; i < l; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  void copyArray(Map<int, dynamic> a, b) {
    final l = b.length;
    a.clear();
    for (int i = 0; i < l; i++) {
      a[i] = b[i];
    }
  }

  // Texture unit allocation

  Int32List allocTexUnits(textures, n) {
    Int32List? r = arrayCacheI32[n];

    if (r == null) {
      r = Int32List(n);
      arrayCacheI32[n] = r;
    }

    for (int i = 0; i != n; ++i) {
      r[i] = textures.allocateTextureUnit();
    }

    return r;
  }

  // --- Setters ---

  // Note: Defining these methods externally, because they come in a bunch
  // and this way their names minify.

  // Single scalar

  void setValueV1f(gl, v, textures) {
    final cache = this.cache;

    if (cache[0] == v) return;

    gl.uniform1f(addr, v.toDouble());

    cache[0] = v;
  }

  // Single float vector (from flat array or three.VectorN)

  void setValueV2f(gl, v, [WebGLTextures? textures]) {
    final cache = this.cache;

    if (v.x != null) {
      if (cache[0] != v.x || cache[1] != v.y) {
        gl.uniform2f(addr, v.x, v.y);

        cache[0] = v.x;
        cache[1] = v.y;
      }
    } else {
      if (arraysEqual(cache, v)) return;

      gl.uniform2fv(addr, v);

      copyArray(cache, v);
    }
  }

  void setValueV3f(gl, v, [WebGLTextures? textures]) {
    final cache = this.cache;

    if (v is Vector3) {
      if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z) {
        gl.uniform3f(addr, v.x, v.y, v.z);

        cache[0] = v.x;
        cache[1] = v.y;
        cache[2] = v.z;
      }
    } else if (v is Color) {
      double cacheR = 0;
      double cacheG = 0;
      double cacheB = 0;

      if (cache.length >= 3) {
        cacheR = cache[0];
        cacheG = cache[1];
        cacheB = cache[2];
      }

      if (cacheR != v.red || cacheG != v.green || cacheB != v.blue) {
        gl.uniform3f(addr, v.red, v.green, v.blue);

        cache[0] = v.red;
        cache[1] = v.green;
        cache[2] = v.blue;
      }
    } else {
      if (arraysEqual(cache, v)) return;
      gl.uniform3fv(addr, Float32Array.from(v));

      copyArray(cache, v);
    }
  }

  void setValueV4f(gl, v, [WebGLTextures? textures]) {
    final cache = this.cache;

    if (v is Vector4) {
      if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z || cache[3] != v.w) {
        gl.uniform4f(addr, v.x, v.y, v.z, v.w);

        cache[0] = v.x;
        cache[1] = v.y;
        cache[2] = v.z;
        cache[3] = v.w;
      }
    } else if (v is Color) {
      if (cache[0] != v.red || cache[1] != v.green || cache[2] != v.blue || cache[3] != 1.0) {
        gl.uniform4f(addr, v.red, v.green, v.blue, 1.0);

        cache[0] = v.red.toDouble();
        cache[1] = v.green.toDouble();
        cache[2] = v.blue.toDouble();
        cache[3] = 1.0;
      }
    } else if (v is List) {
      if (cache[0] != v[0] || cache[1] != v[1] || cache[2] != v[2] || cache[3] != v[3]) {
        gl.uniform4f(addr, v[0], v[1], v[2], v[3]);

        cache[0] = v[0];
        cache[1] = v[1];
        cache[2] = v[2];
        cache[3] = v[3];
      }
    } else {
      if (arraysEqual(cache, v)) return;

      gl.uniform4fv(addr, v);

      copyArray(cache, v);
    }
  }

  // Single matrix (from flat array or three.MatrixN)

  void setValueM2(gl, v, [WebGLTextures? textures]) {
    final cache = this.cache;
    final elements = v?.storage;

    if (elements == null) {
      if (arraysEqual(cache, v)) return;

      gl.uniformMatrix2fv(addr, false, v);

      copyArray(cache, v);
    } else {
      if (arraysEqual(cache, elements)) return;

      mat2array.set(List<double>.from(elements.map((e) => e.toDouble())), 0);

      gl.uniformMatrix2fv(addr, false, mat2array);

      copyArray(cache, elements);
    }
  }

  void setValueM3(gl, Matrix3? v, [WebGLTextures? textures]) {
    final cache = this.cache;
    final elements = v?.storage;

    if (elements == null) {
      if (arraysEqual(cache, v)) return;

      gl.uniformMatrix3fv(addr, false, v);

      copyArray(cache, v);
    } 
    else if(kIsWeb){
      final element = Float32Array.fromList(v!.storage);
      if (arraysEqual(cache, element)) {
        return;
      }

      gl.uniformMatrix3fv(addr, false, element);
      copyArray(cache, elements);
    }
    else {
      if (arraysEqual(cache, elements)) {
        return;
      }

      gl.uniformMatrix3fv(addr, false, elements);
      copyArray(cache, elements);
    }
  }

  void setValueM4(gl, Matrix4 v, [WebGLTextures? textures]) {
    final cache = this.cache;
    final elements = v.storage;

    if (arraysEqual(cache, elements)) {
      return;
    }

    gl.uniformMatrix4fv(addr, false, elements);
    copyArray(cache, elements);
  }

  // Single texture (2D / Cube)

  void setValueT1(gl, Texture? v, WebGLTextures textures) {
    final cache = this.cache;
    final unit = textures.allocateTextureUnit();

    if (cache[0] != unit) {
      gl.uniform1i(addr, unit);
      cache[0] = unit;
    }

    textures.setTexture2D(v ?? emptyTexture, unit);
  }

  void setValueT2DArray1(gl, v, textures) {
    final cache = this.cache;
    final unit = textures.allocateTextureUnit();

    if (cache[0] != unit) {
      gl.uniform1i(addr, unit);
      cache[0] = unit;
    }

    textures.setTexture2DArray(v ?? emptyArrayTexture, unit);
  }

  void setValueT3D1(gl, v, [WebGLTextures? textures]) {
    final cache = this.cache;
    final unit = textures!.allocateTextureUnit();

    if (cache[0] != unit) {
      gl.uniform1i(addr, unit);
      cache[0] = unit;
    }

    textures.setTexture3D(v ?? empty3dTexture, unit);
  }

  void setValueT6(gl, v, [WebGLTextures? textures]) {
    final cache = this.cache;
    final unit = textures!.allocateTextureUnit();

    if (cache[0] != unit) {
      gl.uniform1i(addr, unit);
      cache[0] = unit;
    }

    textures.setTextureCube(v ?? emptyCubeTexture, unit);
  }

  // Integer / Boolean vectors or arrays thereof (always flat arrays)

  void setValueV1i(gl, v, [WebGLTextures? textures]) {
    final cache = this.cache;

    if (cache[0] == v) return;

    if (v is bool) {
      if (v) {
        gl.uniform1i(addr, 1);
      } else {
        gl.uniform1i(addr, 0);
      }
    } else {
      gl.uniform1i(addr, v.toInt());
    }

    cache[0] = v;
  }

  void setValueV2i(gl, Vector v, textures) {
    final cache = this.cache;

    if (arraysEqual(cache, v)) return;

    gl.uniform2iv(addr, 1, v.copyIntoArray());

    copyArray(cache, v.copyIntoArray());
  }

  void setValueV3i(gl, v, textures) {
    final cache = this.cache;

    if (arraysEqual(cache, v)) return;

    gl.uniform3iv(addr, v);

    copyArray(cache, v);
  }

  void setValueV4i(gl, v, textures) {
    final cache = this.cache;

    if (arraysEqual(cache, v)) return;

    gl.uniform4iv(addr, v);

    copyArray(cache, v);
  }

  // uint

  void setValueV1ui(gl, v, textures) {
    final cache = this.cache;

    if (cache[0] == v) return;

    gl.uniform1ui(addr, v);

    cache[0] = v;
  }

  void setValueV2ui(gl, v, textures) {
    final cache = this.cache;

    if (arraysEqual(cache, v)) return;

    gl.uniform2uiv(addr, v);

    copyArray(cache, v);
  }

  void setValueV3ui(gl, v, textures) {
    final cache = this.cache;

    if (arraysEqual(cache, v)) return;

    gl.uniform3uiv(addr, v);

    copyArray(cache, v);
  }

  void setValueV4ui(gl, v, textures) {
    final cache = this.cache;

    if (arraysEqual(cache, v)) return;

    gl.uniform4uiv(addr, v);

    copyArray(cache, v);
  }

  // Helper to pick the right setter for the singular case

  Function getSingularSetter(id, activeInfo) {
    final type = activeInfo.type;

    switch (type) {
      case 0x1406:
        return setValueV1f; // FLOAT
      case 0x8b50:
        return setValueV2f; // _VEC2
      case 0x8b51:
        return setValueV3f; // _VEC3
      case 0x8b52:
        return setValueV4f; // _VEC4

      case 0x8b5a:
        return setValueM2; // _MAT2
      case 0x8b5b:
        return setValueM3; // _MAT3
      case 0x8b5c:
        return setValueM4; // _MAT4

      case 0x1404:
      case 0x8b56:
        return setValueV1i; // INT, BOOL
      case 0x8b53:
      case 0x8b57:
        return setValueV2i; // _VEC2
      case 0x8b54:
      case 0x8b58:
        return setValueV3i; // _VEC3
      case 0x8b55:
      case 0x8b59:
        return setValueV4i; // _VEC4

      case 0x1405:
        return setValueV1ui; // UINT
      case 0x8dc6:
        return setValueV2ui; // _VEC2
      case 0x8dc7:
        return setValueV3ui; // _VEC3
      case 0x8dc8:
        return setValueV4ui; // _VEC4

      case 0x8b5e: // SAMPLER_2D
      case 0x8d66: // SAMPLER_EXTERNAL_OES
      case 0x8dca: // INT_SAMPLER_2D
      case 0x8dd2: // UNSIGNED_INT_SAMPLER_2D
      case 0x8b62: // SAMPLER_2D_SHADOW
        return setValueT1;

      case 0x8b5f: // SAMPLER_3D
      case 0x8dcb: // INT_SAMPLER_3D
      case 0x8dd3: // UNSIGNED_INT_SAMPLER_3D
        return setValueT3D1;

      case 0x8b60: // SAMPLER_CUBE
      case 0x8dcc: // INT_SAMPLER_CUBE
      case 0x8dd4: // UNSIGNED_INT_SAMPLER_CUBE
      case 0x8dc5: // SAMPLER_CUBE_SHADOW
        return setValueT6;

      case 0x8dc1: // SAMPLER_2D_ARRAY
      case 0x8dcf: // INT_SAMPLER_2D_ARRAY
      case 0x8dd7: // UNSIGNED_INT_SAMPLER_2D_ARRAY
      case 0x8dc4: // SAMPLER_2D_ARRAY_SHADOW
        return setValueT2DArray1;
      default:
        throw ("getSingularSetter id: $id name: ${activeInfo.name} size: ${activeInfo.size} type: ${activeInfo.type}  ");
    }
  }

  // Array of scalars
  void setValueV1fArray(gl, v, textures) {
    gl.uniform1fv(addr, v);
  }

  // Integer / Boolean vectors or arrays thereof (always flat arrays)
  void setValueV1iArray(gl, v, textures) {
    gl.uniform1iv(addr, v);
  }

  void setValueV2iArray(gl, v, textures) {
    gl.uniform2iv(addr, v);
  }

  void setValueV3iArray(gl, v, textures) {
    gl.uniform3iv(addr, v);
  }

  void setValueV4iArray(gl, v, textures) {
    gl.uniform4iv(addr, v);
  }

  // Array of vectors (flat or from THREE classes)

  void setValueV2fArray(gl, v, textures) {
    final data = flatten(v, size, 2);

    gl.uniform2fv(addr, data);
  }

  void setValueV3fArray(gl, v, textures) {
    final data = flatten(v, size, 3);

    gl.uniform3fv(addr, data);
  }

  void setValueV4fArray(gl, v, textures) {
    final data = flatten(v, size, 4);
    gl.uniform4fv(addr, data);
  }

  // Array of matrices (flat or from THREE clases)

  void setValueM2Array(gl, v, textures) {
    final data = flatten(v, size, 4);

    gl.uniformMatrix2fv(addr, false, data);
  }

  void setValueM3Array(gl, v, textures) {
    final data = flatten(v, size, 9);

    gl.uniformMatrix3fv(addr, false, data);
  }

  void setValueM4Array(gl, v, textures) {
    final data = flatten(v, size, 16);

    gl.uniformMatrix4fv(addr, false, data);
  }

  // Array of unsigned integer

  void setValueV1uiArray(gl, v, textures) {
    gl.uniform1uiv(addr, v);
  }

  // Array of unsigned integer vectors (from flat array)

  void setValueV2uiArray(gl, v, textures) {
    gl.uniform2uiv(addr, v);
  }

  void setValueV3uiArray(gl, v, textures) {
    gl.uniform3uiv(addr, v);
  }

  void setValueV4uiArray(gl, v, textures) {
    gl.uniform4uiv(addr, v);
  }

  // Array of textures (2D / 3D / Cube / 2DArray)
  void setValueT1Array(gl, v, WebGLTextures textures) {
    final n = v.length;

    final units = allocTexUnits(textures, n);

    // print("setValueT1Array n: ${n} ");
    gl.uniform1iv(addr, units);

    for (int i = 0; i != n; ++i) {
      textures.setTexture2D(v[i] ?? emptyTexture, units[i]);
    }
  }

  void setValueT3DArray(gl, v, textures) {
    final n = v.length;

    final units = allocTexUnits(textures, n);

    gl.uniform1iv(addr, units);

    for (int i = 0; i != n; ++i) {
      textures.setTexture3D(v[i] ?? empty3dTexture, units[i]);
    }
  }

  void setValueT6Array(gl, v, textures) {
    final n = v.length;

    final units = allocTexUnits(textures, n);

    gl.uniform1iv(addr, units);

    for (int i = 0; i != n; ++i) {
      textures.setTextureCube(v[i] ?? emptyCubeTexture, units[i]);
    }
  }

  void setValueT2DArrayArray(gl, v, textures) {
    final n = v.length;

    final units = allocTexUnits(textures, n);

    gl.uniform1iv(addr, units);

    for (int i = 0; i != n; ++i) {
      textures.setTexture2DArray(v[i] ?? emptyArrayTexture, units[i]);
    }
  }

  // Helper to pick the right setter for a pure (bottom-level) array

  getPureArraySetter(id, activeInfo) {
    final type = activeInfo.type;

    // print("getPureArraySetter id: ${id} type: ${activeInfo.type}  ");

    switch (type) {
      case 0x1406:
        return setValueV1fArray; // FLOAT
      case 0x8b50:
        return setValueV2fArray; // _VEC2
      case 0x8b51:
        return setValueV3fArray; // _VEC3
      case 0x8b52:
        return setValueV4fArray; // _VEC4

      case 0x8b5a:
        return setValueM2Array; // _MAT2
      case 0x8b5b:
        return setValueM3Array; // _MAT3
      case 0x8b5c:
        return setValueM4Array; // _MAT4

      case 0x1404:
      case 0x8b56:
        return setValueV1iArray; // INT, BOOL
      case 0x8b53:
      case 0x8b57:
        return setValueV2iArray; // _VEC2
      case 0x8b54:
      case 0x8b58:
        return setValueV3iArray; // _VEC3
      case 0x8b55:
      case 0x8b59:
        return setValueV4iArray; // _VEC4

      case 0x1405:
        return setValueV1uiArray; // UINT
      case 0x8dc6:
        return setValueV2uiArray; // _VEC2
      case 0x8dc7:
        return setValueV3uiArray; // _VEC3
      case 0x8dc8:
        return setValueV4uiArray; // _VEC4

      case 0x8b5e: // SAMPLER_2D
      case 0x8d66: // SAMPLER_EXTERNAL_OES
      case 0x8dca: // INT_SAMPLER_2D
      case 0x8dd2: // UNSIGNED_INT_SAMPLER_2D
      case 0x8b62: // SAMPLER_2D_SHADOW
        return setValueT1Array;

      case 0x8b5f: // SAMPLER_3D
      case 0x8dcb: // INT_SAMPLER_3D
      case 0x8dd3: // UNSIGNED_INT_SAMPLER_3D
        return setValueT3DArray;

      case 0x8b60: // SAMPLER_CUBE
      case 0x8dcc: // INT_SAMPLER_CUBE
      case 0x8dd4: // UNSIGNED_INT_SAMPLER_CUBE
      case 0x8dc5: // SAMPLER_CUBE_SHADOW
        return setValueT6Array;

      case 0x8dc1: // SAMPLER_2D_ARRAY
      case 0x8dcf: // INT_SAMPLER_2D_ARRAY
      case 0x8dd7: // UNSIGNED_INT_SAMPLER_2D_ARRAY
      case 0x8dc4: // SAMPLER_2D_ARRAY_SHADOW
        return setValueT2DArrayArray;
    }
  }
}
