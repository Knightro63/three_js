part of three_webgl;

class WebGLBindingStates {
  dynamic gl;
  WebGLExtensions extensions;
  WebGLAttributes attributes;
  WebGLCapabilities capabilities;

  late int maxVertexAttributes;

  dynamic extension;
  late bool vaoAvailable;

  late Map<String, dynamic> defaultState;
  late Map<String, dynamic> currentState;
  late Map<int, dynamic> bindingStates;

  bool forceUpdate = false;

  WebGLBindingStates(
    this.gl,
    this.extensions,
    this.attributes,
    this.capabilities,
  ) {
    maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);

    bindingStates = <int, dynamic>{};

    extension = capabilities.isWebGL2 ? null : extensions.get('OES_vertex_array_object');
    vaoAvailable = capabilities.isWebGL2 || extension != null;

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

    if (vaoAvailable) {
      final state = getBindingState(geometry, program, material);

      if (currentState != state) {
        currentState = state;
        bindVertexArrayObject(currentState["object"]);
      }

      updateBuffers = needsUpdate(object, geometry, program, index);
      // print("WebGLBindingStates.dart setup object: ${object}  updateBuffers: ${updateBuffers}  ");

      if (updateBuffers) saveCache(object, geometry, program, index);
    } 
    else {
      final wireframe = (material.wireframe == true);

      if (
        currentState["geometry"] != geometry.id ||
        currentState["program"] != program.id ||
        currentState["wireframe"] != wireframe
      ) {
        currentState["geometry"] = geometry.id;
        currentState["program"] = program.id;
        currentState["wireframe"] = wireframe;

        updateBuffers = true;
      }
    }

    if (index != null) {
      attributes.update(index, gl.ELEMENT_ARRAY_BUFFER);
    }

    if (updateBuffers || forceUpdate) {
      forceUpdate = false;

      setupVertexAttributes(object, material, program, geometry);

      if (index != null) {
        final buf = attributes.get(index)["buffer"];
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, buf);
      }
    }
  }

  createVertexArrayObject() {
    if (capabilities.isWebGL2) return gl.createVertexArray();

    return extension.createVertexArrayOES();
  }

  bindVertexArrayObject(vao) {
    if (capabilities.isWebGL2) {
      if (vao != null) {
        return gl.bindVertexArray(vao);
      } else {
        console.warning(" WebGLBindingStates.dart  bindVertexArrayObject VAO is null");
        return;
      }
    }

    return extension.bindVertexArrayOES(vao);
  }

  deleteVertexArrayObject(vao) {
    if (capabilities.isWebGL2) return gl.deleteVertexArray(vao);

    return extension.deleteVertexArrayOES(vao);
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

  Map<String, dynamic> createBindingState(vao) {
    final newAttributes = List<int>.filled(maxVertexAttributes, 0);
    final enabledAttributes = List<int>.filled(maxVertexAttributes, 0);
    final attributeDivisors = List<int>.filled(maxVertexAttributes, 0);

    for (int i = 0; i < maxVertexAttributes; i++) {
      newAttributes[i] = 0;
      enabledAttributes[i] = 0;
      attributeDivisors[i] = 0;
    }

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
      Map programAttribute = programAttributes[name];

      if (programAttribute["location"] >= 0) {
        final cachedAttribute = cachedAttributes[name];
        BufferAttribute<NativeArray<num>>? geometryAttribute = geometryAttributes[name];

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
      Map programAttribute = programAttributes[name];

      if (programAttribute["location"] >= 0) {
        BufferAttribute<NativeArray<num>>? attribute = attributes[name];

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

  void enableAttribute(attribute) {
    enableAttributeAndDivisor(attribute, 0);
  }

  void enableAttributeAndDivisor(attribute, meshPerAttribute) {
    final newAttributes = currentState["newAttributes"];
    final enabledAttributes = currentState["enabledAttributes"];
    final attributeDivisors = currentState["attributeDivisors"];

    newAttributes[attribute] = 1;

    if (enabledAttributes[attribute] == 0) {
      gl.enableVertexAttribArray(attribute);
      enabledAttributes[attribute] = 1;
    }

    if (attributeDivisors[attribute] != meshPerAttribute) {
      // final extension = capabilities.isWebGL2 ? gl : extensions.get( 'ANGLE_instanced_arrays' );
      // extension[ capabilities.isWebGL2 ? 'vertexAttribDivisor' : 'vertexAttribDivisorANGLE' ]( attribute, meshPerAttribute );

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

  void vertexAttribPointer(index, size, type, normalized, stride, offset) {
    if (capabilities.isWebGL2 == true && (type == gl.INT || type == gl.UNSIGNED_INT)) {
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
    if (capabilities.isWebGL2 == false && (object is InstancedMesh || geometry is InstancedBufferGeometry)) {
      if (extensions.get('ANGLE_instanced_arrays') == null) return;
    }

    initAttributes();

    final geometryAttributes = geometry.attributes;

    final programAttributes = program.getAttributes();

    final materialDefaultAttributeValues = material.defaultAttributeValues;

    for (final name in programAttributes.keys) {
      final programAttribute = programAttributes[name];

      if (programAttribute["location"] >= 0) {
        // final geometryAttribute = geometryAttributes[ name ];
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

          if (geometryAttribute is InterleavedBufferAttribute) {
            final data = geometryAttribute.data;
            final stride = data?.stride;
            final offset = geometryAttribute.offset;

            if (data != null && data is InstancedInterleavedBuffer) {
              // enableAttributeAndDivisor( programAttribute, data.meshPerAttribute );
              for (int i = 0; i < programAttribute["locationSize"]; i++) {
                enableAttributeAndDivisor(programAttribute["location"] + i, data.meshPerAttribute);
              }

              if (object is! InstancedMesh && geometry.maxInstanceCount == null) {
                geometry.maxInstanceCount = data.meshPerAttribute * data.count;
              }
            } else {
              // enableAttribute( programAttribute );
              for (int i = 0; i < programAttribute["locationSize"]; i++) {
                enableAttribute(programAttribute["location"] + i);
              }
            }

            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

            // vertexAttribPointer( programAttribute, size, type, normalized, stride * bytesPerElement, offset * bytesPerElement );
            for (int i = 0; i < programAttribute["locationSize"]; i++) {
              vertexAttribPointer(
                  programAttribute["location"] + i,
                  size ~/ programAttribute["locationSize"],
                  type,
                  normalized,
                  stride! * bytesPerElement,
                  (offset + (size ~/ programAttribute["locationSize"]) * i) * bytesPerElement);
            }
          } else {
            if (geometryAttribute is InstancedBufferAttribute) {
              // enableAttributeAndDivisor( programAttribute, geometryAttribute.meshPerAttribute );
              for (int i = 0; i < programAttribute["locationSize"]; i++) {
                enableAttributeAndDivisor(programAttribute["location"] + i, geometryAttribute.meshPerAttribute);
              }

              geometry.maxInstanceCount ??= geometryAttribute.meshPerAttribute * geometryAttribute.count;
            } else {
              // enableAttribute( programAttribute );
              for (int i = 0; i < programAttribute["locationSize"]; i++) {
                enableAttribute(programAttribute["location"] + i);
              }
            }

            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
            // vertexAttribPointer( programAttribute, size, type, normalized, 0, 0 );
            for (int i = 0; i < programAttribute["locationSize"]; i++) {
              vertexAttribPointer(programAttribute["location"] + i, size ~/ programAttribute["locationSize"], type,
                  normalized, size * bytesPerElement, (size ~/ programAttribute["locationSize"]) * i * bytesPerElement);
            }
          }
        } else if (materialDefaultAttributeValues != null) {
          final value = materialDefaultAttributeValues[name];

          if (value != null) {
            switch (value.length) {
              case 2:
                gl.vertexAttrib2fv(programAttribute["location"], value);
                break;

              case 3:
                gl.vertexAttrib3fv(programAttribute["location"], value);
                break;

              case 4:
                gl.vertexAttrib4fv(programAttribute["location"], value);
                break;

              default:
                gl.vertexAttrib1fv(programAttribute["location"], value);
            }
          }
        }
      }
    }

    disableUnusedAttributes();
  }

  void dispose() {
    reset();

    // for ( final geometryId in bindingStates ) {

    // 	final programMap = bindingStates[ geometryId ];

    // 	for ( final programId in programMap ) {

    // 		final stateMap = programMap[ programId ];

    // 		for ( final wireframe in stateMap ) {

    // 			deleteVertexArrayObject( stateMap[ wireframe ].object );

    // 			delete stateMap[ wireframe ];

    // 		}

    // 		delete programMap[ programId ];

    // 	}

    // 	delete bindingStates[ geometryId ];

    // }
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

    // for ( final geometryId in bindingStates ) {

    // 	final programMap = bindingStates[ geometryId ];

    // 	if ( programMap[ program.id ] == null ) continue;

    // 	final stateMap = programMap[ program.id ];

    // 	for ( final wireframe in stateMap ) {

    // 		deleteVertexArrayObject( stateMap[ wireframe ].object );

    // 		delete stateMap[ wireframe ];

    // 	}

    // 	delete programMap[ program.id ];

    // }
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
