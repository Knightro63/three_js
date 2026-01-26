part of three_webgl;

class AngleRenderLists {
  AngleRenderLists();

  WeakMap lists = WeakMap();

  AngleRenderList get(scene, renderCallDepth) {
    final listArray = lists.get( scene );
    dynamic list;

    if (lists.has(scene) == false) {
      list = AngleRenderList();
      lists.add(key: scene, value: [list]);
    } else {
      if (renderCallDepth >= listArray.length) {
        list = AngleRenderList();
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
