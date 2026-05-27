/// Data structure for the renderer. It allows defining values
/// with chained, hierarchical keys. Keys are meant to be
/// objects since the module internally works with nested Maps
/// for safe garbage-collection performance tracking.
class ChainMap {
  /// A map cache holding nested lookups by their primary key list lengths.
  final Map<int, Map<dynamic, dynamic>> maps = {};

  /// Constructs a new Chain Map context.
  ChainMap();

  /// Returns the top-level nested Map container layout matching the explicit keys length.
  Map<dynamic, dynamic> _getMap(List<dynamic> keys) {
    final int length = keys.length;
    
    // Utilize map direct bracket directives to look up multi-key length partitions
    Map<dynamic, dynamic>? targetMap = this.maps[length];
    
    if (targetMap == null) {
      targetMap = <dynamic, dynamic>{};
      this.maps[length] = targetMap;
    }
    
    return targetMap;
  }

  /// Returns the value for the given array of chained keys.
  /// 
  /// [keys] - Ordered sequential array list of lookups.
  /// Returns the cached item or `null` if no matching tracking data was located.
  dynamic get(List<dynamic> keys) {
    if (keys.isEmpty) return null;
    
    Map<dynamic, dynamic>? currentMap = this._getMap(keys);

    for (int i = 0; i < keys.length - 1; i++) {
      final dynamic subKey = keys[i];
      final dynamic nextStep = currentMap?[subKey];
      
      if (nextStep is! Map) {
        return null; // The intermediate chain layout track is missing or invalid
      }
      
      currentMap = nextStep;
    }

    final dynamic finalKey = keys[keys.length - 1];
    return currentMap?[finalKey];
  }

  /// Sets the value for the given chained array of hierarchical keys.
  /// 
  /// [keys] - Ordered sequential array list of key mappings.
  /// [value] - The value payload to store.
  /// Returns a fluent cascading reference to this Chain Map.
  ChainMap set(List<dynamic> keys, dynamic value) {
    if (keys.isEmpty) return this;
    
    Map<dynamic, dynamic> currentMap = this._getMap(keys);

    for (int i = 0; i < keys.length - 1; i++) {
      final dynamic subKey = keys[i];
      
      if (!currentMap.containsKey(subKey) || currentMap[subKey] is! Map) {
        currentMap[subKey] = <dynamic, dynamic>{};
      }
      
      currentMap = currentMap[subKey] as Map<dynamic, dynamic>;
    }

    final dynamic finalKey = keys[keys.length - 1];
    currentMap[finalKey] = value;
    
    return this;
  }

  /// Deletes a value matching the given hierarchical array keys.
  /// 
  /// [keys] - The keys array.
  /// Returns `true` if the item has been removed successfully, or `false` if not found.
  bool delete(List<dynamic> keys) {
    if (keys.isEmpty) return false;
    
    Map<dynamic, dynamic>? currentMap = this._getMap(keys);

    for (int i = 0; i < keys.length - 1; i++) {
      final dynamic subKey = keys[i];
      final dynamic nextStep = currentMap?[subKey];
      
      if (nextStep is! Map) {
        return false;
      }
      
      currentMap = nextStep;
    }

    final dynamic finalKey = keys[keys.length - 1];
    if (currentMap != null && currentMap.containsKey(finalKey)) {
      currentMap.remove(finalKey); // Replaces JavaScript dictionary delete() format command
      return true;
    }
    
    return false;
  }
}
