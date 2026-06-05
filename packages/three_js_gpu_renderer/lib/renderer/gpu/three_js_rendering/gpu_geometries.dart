import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_info.dart';
import 'package:three_js_math/three_js_math.dart';

class GpuGeometries {
  GpuInfo info;
  bool _didDispose = false;

  Map<int, bool> geometries = {};
  final wireframeAttributes = WeakMap();

  GpuGeometries(this.info);

  void onGeometryDispose(Event event) {
    final geometry = event.target;
    geometry.removeEventListener('dispose', onGeometryDispose);

    geometries.remove(geometry.id);

    final attribute = wireframeAttributes.get(geometry);

    if (attribute != null) {
      wireframeAttributes.delete(geometry);
    }
    if (geometry is InstancedBufferGeometry) {
      // geometry.remove("maxInstanceCount");
      geometry.maxInstanceCount = null;
    }

    info.memory["geometries"] = info.memory["geometries"]! - 1;
  }

  BufferGeometry get(BufferGeometry geometry) {
    if (geometries[geometry.id] == true) return geometry;
    geometry.addEventListener('dispose', onGeometryDispose);
    geometries[geometry.id] = true;
    info.memory["geometries"] = info.memory["geometries"]! + 1;
    return geometry;
  }

  void update(BufferGeometry geometry) {}

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
    wireframeAttributes.set(geometry, attribute);
  }

  BufferAttribute? getWireframeAttribute(BufferGeometry geometry) {
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
    info.dispose();
  }
}
