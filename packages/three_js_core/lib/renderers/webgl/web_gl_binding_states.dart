part of three_webgl;

class WebGLBindingStates {
  bool _didDispose = false;
  RenderingContext gl;
  WebGLAttributes attributes;

  late int maxVertexAttributes;

  dynamic extension;

  late Map<String, dynamic> defaultState;
  late Map<String, dynamic> currentState;
  late Map<int, dynamic> bindingStates;

  bool forceUpdate = false;

  WebGLBindingStates(
    this.gl,
    this.attributes,
  ) {
    maxVertexAttributes = gl.getParameter(WebGL.MAX_VERTEX_ATTRIBS);
    bindingStates = <int, dynamic>{};
    defaultState = createBindingState(null);
    currentState = defaultState;
  }

  void setup(
    Object3D object,
    Material material,
    WebGLProgram program,
    BufferGeometry geometry,
    BufferAttribute? index,
  ) {
    bool updateBuffers = false;

    final state = getBindingState(geometry, program, material);

    if (currentState != state) {
      currentState = state;
      bindVertexArrayObject(currentState["object"]);
    }

    updateBuffers = needsUpdate(object, geometry, program, index);

    if (updateBuffers) saveCache(object, geometry, program, index);


    if (index != null) {
      attributes.update(index, WebGL.ELEMENT_ARRAY_BUFFER);
    }

    if (updateBuffers || forceUpdate) {
      forceUpdate = false;

      setupVertexAttributes(object, material, program, geometry);

      if (index != null) {
        final buf = attributes.get(index)["buffer"];
        gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, buf);
      }
    }
  }

  VertexArrayObject createVertexArrayObject() {
    return gl.createVertexArray();
  }

  void bindVertexArrayObject(VertexArrayObject? vao) {
    if (vao != null) {
      return gl.bindVertexArray(vao);
    } 
    else {
      console.warning(" WebGLBindingStates.dart  bindVertexArrayObject VAO is null");
      return;
    }
  }

  void deleteVertexArrayObject(vao) {
    return gl.deleteVertexArray(vao);
  }

  getBindingState(
    BufferGeometry geometry,
    program,
    Material material,
  ) {
    final wireframe = (material.wireframe == true);

    Map<int, dynamic>? programMap = bindingStates[geometry.id];

    if (programMap == null) {
      programMap = {};
      bindingStates[geometry.id] = programMap;
    }

    Map? stateMap = programMap[program.id];

    if (stateMap == null) {
      stateMap = {};
      programMap[program.id] = stateMap;
    }

     Map? state = stateMap[wireframe];

    if (state == null) {
      state = createBindingState(createVertexArrayObject());
      stateMap[wireframe] = state;
    }

    return state;
  }

  Map<String, dynamic> createBindingState(VertexArrayObject? vao) {
    final newAttributes = List<int>.filled(maxVertexAttributes, 0);
    final enabledAttributes = List<int>.filled(maxVertexAttributes, 0);
    final attributeDivisors = List<int>.filled(maxVertexAttributes, 0);

    // for (int i = 0; i < maxVertexAttributes; i++) {
    //   newAttributes[i] = 0;
    //   enabledAttributes[i] = 0;
    //   attributeDivisors[i] = 0;
    // }

    return {
      // for backward compatibility on non-VAO support browser
      "geometry": null,
      "program": null,
      "wireframe": false,

      "newAttributes": newAttributes,
      "enabledAttributes": enabledAttributes,
      "attributeDivisors": attributeDivisors,
      "object": vao,
      "attributes": {},
      "index": null
    };
  }

  bool needsUpdate(Object3D object, BufferGeometry geometry, WebGLProgram program, BufferAttribute? index) {
    final cachedAttributes = currentState["attributes"];
    final geometryAttributes = geometry.attributes;
    int attributesNum = 0;
    final programAttributes = program.getAttributes();
    for (final name in programAttributes.keys) {
      AttributeLocations programAttribute = programAttributes[name]!;

      if (programAttribute.location.id >= 0) {
        final cachedAttribute = cachedAttributes[name];
        BufferAttribute? geometryAttribute = geometryAttributes[name];

        if (geometryAttribute == null) {
          if (name == 'instanceMatrix' && object.instanceMatrix != null) geometryAttribute = object.instanceMatrix;
          if (name == 'instanceColor' && object.instanceColor != null) geometryAttribute = object.instanceColor;
        }

        if (cachedAttribute == null) return true;

        if (cachedAttribute["attribute"] != geometryAttribute) return true;

        if (geometryAttribute != null && cachedAttribute["data"] != geometryAttribute.data) return true;

        attributesNum++;
      }
    }

    if (currentState["attributesNum"] != attributesNum) return true;
    if (currentState["index"] != index) return true;
    return false;
  }

  void saveCache(object, BufferGeometry geometry, WebGLProgram program, BufferAttribute? index) {
    final cache = {};
    final attributes = geometry.attributes;
    int attributesNum = 0;

    final programAttributes = program.getAttributes();

    for (final name in programAttributes.keys) {
      AttributeLocations programAttribute = programAttributes[name]!;

      if (programAttribute.location.id >= 0) {
        BufferAttribute? attribute = attributes[name];

        if (attribute == null) {
          if (name == 'instanceMatrix' && object.instanceMatrix != null) attribute = object.instanceMatrix;
          if (name == 'instanceColor' && object.instanceColor != null) attribute = object.instanceColor;
        }

        final data = {};
        data["attribute"] = attribute;

        if (attribute != null && attribute.data != null) {
          data["data"] = attribute.data;
        }

        cache[name] = data;

        attributesNum++;
      }
    }

    currentState["attributes"] = cache;
    currentState["attributesNum"] = attributesNum;

    currentState["index"] = index;
  }

  void initAttributes() {
    final newAttributes = currentState["newAttributes"];

    for (int i = 0, il = newAttributes.length; i < il; i++) {
      newAttributes[i] = 0;
    }
  }

  void enableAttribute(int attribute) {
    enableAttributeAndDivisor(attribute, 0);
  }

  void enableAttributeAndDivisor(int attribute, int meshPerAttribute) {
    final newAttributes = currentState["newAttributes"];
    final enabledAttributes = currentState["enabledAttributes"];
    final attributeDivisors = currentState["attributeDivisors"];

    newAttributes[attribute] = 1;

    if (enabledAttributes[attribute] == 0) {
      gl.enableVertexAttribArray(attribute);
      enabledAttributes[attribute] = 1;
    }

    if (attributeDivisors[attribute] != meshPerAttribute) {
      gl.vertexAttribDivisor(attribute, meshPerAttribute);
      attributeDivisors[attribute] = meshPerAttribute;
    }
  }

  void disableUnusedAttributes() {
    final newAttributes = currentState["newAttributes"];
    final enabledAttributes = currentState["enabledAttributes"];

    for (int i = 0, il = enabledAttributes.length; i < il; i++) {
      if (enabledAttributes[i] != newAttributes[i]) {
        gl.disableVertexAttribArray(i);
        enabledAttributes[i] = 0;
      }
    }
  }

  void vertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset, bool integer) {
    if (integer){
      gl.vertexAttribIPointer(index, size, type, stride, offset);
    } else {
      gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
    }
  }

  void setupVertexAttributes(
    Object3D object,
    Material material,
    WebGLProgram program,
    BufferGeometry geometry,
  ) {
    initAttributes();

    final geometryAttributes = geometry.attributes;

    final programAttributes = program.getAttributes();

    final materialDefaultAttributeValues = material.defaultAttributeValues;

    for (final name in programAttributes.keys) {
      final programAttribute = programAttributes[name];

      if (programAttribute!.location.id >= 0) {
        BufferAttribute? geometryAttribute = geometryAttributes[name];

        if (geometryAttribute == null) {
          if (name == 'instanceMatrix' && object is InstancedMesh) {
            geometryAttribute = object.instanceMatrix;
          }
          if (name == 'instanceColor' && object is InstancedMesh && object.instanceColor != null) {
            geometryAttribute = object.instanceColor;
          }
        }

        if (geometryAttribute != null) {
          final normalized = geometryAttribute.normalized;
          final size = geometryAttribute.itemSize;

          final attribute = attributes.get(geometryAttribute);

          // TODO Attribute may not be available on context restore

          if (attribute == null) {
            console.warning("WebGLBindingState setupVertexAttributes name: $name attribute == null ");
            continue;
          }

          final buffer = attribute["buffer"];
          final type = attribute["type"];
          final bytesPerElement = attribute["bytesPerElement"];

          final integer = ( type == WebGL.INT || type == WebGL.UNSIGNED_INT) && geometryAttribute.gpuType == IntType;
          if (geometryAttribute is InterleavedBufferAttribute) {
            final data = geometryAttribute.data;
            final stride = data?.stride;
            final offset = geometryAttribute.offset;

            if (data != null && data is InstancedInterleavedBuffer) {
              for (int i = 0; i < programAttribute.locationSize; i++) {
                enableAttributeAndDivisor(programAttribute.location.id + i, data.meshPerAttribute);
              }

              if (object is! InstancedMesh && geometry.maxInstanceCount == null) {
                geometry.maxInstanceCount = data.meshPerAttribute * data.count;
              }
            } 
            else {
              for (int i = 0; i < programAttribute.locationSize; i++) {
                enableAttribute(programAttribute.location.id + i);
              }
            }

            gl.bindBuffer(WebGL.ARRAY_BUFFER, buffer);

            for (int i = 0; i < programAttribute.locationSize; i++) {
              vertexAttribPointer(
                programAttribute.location.id + i,
                size ~/ programAttribute.locationSize,
                type,
                normalized,
                (stride! * bytesPerElement).toInt(),
                ((offset + (size ~/ programAttribute.locationSize) * i) * bytesPerElement).toInt(),
                integer
              );
            }
          } 
          else {
            if (geometryAttribute is InstancedBufferAttribute) {
              for (int i = 0; i < programAttribute.locationSize; i++) {
                enableAttributeAndDivisor(programAttribute.location.id + i, geometryAttribute.meshPerAttribute);
              }
              geometry.maxInstanceCount ??= geometryAttribute.meshPerAttribute * geometryAttribute.count;
            } 
            else {
              for (int i = 0; i < programAttribute.locationSize; i++) {
                enableAttribute(programAttribute.location.id + i);
              }
            }

            gl.bindBuffer(WebGL.ARRAY_BUFFER, buffer);
            for (int i = 0; i < programAttribute.locationSize; i++) {
              vertexAttribPointer(
                programAttribute.location.id + i, 
                size ~/ programAttribute.locationSize, 
                type,
                normalized, 
                (size * bytesPerElement).toInt(), 
                ((size ~/ programAttribute.locationSize) * i * bytesPerElement).toInt(),
                integer
              );
            }
          }
        } 
        else if (materialDefaultAttributeValues != null) {
          final value = materialDefaultAttributeValues[name];

          if (value != null) {
            switch (value.length) {
              case 2:
                gl.vertexAttrib2fv(programAttribute.location.id, value);
                break;
              case 3:
                gl.vertexAttrib3fv(programAttribute.location.id, value);
                break;
              case 4:
                gl.vertexAttrib4fv(programAttribute.location.id, value);
                break;
              default:
                gl.vertexAttrib1fv(programAttribute.location.id, value);
            }
          }
        }
      }
    }

    disableUnusedAttributes();
  }

  void dispose() {
    if(_didDispose) return;
    _didDispose = true;
    reset();

    for ( final geometryId in bindingStates.keys ) {
      final programMap = bindingStates[ geometryId ];
      for ( final programId in programMap.keys ) {
        final stateMap = programMap[ programId ];
        for ( final wireframe in stateMap.keys) {
          deleteVertexArrayObject( stateMap[ wireframe ]['object'] );
        }
        stateMap.clear();
      }
      programMap.clear();
    }
    
    bindingStates.clear();
    attributes.dispose();
    defaultState.clear();
    currentState.clear();
    attributes.dispose();
  }

  void releaseStatesOfGeometry(BufferGeometry geometry) {
    if (bindingStates[geometry.id] == null) return;

    final programMap = bindingStates[geometry.id];
    for (final programId in programMap.keys) {
      final stateMap = programMap[programId];
      for (final wireframe in stateMap.keys) {
        deleteVertexArrayObject(stateMap[wireframe]["object"]);
      }
      stateMap.clear();
    }
    programMap.clear();

    bindingStates.remove(geometry.id);
  }

  void releaseStatesOfProgram(program) {
    console.info(" WebGLBindingStates releaseStatesOfProgram ");

    for (final geometryId in bindingStates.keys ) {
    	final programMap = bindingStates[ geometryId ];

    	if ( programMap[ program.id ] == null ) continue;
    	final stateMap = programMap[ program.id ];

    	for ( final wireframe in stateMap.keys ) {
    		deleteVertexArrayObject( stateMap[ wireframe ]['object'] );
    	}
      (stateMap as Map).clear();
    	(programMap as Map).remove(program.id);
    }
  }

  void reset() {
    resetDefaultState();
    forceUpdate = true;

    if (currentState == defaultState) return;

    currentState = defaultState;
    bindVertexArrayObject(currentState["object"]);
  }

  // for backward-compatilibity

  void resetDefaultState() {
    defaultState["geometry"] = null;
    defaultState["program"] = null;
    defaultState["wireframe"] = false;
  }
}
