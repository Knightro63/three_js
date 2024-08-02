import 'package:three_js_core/three_js_core.dart';

import '../brush.dart';
import '../constants.dart';

class Operation extends Brush {
  bool isOperation = true;
  int operation = ADDITION;

  // ignore: unused_field
  final _cachedGeometry = BufferGeometry();
  // ignore: unused_field
  dynamic _cachedMaterials;
  int? _previousOperation;

  // Operation(args) : super(args);
  Operation(super.geometry, super.material) : super();

  @override
  void markUpdated() {
    super.markUpdated();
    _previousOperation = operation;
  }

  @override
  bool isDirty() {
    return operation != _previousOperation || super.isDirty();
  }

  void insertBefore(Brush brush) {
    var parent = this.parent;
    var index = parent?.children.indexOf(this);
    parent?.children.insert(index!, brush);
  }

  void insertAfter(Brush brush) {
    var parent = this.parent;
    var index = parent?.children.indexOf(this);
    parent?.children.insert(index! + 1, brush);
  }
}
