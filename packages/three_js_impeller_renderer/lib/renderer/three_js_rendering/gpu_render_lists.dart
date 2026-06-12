

import 'package:three_js_core/three_js_core.dart';
import './gpu_render_list.dart';

class GpuRenderLists {
  WeakMap lists = WeakMap();

  GpuRenderList get(scene, renderCallDepth) {
    final listArray = lists.get( scene );
    dynamic list;

    if (lists.has(scene) == false) {
      list = GpuRenderList();
      lists.add(key: scene, value: [list]);
    } else {
      if (renderCallDepth >= listArray.length) {
        list = GpuRenderList();
        listArray.add(list);
      } else {
        list = listArray[renderCallDepth];
      }
    }

    return list;
  }

  void dispose() {
    lists.clear();
  }
}
