import '../core/index.dart';

/// A bone which is part of a [Skeleton]. The skeleton in turn is used by
/// the [SkinnedMesh]. Bones are almost identical to a blank
/// [Object3D].
/// 
/// ```
/// final root = Bone();
/// final child = Bone();
///
/// root.add( child );
/// child.position.y = 5;
/// ```
class Bone extends Object3D {
  Bone() : super() {
    type = 'Bone';
  }

  @override
  Bone clone([bool? recursive]) {
    return Bone()..copy(this, recursive);
  }
}
