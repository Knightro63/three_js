part of three_webgl;

class WebGLRenderLists {
  WebGLRenderLists();

  WeakMap lists = WeakMap();

  WebGLRenderList get(scene, renderCallDepth) {
    final listArray = lists.get( scene );
    dynamic list;

    if (lists.has(scene) == false) {
      list = WebGLRenderList();
      lists.add(key: scene, value: [list]);
    } else {
      if (renderCallDepth >= listArray.length) {
        list = WebGLRenderList();
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
