import 'event_dispatcher.dart';
import './uniform.dart';

class UniformsGroup with EventDispatcher {
  bool isUniformsGroup = true;
  String name = '';
  List<Uniform> uniforms = [];
  int? usage;
  int? size;
  Map? cache;
  int? bindingPointIndex;

	UniformsGroup():super(){
		UniformsGroup._id++;
    id = _id;
	}

  static int _id = 0;
  late int id;

	UniformsGroup add(Uniform uniform ) {
		uniforms.add(uniform);
		return this;
	}
	UniformsGroup addAll(List<Uniform> uniform ) {
		uniforms.addAll(uniform);
		return this;
	}
	UniformsGroup remove(Uniform uniform) {
		final index = uniforms.indexOf(uniform);
		if (index != - 1) uniforms.removeAt(index);
		return this;
	}

	UniformsGroup setName(String name) {
		this.name = name;
		return this;
	}

	UniformsGroup setUsage(value) {
		usage = value;
		return this;
	}

	void dispose() {
    uniforms.clear();
  }

	UniformsGroup copy(UniformsGroup source) {
		name = source.name;
		usage = source.usage;

    for (final u in source.uniforms) {
      uniforms.add(u.clone());
    }
	
		return this;
	}

	UniformsGroup clone() {
    final UniformsGroup ug = UniformsGroup();
    ug.setName(name);
    ug.setUsage(usage);
    if(uniforms.length > 2){
      ug.uniforms = uniforms..removeAt(1);
    }
		return ug;
	}
}
