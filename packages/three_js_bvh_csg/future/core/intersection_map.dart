class IntersectionMap {
  Map<int, List<int>> intersectionSet = {};

  List<int> ids = [];

  IntersectionMap();

  void add(int id, int intersectionId) {
    if (!intersectionSet.containsKey(id)) {
      intersectionSet[id] = [];
      ids.add(id);
    }
    intersectionSet[id]?.add(intersectionId);
  }
}
