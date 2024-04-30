import 'bounding_box.dart';
import 'bounding_sphere.dart';

class BoundingVolume {
  BoundingBox? boundingBox;
  BoundingSphere? _boundingSphere;
  BoundingVolume();
  BoundingSphere? get boundingSphere => _boundingSphere;
}