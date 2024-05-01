import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'property_binding.dart';

///
/// A group of objects that receives a shared animation state.
///
/// Usage:
///
///  - Add objects you would otherwise pass as 'root' to the
///    constructor or the .clipAction method of AnimationMixer.
///
///  - Instead pass this object as 'root'.
///
///  - You can also add and remove objects later when the mixer
///    is running.
///
/// Note:
///
///    Objects of this class appear as one object to the mixer,
///    so cache control of the individual objects must be done
///    on the group.
///
/// Limitation:
///
///  - The animated properties must be compatible among the
///    all objects in the group.
///
///  - A single property can either be controlled through a
///    target group or directly, but not both.

class AnimationObjectGroup {
  bool isAnimationObjectGroup = true;

  String uuid = MathUtils.generateUUID();

  // threshold
  int nCachedObjects_ = 0;
  // note: read by PropertyBinding.Composite

  late Map<String,int> _indicesByUUID;
  late List<String> _paths;
  late List<Map<String,String?>> _parsedPaths;
  late List<List<PropertyBinding?>> _bindings;
  late Map<String,int> _bindingsIndicesByPath;
  List<Mesh> _objects = [];

  /// [items] - an arbitrary number of meshes that share the same
	/// animation state.
  AnimationObjectGroup(List<Mesh>? items) {
    // cached objects followed by the active ones
    _objects = items != null ? items.sublist(0) : [];

    _indicesByUUID = {}; // for bookkeeping

    if (items != null && items.isNotEmpty) {
      for (int i = 0, n = items.length; i != n; ++i) {
        _indicesByUUID[items[i].uuid] = i;
      }
    }

    _paths = []; // inside: string
    _parsedPaths = []; // inside: { we don't care, here }
    _bindings = []; // inside: Array< PropertyBinding >
    _bindingsIndicesByPath = {}; // inside: indices in these arrays
  }

  /// Adds an arbitrary number of objects to this `AnimationObjectGroup`.
  void add(List<Mesh> items) {
    final objects = _objects,
        indicesByUUID = _indicesByUUID,
        paths = _paths,
        parsedPaths = _parsedPaths,
        bindings = _bindings,
        nBindings = bindings.length;

    late Object3D knownObject;
    int nObjects = objects.length;
    int nCachedObjects = nCachedObjects_;

    for (int i = 0, n = items.length; i != n; ++i) {
      final object = items[i], uuid = object.uuid;
      int? index = indicesByUUID[uuid];

      if (index == null) {
        // unknown object -> add it to the ACTIVE region

        index = nObjects++;
        indicesByUUID[uuid] = index;
        objects.add(object);

        // accounting is done, now do the same for all bindings

        for (int j = 0, m = nBindings; j != m; ++j) {
          bindings[j].add(PropertyBinding(object, paths[j], parsedPaths[j]));
        }
      } 
      else if (index < nCachedObjects) {
        knownObject = objects[index];

        // move existing object to the ACTIVE region

        final firstActiveIndex = --nCachedObjects,
            lastCachedObject = objects[firstActiveIndex];

        indicesByUUID[lastCachedObject.uuid] = index;
        objects[index] = lastCachedObject;

        indicesByUUID[uuid] = firstActiveIndex;
        objects[firstActiveIndex] = object;

        // accounting is done, now do the same for all bindings

        for (int j = 0, m = nBindings; j != m; ++j) {
          final bindingsForPath = bindings[j],
              lastCached = bindingsForPath[firstActiveIndex];

          PropertyBinding? binding = bindingsForPath[index];

          bindingsForPath[index] = lastCached;

          binding ??= PropertyBinding(object, paths[j], parsedPaths[j]);

          bindingsForPath[firstActiveIndex] = binding;
        }
      } 
      else if (objects[index] != knownObject) {
        console.warning('AnimationObjectGroup: Different objects with the same UUID ' 'detected. Clean the caches or recreate your infrastructure when reloading scenes.');
      } // else the object is already where we want it to be

    } // for arguments

    nCachedObjects_ = nCachedObjects;
  }

  /// Removes an arbitrary number of objects from this `AnimationObjectGroup`.
  void remove(List<Mesh> items) {
    final objects = _objects,
        indicesByUUID = _indicesByUUID,
        bindings = _bindings,
        nBindings = bindings.length;

    int nCachedObjects = nCachedObjects_;

    for (int i = 0, n = items.length; i != n; ++i) {
      final object = items[i], uuid = object.uuid, index = indicesByUUID[uuid];

      if (index != null && index >= nCachedObjects) {
        // move existing object into the CACHED region

        final lastCachedIndex = nCachedObjects++,
            firstActiveObject = objects[lastCachedIndex];

        indicesByUUID[firstActiveObject.uuid] = index;
        objects[index] = firstActiveObject;

        indicesByUUID[uuid] = lastCachedIndex;
        objects[lastCachedIndex] = object;

        // accounting is done, now do the same for all bindings

        for (int j = 0, m = nBindings; j != m; ++j) {
          final bindingsForPath = bindings[j],
              firstActive = bindingsForPath[lastCachedIndex],
              binding = bindingsForPath[index];

          bindingsForPath[index] = firstActive;
          bindingsForPath[lastCachedIndex] = binding;
        }
      }
    } // for arguments

    nCachedObjects_ = nCachedObjects;
  }

  /// Deallocates all memory resources for the passed objects of this `AnimationObjectGroup`.
  void uncache(List<Mesh> items) {
    final objects = _objects,
        indicesByUUID = _indicesByUUID,
        bindings = _bindings,
        nBindings = bindings.length;

    int nCachedObjects = nCachedObjects_, nObjects = objects.length;

    for (int i = 0, n = items.length; i != n; ++i) {
      final object = items[i], uuid = object.uuid, index = indicesByUUID[uuid];

      if (index != null) {
        // delete indicesByUUID[ uuid ];
        indicesByUUID.remove(uuid);

        if (index < nCachedObjects) {
          // object is cached, shrink the CACHED region

          final firstActiveIndex = --nCachedObjects,
              lastCachedObject = objects[firstActiveIndex],
              lastIndex = --nObjects,
              lastObject = objects[lastIndex];

          // last cached object takes this object's place
          indicesByUUID[lastCachedObject.uuid] = index;
          objects[index] = lastCachedObject;

          // last object goes to the activated slot and pop
          indicesByUUID[lastObject.uuid] = firstActiveIndex;
          objects[firstActiveIndex] = lastObject;
          objects.removeLast();

          // accounting is done, now do the same for all bindings

          for (int j = 0, m = nBindings; j != m; ++j) {
            final bindingsForPath = bindings[j],
                lastCached = bindingsForPath[firstActiveIndex],
                last = bindingsForPath[lastIndex];

            bindingsForPath[index] = lastCached;
            bindingsForPath[firstActiveIndex] = last;
            bindingsForPath.removeLast();
          }
        } 
        else {
          // object is active, just swap with the last and pop

          final lastIndex = --nObjects, lastObject = objects[lastIndex];

          if (lastIndex > 0) {
            indicesByUUID[lastObject.uuid] = index;
          }

          objects[index] = lastObject;
          objects.removeLast();

          // accounting is done, now do the same for all bindings

          for (int j = 0, m = nBindings; j != m; ++j) {
            final bindingsForPath = bindings[j];

            bindingsForPath[index] = bindingsForPath[lastIndex];
            bindingsForPath.removeLast();
          }
        } // cached or active

      } // if object is known

    } // for arguments

    nCachedObjects_ = nCachedObjects;
  }

  // Internal interface used by befriended PropertyBinding.Composite:
  List<PropertyBinding?> subscribe_(String path, parsedPath) {
    // returns an array of bindings for the given path that is changed
    // according to the contained objects in the group

    final indicesByPath = _bindingsIndicesByPath;
    int? index = indicesByPath[path];
    final bindings = _bindings;

    if (index != null) return bindings[index];

    final paths = _paths,
        parsedPaths = _parsedPaths,
        objects = _objects,
        nObjects = objects.length,
        nCachedObjects = nCachedObjects_;

    final bindingsForPath = List<PropertyBinding?>.filled(nObjects, null);

    index = bindings.length;

    indicesByPath[path] = index;

    paths.add(path);
    parsedPaths.add(parsedPath);
    bindings.add(bindingsForPath);

    for (int i = nCachedObjects, n = objects.length; i != n; ++i) {
      final object = objects[i];
      bindingsForPath[i] = PropertyBinding(object, path, parsedPath);
    }

    return bindingsForPath;
  }

  void unsubscribe_(path) {
    // tells the group to forget about a property path and no longer
    // update the array previously obtained with 'subscribe_'

    final indicesByPath = _bindingsIndicesByPath,
        index = indicesByPath[path];

    if (index != null) {
      final paths = _paths,
          parsedPaths = _parsedPaths,
          bindings = _bindings,
          lastBindingsIndex = bindings.length - 1,
          lastBindings = bindings[lastBindingsIndex],
          lastBindingsPath = path[lastBindingsIndex];

      indicesByPath[lastBindingsPath] = index;

      bindings[index] = lastBindings;
      bindings.removeLast();

      parsedPaths[index] = parsedPaths[lastBindingsIndex];
      parsedPaths.removeLast();

      paths[index] = paths[lastBindingsIndex];
      paths.removeLast();
    }
  }
}
