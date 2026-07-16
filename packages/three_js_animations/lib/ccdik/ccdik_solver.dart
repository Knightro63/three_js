import 'package:three_js_animations/ccdik/ccdik_helper.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

// Private global/file-level variables for caching performance
final Quaternion _quaternion = Quaternion();
final Vector3 _targetPos = Vector3();
final Vector3 _targetVec = Vector3();
final Vector3 _effectorPos = Vector3();
final Vector3 _effectorVec = Vector3();
final Vector3 _linkPos = Vector3();
final Quaternion _invLinkQ = Quaternion();
final Vector3 _linkScale = Vector3();
final Vector3 _axis = Vector3();
final Vector3 _vector = Vector3();

/// This class solves the Inverse Kinematics Problem with a [CCD Algorithm](https://web.archive.org/web/20221206080850/https://sites.google.com/site/auraliusproject/ccd-algorithm).
class CCDIKSolver {
  late SkinnedMesh mesh;
  late List<Map<String,dynamic>> iks;

  late List<List<Quaternion>> _initialQuaternions;
  final Quaternion _workingQuaternion = Quaternion();

  CCDIKSolver(this.mesh, [List<Map<String,dynamic>>? iks]) {
    this.iks = iks ?? [];
    _initialQuaternions = [];

    for (final ik in this.iks) {
      final List<Quaternion> chainQuats = [];
      final List links = ik['links'] ?? [];
      for (int i = 0; i < links.length; i++) {
        chainQuats.add(Quaternion());
      }
      _initialQuaternions.add(chainQuats);
    }

    valid();
  }

  /// Updates all IK bones by solving the CCD algorithm.
  ///
  /// [globalBlendFactor] - Blend factor applied if an IK chain doesn't have its own .blendFactor.
  /// Returns a reference to this instance.
  CCDIKSolver update([double globalBlendFactor = 1.0]) {
    final iksList = iks;
    for (int i = 0; i < iksList.length; i++) {
      updateOne(iksList[i], globalBlendFactor);
    }
    return this;
  }

  /// Updates one IK bone solving the CCD algorithm.
  ///
  /// [ik] - The IK to update.
  /// [overrideBlend] - If the IK object does not define `blendFactor`, this value is used.
  /// Returns a reference to this instance.
  CCDIKSolver updateOne(Map<String,dynamic> ik, [double overrideBlend = 1.0]) {
    final double chainBlend = ik['blendFactor'] != null ? ik['blendFactor'].toDouble() : overrideBlend;
    final bones = mesh.skeleton!.bones;
    final int chainIndex = iks.indexOf(ik);
    final List<Quaternion> initialQuaternions = _initialQuaternions[chainIndex];

    final effector = bones[ik['effector']];
    final target = bones[ik['target']];

    // don't use getWorldPosition() here for the performance
    // because it calls updateMatrixWorld( true ) inside.
    _targetPos.setFromMatrixPosition(target.matrixWorld);

    final List links = ik['links'] ?? [];
    final int iteration = ik['iteration'] != null ? ik['iteration'] : 1;

    if (chainBlend < 1.0) {
      for (int j = 0; j < links.length; j++) {
        final int linkIndex = links[j]['index'];
        initialQuaternions[j].setFrom(bones[linkIndex].quaternion);
      }
    }

    for (int i = 0; i < iteration; i++) {
      bool rotated = false;

      for (int j = 0; j < links.length; j++) {
        final link = bones[links[j]['index']];

        // skip this link and following links
        if (links[j]['enabled'] == false) break;

        final limitation = links[j]['limitation'];
        final rotationMin = links[j]['rotationMin'];
        final rotationMax = links[j]['rotationMax'];

        // don't use getWorldPosition/Quaternion() here for the performance
        // because they call updateMatrixWorld( true ) inside.
        link.matrixWorld.decompose(_linkPos, _invLinkQ, _linkScale);
        _invLinkQ.invert();
        _effectorPos.setFromMatrixPosition(effector.matrixWorld);

        // work in link world
        _effectorVec.sub2(_effectorPos, _linkPos);
        _effectorVec.applyQuaternion(_invLinkQ);
        _effectorVec.normalize();

        _targetVec.sub2(_targetPos, _linkPos);
        _targetVec.applyQuaternion(_invLinkQ);
        _targetVec.normalize();

        double angle = _targetVec.dot(_effectorVec);
        if (angle > 1.0) {
          angle = 1.0;
        } else if (angle < -1.0) {
          angle = -1.0;
        }
        angle = math.acos(angle);

        // skip if changing angle is too small to prevent vibration of bone
        if (angle < 1e-5) continue;

        if (ik['minAngle'] != null && angle < ik['minAngle']) {
          angle = ik['minAngle'].toDouble();
        }

        if (ik['maxAngle'] != null && angle > ik['maxAngle']) {
          angle = ik['maxAngle'].toDouble();
        }

        _axis.cross2(_effectorVec, _targetVec);
        _axis.normalize();
        _quaternion.setFromAxisAngle(_axis, angle);
        link.quaternion.multiply(_quaternion);

        // TODO: re-consider the limitation specification
        if (limitation != null) {
          double c = link.quaternion.w.toDouble();
          if (c > 1.0){
            c = 1.0;
          }

          // preserve sign of the rotation along the limitation axis,
          // otherwise negative rotations get mirrored to positive
          final double dot = link.quaternion.x * limitation.x +
              link.quaternion.y * limitation.y +
              link.quaternion.z * limitation.z;
          final double sign = dot < 0 ? -1.0 : 1.0;
          final double c2 = sign * math.sqrt(1.0 - c * c);

          link.quaternion.set(limitation.x * c2, limitation.y * c2, limitation.z * c2, c);
        }

        if (rotationMin != null) {
          link.rotation.setFromVector3(_vector.setFromEuler(link.rotation).max(rotationMin));
        }

        if (rotationMax != null) {
          link.rotation.setFromVector3(_vector.setFromEuler(link.rotation).min(rotationMax));
        }

        link.updateMatrixWorld(true);
        rotated = true;
      }

      if (!rotated) break;
    }

    if (chainBlend < 1.0) {
      for (int j = 0; j < links.length; j++) {
        final int linkIndex = links[j]['index'];
        final link = bones[linkIndex];
        _workingQuaternion.setFrom(initialQuaternions[j]).slerp(link.quaternion, chainBlend);
        link.quaternion.setFrom(_workingQuaternion);
        link.updateMatrixWorld(true);
      }
    }

    return this;
  }

  /// Creates a helper for visualizing the CCDIK.
  ///
  /// [sphereSize] - The sphere size.
  /// Returns the created helper.
  CCDIKHelper createHelper(double sphereSize) {
    return CCDIKHelper(mesh, iks, sphereSize);
  }

  // Private validation method
  void valid() {
    final iksList = iks;
    final bones = mesh.skeleton!.bones;

    for (int i = 0; i < iksList.length; i++) {
      final ik = iksList[i];
      final effector = bones[ik['effector']];
      final List links = ik['links'] ?? [];

      dynamic link0 = effector;
      for (int j = 0; j < links.length; j++) {
        final dynamic link1 = bones[links[j]['index']];
        if (link0.parent != link1) {
          print('THREE.CCDIKSolver: bone ${link0.name} is not the child of bone ${link1.name}');
        }
        link0 = link1;
      }
    }
  }
}
