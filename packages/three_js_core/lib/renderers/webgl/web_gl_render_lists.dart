part of three_webgl;

class WebGLRenderLists {
  WebGLRenderLists();

  WeakMap lists = WeakMap();

  WebGLRenderList get(scene, renderCallDepth) {
    dynamic list;

    if (lists.has(scene) == false) {
      list = WebGLRenderList();
      lists.add(key: scene, value: [list]);
    } else {
      if (renderCallDepth >= lists.get(scene).length) {
        list = WebGLRenderList();
        lists.get(scene).add(list);
      } else {
        list = lists.get(scene)[renderCallDepth];
      }
    }

    return list;
  }

  void dispose() {
    lists = WeakMap();
  }
}
