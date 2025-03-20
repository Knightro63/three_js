part of three_webgl;

class WebGLGeometries {
  bool _didDispose = false;
  RenderingContext gl;
  WebGLAttributes attributes;
  WebGLInfo info;
  WebGLBindingStates bindingStates;

  Map<int, bool> geometries = {};
  final wireframeAttributes = WeakMap();

  WebGLGeometries(this.gl, this.attributes, this.info, this.bindingStates);

  void onGeometryDispose(Event event) {
    final geometry = event.target;

    if (geometry.index != null) {
      attributes.remove(geometry.index);
    }

    for (String name in geometry.attributes.keys) {
      attributes.remove(geometry.attributes[name]);
    }

		for (final name in geometry.morphAttributes.keys) {
			final array = geometry.morphAttributes[ name ];

			for (int i = 0, l = array.length; i < l; i ++ ) {
				attributes.remove( array[ i ] );
			}
		}

    geometry.removeEventListener('dispose', onGeometryDispose);

    geometries.remove(geometry.id);

    final attribute = wireframeAttributes.get(geometry);

    if (attribute != null) {
      attributes.remove(attribute);
      wireframeAttributes.delete(geometry);
    }

    bindingStates.releaseStatesOfGeometry(geometry);

    if (geometry is InstancedBufferGeometry) {
      // geometry.remove("maxInstanceCount");
      geometry.maxInstanceCount = null;
    }

    //

    info.memory["geometries"] = info.memory["geometries"]! - 1;
  }

  BufferGeometry get(BufferGeometry geometry) {
    if (geometries[geometry.id] == true) return geometry;

    geometry.addEventListener('dispose', onGeometryDispose);

    geometries[geometry.id] = true;

    info.memory["geometries"] = info.memory["geometries"]! + 1;

    return geometry;
  }

  void update(BufferGeometry geometry) {
    final geometryAttributes = geometry.attributes;

    for (final name in geometryAttributes.keys) {
      attributes.update(geometryAttributes[name], WebGL.ARRAY_BUFFER);
    }
  }

  void updateWireframeAttribute(BufferGeometry geometry) {
    List<int> indices = [];

    final geometryIndex = geometry.index;
    final geometryPosition = geometry.attributes["position"];
    int version = 0;

    if (geometryIndex != null) {
      final array = geometryIndex.array;
      version = geometryIndex.version;
      for (int i = 0, l = array.length; i < l; i += 3) {
        final a = array[i + 0].toInt();
        final b = array[i + 1].toInt();
        final c = array[i + 2].toInt();

        indices.addAll([a, b, b, c, c, a]);
      }
    } 
    else if( geometryPosition != null ){
      final array = geometryPosition.array;
      version = geometryPosition.version;

      for (int i = 0, l = (array.length ~/ 3) - 1; i < l; i += 3) {
        final a = i + 0;
        final b = i + 1;
        final c = i + 2;

        indices.addAll([a, b, b, c, c, a]);
      }
    }
    else{
      return;
    }

    BufferAttribute attribute;
    final max = indices.getMaxValue();
    if (max != null && max > 65535) {
      attribute = Uint32BufferAttribute.fromList(indices, 1);
    } 
    else {
      attribute = Uint16BufferAttribute.fromList(indices, 1);
    }

    attribute.version = version;

    // Updating index buffer in VAO now. See WebGLBindingStates

    final previousAttribute = wireframeAttributes.get(geometry);
    if (previousAttribute != null) attributes.remove(previousAttribute);
    wireframeAttributes.set(geometry, attribute);
  }

  BufferAttribute<NativeArray<num>>? getWireframeAttribute(BufferGeometry geometry) {
    final currentAttribute = wireframeAttributes.get(geometry);

    if (currentAttribute != null) {
      final geometryIndex = geometry.index;
      if (geometryIndex != null) {
        // if the attribute is obsolete, create a new one
        if (currentAttribute.version < geometryIndex.version) {
          updateWireframeAttribute(geometry);
        }
      }
    } 
    else {
      updateWireframeAttribute(geometry);
    }
    return wireframeAttributes.get(geometry);
  }

  void dispose() {
    if(_didDispose) return;
    _didDispose = true;
    for(final key in wireframeAttributes.keys){
      (wireframeAttributes[key] as BufferAttribute).dispose();
    }

    wireframeAttributes.clear();
    geometries.clear();
    attributes.dispose();
    info.dispose();
    bindingStates.dispose();
  }
}
