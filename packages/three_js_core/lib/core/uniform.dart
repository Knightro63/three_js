class Uniform {
  dynamic value;
	Uniform(this.value);

	Uniform clone() {
		return Uniform(value?.clone() == null ?value :value.clone());
	}
}
