import 'event_dispatcher.dart';
import './uniform.dart';

class UniformsGroup with EventDispatcher {
  bool isUniformsGroup = true;
  String name = '';
  List<Uniform> uniforms = [];
  dynamic usage;

	UniformsGroup():super(){
		UniformsGroup.id++;
	}

  static int id = 0;

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

	void dispose() {}

	UniformsGroup copy(UniformsGroup source) {
		name = source.name;
		usage = source.usage;

    for (int j = 0; j < source.uniforms.length; j ++ ) {
      uniforms.add(uniforms[j].clone());
    }
	
		return this;
	}

	UniformsGroup clone() {
    final UniformsGroup ug = UniformsGroup();
    ug.setName(name);
    ug.setUsage(usage);
    ug.uniforms = uniforms.removeAt(1) as List<Uniform>;
		return ug;
	}
}
