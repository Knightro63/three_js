@JS('THREE')
import 'event_dispatcher.dart';
import './uniform.dart';
import 'dart:js_interop';

@JS('UniformsGroup')
class UniformsGroup with EventDispatcher {
  bool isUniformsGroup = true;
  external String name;
  external List<Uniform> uniforms;
  external int? usage;
  external int? size;
  external Map? cache;
  external int? bindingPointIndex;

	external UniformsGroup();
  external  int id;

	external UniformsGroup add(Uniform uniform );
	UniformsGroup addAll(List<Uniform> uniform ) {
		uniforms.addAll(uniform);
		return this;
	}
	external UniformsGroup remove(Uniform uniform);
	external UniformsGroup setName(String name);
	external UniformsGroup setUsage(value);
	external void dispose();
	external UniformsGroup copy(UniformsGroup source);
	external UniformsGroup clone();
}
