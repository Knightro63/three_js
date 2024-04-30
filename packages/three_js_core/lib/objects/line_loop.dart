import './line.dart';

class LineLoop extends Line {
  LineLoop(super.geometry, super.material){
    type = 'LineLoop';
  }
}
