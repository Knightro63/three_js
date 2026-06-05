

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_geometries.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_info.dart';

class GpuObjects {
  bool _didDispose = false;
  final updateMap = WeakMap();
  GpuGeometries geometries;
  GpuInfo info;

  GpuObjects(this.geometries,this.info);

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
    geometries.dispose();
  }
  void onInstancedMeshDispose(event) {
    final instancedMesh = event.target;
    instancedMesh.removeEventListener('dispose', onInstancedMeshDispose);
  }
}
