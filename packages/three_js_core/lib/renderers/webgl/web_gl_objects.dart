part of three_webgl;

class WebGLObjects {
  bool _didDispose = false;
  final updateMap = WeakMap();
  WebGLInfo info;
  RenderingContext gl;
  WebGLGeometries geometries;
  WebGLAttributes attributes;

  WebGLObjects(this.gl, this.geometries, this.attributes, this.info);

  BufferGeometry update(Object3D object) {
    num frame = info.render["frame"]!;

    final geometry = object.geometry;

    final buffergeometry = geometries.get(geometry!);

    // Update once per frame

    if (updateMap.get(buffergeometry) != frame) {
      geometries.update(buffergeometry);
      updateMap.add(key: buffergeometry, value: frame);
    }

    // print(" WebGLObjects update object: ${object} ${object.type} ");

    if (object is InstancedMesh) {
      if (object.hasEventListener('dispose', onInstancedMeshDispose) == false) {
        object.addEventListener('dispose', onInstancedMeshDispose);
      }

      if ( updateMap.get( object ) != frame ) {
        // print(" WebGLObjects update 2 object: ${object} ${object.instanceMatrix} ");
        attributes.update(object.instanceMatrix, WebGL.ARRAY_BUFFER);

        if (object.instanceColor != null) {
          attributes.update(object.instanceColor, WebGL.ARRAY_BUFFER);
        }
        updateMap.set( object, frame );
      }
    }

		if ( object is SkinnedMesh ) {
			final skeleton = object.skeleton;

			if ( updateMap.get( skeleton ) != frame ) {
				skeleton?.update();
				updateMap.set( skeleton, frame );
			}
		}
    
    return buffergeometry;
  }

  void dispose() {
    if(_didDispose) return;
    _didDispose = true;
    updateMap.clear();
    attributes.dispose();
    geometries.dispose();
    info.dispose();
  }
  void onInstancedMeshDispose(event) {
    final instancedMesh = event.target;

    instancedMesh.removeEventListener('dispose', onInstancedMeshDispose);

    attributes.remove(instancedMesh.instanceMatrix);

    if (instancedMesh.instanceColor != null) {
      attributes.remove(instancedMesh.instanceColor);
    }
  }
}
