import 'package:three_js_core/objects/group.dart';
import 'package:three_js_math/three_js_math.dart';

class OperationGroup extends Group {
  bool isOperationGroup = true;
  Matrix4 _previousMatrix = Matrix4();

  OperationGroup() : super();

  void markUpdated() {
    //this._previousMatrix.copy( this.matrix );
    _previousMatrix = matrix;
  }

  bool isDirty() {
    //const el1 = matrix.elements;
    // const el2 = _previousMatrix.elements.
    // ignore: prefer_typing_uninitialized_variables
    //var el1, el2;
    final el1 = matrix.storage;
    final el2 = _previousMatrix.storage;
    for (int i = 0; i < 16; i++) {
      if (el1[i] != el2[i]) {
        return true;
      }
    }

    return false;
  }
}
