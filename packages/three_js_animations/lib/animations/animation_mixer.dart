import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import '../interpolants/index.dart';
import 'animation_action.dart';
import 'animation_clip.dart';
import 'keyframe_track.dart';
import 'property_mixer.dart';
import 'property_binding.dart';

class AnimationMixer with EventDispatcher {
  num time = 0.0;
  num timeScale = 1.0;

  late Object3D root;
  int _accuIndex = 0;

  late List<AnimationAction> _actions;
  late int _nActiveActions;
  late Map<String,dynamic> actionsByClip; // TODO: this is broken needs to be addressed
  late List<PropertyMixer> bindings;
  late int _nActiveBindings;
  late Map<String,Map<String,PropertyMixer>> bindingsByRootAndName;
  late List _controlInterpolants;
  late int _nActiveControlInterpolants;

  final _controlInterpolantsResultBuffer = List<num>.filled(1, 0);

  AnimationMixer(this.root) {
    _initMemoryManager();
  }

  void _bindAction(AnimationAction action, AnimationAction? prototypeAction) {
    final root = action.localRoot ?? this.root;
    final List<KeyframeTrack> tracks = action.clip.tracks;
    final nTracks = tracks.length,
        bindings = action.propertyBindings,
        interpolants = action.interpolants,
        rootUuid = root.uuid,
        bindingsByRoot = bindingsByRootAndName;

    Map<String, PropertyMixer>? bindingsByName = bindingsByRoot[rootUuid];

    if (bindingsByName == null) {
      bindingsByName = {};
      bindingsByRoot[rootUuid] = bindingsByName;
    }

    for (int i = 0; i != nTracks; ++i) {
      final track = tracks[i], trackName = track.name;

      PropertyMixer? binding = bindingsByName[trackName];

      if (binding != null) {
        ++binding.referenceCount;
        bindings[i] = binding;
      } else {
        binding = bindings[i];

        if (binding != null) {
          // existing binding, make sure the cache knows

          if (binding.cacheIndex == null) {
            ++binding.referenceCount;
            _addInactiveBinding(binding, rootUuid, trackName);
          }

          continue;
        }

        final path = prototypeAction != null
            ? prototypeAction.propertyBindings[i]?.binding.parsedPath
            : null;

        binding = PropertyMixer(
            PropertyBinding.create(root, trackName, path) as PropertyBinding,
            track.valueTypeName,
            track.getValueSize());

        ++binding.referenceCount;
        _addInactiveBinding(binding, rootUuid, trackName);

        bindings[i] = binding;
      }

      interpolants[i]?.resultBuffer = binding.buffer;
    }
  }

  void activateAction(AnimationAction action) {
    if (!isActiveAction(action)) {
      if (action.cacheIndex == null) {
        // this action has been forgotten by the cache, but the user
        // appears to be still using it -> rebind

        final rootUuid = (action.localRoot ?? root).uuid,
            clipUuid = action.clip.uuid,
            actionsForClip = actionsByClip[clipUuid];

        _bindAction(action, actionsForClip ?? actionsForClip.knownActions[0]);
        _addInactiveAction(action, clipUuid, rootUuid);
      }

      final bindings = action.propertyBindings;

      // increment reference counts / sort out state
      for (int i = 0, n = bindings.length; i != n; ++i) {
        final binding = bindings[i]!;

        if (binding.useCount++ == 0) {
          _lendBinding(binding);
          binding.saveOriginalState();
        }
      }

      _lendAction(action);
    }
  }

  void deactivateAction(AnimationAction action) {
    if (isActiveAction(action)) {
      final bindings = action.propertyBindings;

      // decrement reference counts / sort out state
      for (int i = 0, n = bindings.length; i != n; ++i) {
        final binding = bindings[i];

        if (--binding?.useCount == 0) {
          binding?.restoreOriginalState();
          _takeBackBinding(binding);
        }
      }

      _takeBackAction(action);
    }
  }

  // Memory manager

  void _initMemoryManager() {
    _actions = []; // 'nActiveActions' followed by inactive ones
    _nActiveActions = 0;

    actionsByClip = {};

    bindings = []; // 'nActiveBindings' followed by inactive ones
    _nActiveBindings = 0;

    bindingsByRootAndName = {}; // inside: Map< name, PropertyMixer >

    _controlInterpolants = []; // same game as above
    _nActiveControlInterpolants = 0;
  }

  // Memory management for AnimationAction objects

  bool isActiveAction(AnimationAction action) {
    final index = action.cacheIndex;
    return index != null && index < _nActiveActions;
  }

  void _addInactiveAction(AnimationAction action, String clipUuid, String rootUuid) {
    final actions = _actions;
    final actionsByClip = this.actionsByClip;

    Map? actionsForClip = actionsByClip[clipUuid];

    if (actionsForClip == null) {
      actionsForClip = {
        "knownActions": [action],
        "actionByRoot": {}
      };

      action.byClipCacheIndex = 0;

      actionsByClip[clipUuid] = actionsForClip;
    } 
    else {
      final knownActions = actionsForClip['knownActions'];
      if(knownActions != null){
        action.byClipCacheIndex = knownActions.length;
        knownActions.add(action);
      }
    }

    action.cacheIndex = actions.length;
    actions.add(action);

    actionsForClip["actionByRoot"]?[rootUuid] = action;
  }

  void _removeInactiveAction(AnimationAction action) {
    final actions = _actions;
    final lastInactiveAction = actions[actions.length - 1];
    int cacheIndex = action.cacheIndex!;

    lastInactiveAction.cacheIndex = cacheIndex;
    actions[cacheIndex] = lastInactiveAction;
    actions.removeLast();

    action.cacheIndex = null;

    final clipUuid = action.clip.uuid,
        actionsByClip = this.actionsByClip,
        actionsForClip = actionsByClip[clipUuid],
        knownActionsForClip = actionsForClip.knownActions,
        lastKnownAction = knownActionsForClip[knownActionsForClip.length - 1],
        byClipCacheIndex = action.byClipCacheIndex;

    lastKnownAction.byClipCacheIndex = byClipCacheIndex;
    knownActionsForClip[byClipCacheIndex] = lastKnownAction;
    knownActionsForClip.removeLast();

    action.byClipCacheIndex = null;

    Map actionByRoot = actionsForClip.actionByRoot;
    final rootUuid = (action.localRoot ?? root).uuid;

    // delete actionByRoot[ rootUuid ];
    actionByRoot.remove(rootUuid);

    if (knownActionsForClip.isEmpty()) {
      // delete actionsByClip[ clipUuid ];
      actionsByClip.remove(clipUuid);
    }

    _removeInactiveBindingsForAction(action);
  }

  void _removeInactiveBindingsForAction(AnimationAction action) {
    final bindings = action.propertyBindings;

    for (int i = 0, n = bindings.length; i != n; ++i) {
      final binding = bindings[i];

      if (binding != null && --binding.referenceCount == 0) {
        _removeInactiveBinding(binding);
      }
    }
  }

  void _lendAction(AnimationAction action) {
    // [ active actions |  inactive actions  ]
    // [  active actions >| inactive actions ]
    //                 s        a
    //                  <-swap->
    //                 a        s

    final actions = _actions,
    prevIndex = action.cacheIndex!,
        lastActiveIndex = _nActiveActions++,
        firstInactiveAction = actions[lastActiveIndex];

    action.cacheIndex = lastActiveIndex;
    actions[lastActiveIndex] = action;

    firstInactiveAction.cacheIndex = prevIndex;
    actions[prevIndex] = firstInactiveAction;
  }

  void _takeBackAction(AnimationAction action) {
    // [  active actions  | inactive actions ]
    // [ active actions |< inactive actions  ]
    //        a        s
    //         <-swap->
    //        s        a

    final actions = _actions,
        prevIndex = action.cacheIndex!,
        firstInactiveIndex = --_nActiveActions,
        lastActiveAction = actions[firstInactiveIndex];

    action.cacheIndex = firstInactiveIndex;
    actions[firstInactiveIndex] = action;

    lastActiveAction.cacheIndex = prevIndex;
    actions[prevIndex] = lastActiveAction;
  }

  // Memory management for PropertyMixer objects

  void _addInactiveBinding(PropertyMixer binding, String rootUuid, String trackName) {
    final bindingsByRoot = bindingsByRootAndName, bindings = this.bindings;

    Map<String, PropertyMixer>? bindingByName = bindingsByRoot[rootUuid];

    if (bindingByName == null) {
      bindingByName = {};
      bindingsByRoot[rootUuid] = bindingByName;
    }

    bindingByName[trackName] = binding;

    binding.cacheIndex = bindings.length;
    bindings.add(binding);
  }

  void _removeInactiveBinding(PropertyMixer binding) {
    final bindings = this.bindings,
        propBinding = binding.binding,
        rootUuid = propBinding.rootNode?.uuid,
        trackName = propBinding.path,
        bindingsByRoot = bindingsByRootAndName,
        bindingByName = bindingsByRoot[rootUuid],
        lastInactiveBinding = bindings[bindings.length - 1],
        cacheIndex = binding.cacheIndex!;

    lastInactiveBinding.cacheIndex = cacheIndex;
    bindings[cacheIndex] = lastInactiveBinding;
    bindings.removeLast();

    // delete bindingByName[ trackName ];
    bindingByName?.remove(trackName);

    if (bindingByName != null && bindingByName.keys.isEmpty) {
      // delete bindingsByRoot[ rootUuid ];
      bindingsByRoot.remove(rootUuid);
    }
  }

  void _lendBinding(PropertyMixer binding) {
    final bindings = this.bindings,
        prevIndex = binding.cacheIndex!,
        lastActiveIndex = _nActiveBindings++,
        firstInactiveBinding = bindings[lastActiveIndex];

    binding.cacheIndex = lastActiveIndex;
    bindings[lastActiveIndex] = binding;

    firstInactiveBinding.cacheIndex = prevIndex;
    bindings[prevIndex] = firstInactiveBinding;
  }

  void _takeBackBinding(binding) {
    final bindings = this.bindings,
        prevIndex = binding.cacheIndex,
        firstInactiveIndex = --_nActiveBindings,
        lastActiveBinding = bindings[firstInactiveIndex];

    binding.cacheIndex = firstInactiveIndex;
    bindings[firstInactiveIndex] = binding;

    lastActiveBinding.cacheIndex = prevIndex;
    bindings[prevIndex] = lastActiveBinding;
  }

  // Memory management of Interpolants for weight and time scale

  Interpolant lendControlInterpolant() {
    final interpolants = _controlInterpolants,
        lastActiveIndex = _nActiveControlInterpolants++;

    Interpolant? interpolant = interpolants[lastActiveIndex];

    if (interpolant == null) {
      console.info(" AnimationMixer LinearInterpolant init todo");
      interpolant = LinearInterpolant(List<num>.filled(2, 0),
          List<num>.filled(2, 0), 1, _controlInterpolantsResultBuffer);

      interpolant.cachedIndex = lastActiveIndex;
      interpolants[lastActiveIndex] = interpolant;
    }

    return interpolant;
  }

  void takeBackControlInterpolant(Interpolant interpolant) {
    final interpolants = _controlInterpolants,
        prevIndex = interpolant.cachedIndex,
        firstInactiveIndex = --_nActiveControlInterpolants,
        lastActiveInterpolant = interpolants[firstInactiveIndex];

    interpolant.cachedIndex = firstInactiveIndex;
    interpolants[firstInactiveIndex] = interpolant;

    lastActiveInterpolant._cacheIndex = prevIndex;
    interpolants[prevIndex] = lastActiveInterpolant;
  }

  // return an action for a clip optionally using a custom root target
  // object (this method allocates a lot of dynamic memory in case a
  // previously unknown clip/root combination is specified)
  AnimationAction? clipAction(AnimationClip? clip, [Object3D? optionalRoot, int? blendMode]) {
    final root = optionalRoot ?? this.root;
    final rootUuid = root.uuid;

    AnimationClip? clipObject = clip;

    final clipUuid = clip?.uuid ?? root.uuid;
    final actionsForClip = actionsByClip[clipUuid];
    AnimationAction? prototypeAction;

    if (blendMode == null) {
      if (clipObject != null) {
        blendMode = clipObject.blendMode;
      } 
      else {
        blendMode = NormalAnimationBlendMode;
      }
    }

    if (actionsForClip != null) {
      final existingAction = actionsForClip?.actionByRoot[rootUuid];

      if (existingAction != null && existingAction.blendMode == blendMode) {
        return existingAction;
      }

      // we know the clip, so we don't have to parse all
      // the bindings again but can just copy
      prototypeAction = actionsForClip.knownActions[0];

      // also, take the clip from the prototype action
      clipObject ??= prototypeAction?.clip;
    }

    // clip must be known when specified via string
    if (clipObject == null) return null;

    // allocate all resources required to run it
    final newAction = AnimationAction(
      this, 
      clipObject,
      localRoot: optionalRoot, 
      blendMode: blendMode
    );

    _bindAction(newAction, prototypeAction);

    // and make the action known to the memory manager
    _addInactiveAction(newAction, clipUuid, rootUuid);

    return newAction;
  }

  // get an existing action
  AnimationAction? existingAction(AnimationClip clip, optionalRoot) {
    final root = optionalRoot ?? this.root;
    final rootUuid = root.uuid;

    final clipObject = clip;//clip.runtimeType.toString() == 'String'? AnimationClip.findByName(root, clip):clip,
    final clipUuid = clipObject.uuid;//clipObject ? clipObject.uuid : clip;
    final actionsForClip = actionsByClip[clipUuid];

    if (actionsForClip != null) {
      return actionsForClip.actionByRoot[rootUuid];
    }

    return null;
  }

  // deactivates all previously scheduled actions
  AnimationMixer stopAllAction() {
    final actions = _actions, nActions = _nActiveActions;

    for (int i = nActions - 1; i >= 0; --i) {
      actions[i].stop();
    }

    return this;
  }

  // advance the time and update apply the animation
  AnimationMixer update(num deltaTime) {
    deltaTime *= timeScale;

    final actions = _actions,
        nActions = _nActiveActions,
        time = this.time += deltaTime,
        timeDirection = deltaTime.toDouble().sign,
        accuIndex = _accuIndex ^= 1;

    // run active actions

    for (int i = 0; i != nActions; ++i) {
      final action = actions[i];
      action.update(time, deltaTime, timeDirection, accuIndex);
    }

    // update scene graph

    final bindings = this.bindings;
    final nBindings = _nActiveBindings;

    for (int i = 0; i != nBindings; ++i) {
      final binding = bindings[i];
      binding.apply(accuIndex);
    }

    return this;
  }

  // Allows you to seek to a specific time in an animation.
  AnimationMixer setTime(timeInSeconds) {
    time = 0; // Zero out time attribute for AnimationMixer object;
    for (int i = 0; i < _actions.length; i++) {
      _actions[i].time = 0; // Zero out time attribute for all associated AnimationAction objects.

    }

    return update(timeInSeconds); // Update used to set exact time. Returns "this" AnimationMixer object.
  }

  // return this mixer's root target object
  Object3D getRoot() {
    return root;
  }

  // free all resources specific to a particular clip
  void nuncacheClip(AnimationClip clip) {
    final actions = _actions,
        clipUuid = clip.uuid,
        actionsByClip = this.actionsByClip,
        actionsForClip = actionsByClip[clipUuid];

    if (actionsForClip != null) {
      // note: just calling _removeInactiveAction would mess up the
      // iteration state and also require updating the state we can
      // just throw away

      final actionsToRemove = actionsForClip['knownActions'];

      for (int i = 0, n = actionsToRemove.length; i != n; ++i) {
        final AnimationAction action = actionsToRemove[i];

        deactivateAction(action);

        final cacheIndex = action.cacheIndex!,
            lastInactiveAction = actions[actions.length - 1];

        action.cacheIndex = null;
        action.byClipCacheIndex = null;

        lastInactiveAction.cacheIndex = cacheIndex;
        actions[cacheIndex] = lastInactiveAction;
        actions.removeLast();

        _removeInactiveBindingsForAction(action);
      }

      // delete actionsByClip[ clipUuid ];
      actionsByClip.remove(clipUuid);
    }
  }

  // free all resources specific to a particular root target object
  void uncacheRoot(root) {
    final rootUuid = root.uuid;
    final actionsByClip = this.actionsByClip;

    // for ( var clipUuid in actionsByClip ) {
    actionsByClip.forEach((clipUuid, value) {
      final actionByRoot = actionsByClip[clipUuid].actionByRoot,
          action = actionByRoot[rootUuid];

      if (action != null) {
        deactivateAction(action);
        _removeInactiveAction(action);
      }
    });

    final bindingsByRoot = bindingsByRootAndName,
        bindingByName = bindingsByRoot[rootUuid];

    if (bindingByName != null) {
      for (String trackName in bindingByName.keys) {
        final binding = bindingByName[trackName];
        if(binding != null){
          binding.restoreOriginalState();
          _removeInactiveBinding(binding);
        }
      }
    }
  }

  // remove a targeted clip from the cache
  void uncacheAction(AnimationClip clip, [optionalRoot]) {
    final action = existingAction(clip, optionalRoot);

    if (action != null) {
      deactivateAction(action);
      _removeInactiveAction(action);
    }
  }
}
