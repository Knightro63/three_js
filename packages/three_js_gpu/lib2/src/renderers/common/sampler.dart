
import 'package:three_js_core/three_js_core.dart';
import './binding.dart';

class Sampler extends Binding {
  Texture? texture;
  late int version;

	Sampler(super.name, this.texture ){
		version = texture != null? texture!.version : 0;
	}
}
