
enum NodeShaderStage{vertex,fragment}
enum NodeUpdateType {
	none,
	frame,
	render,
	object
}

enum NodeType{
	bool,
	int,
	float,
	vec2,
	vec3,
	vec4,
	mat2,
	mat3,
	mat4
}

enum NodeAccess{
	readOnly,
	writeOnly,
	readWrite,
}

const defaultShaderStages = [ 'fragment', 'vertex' ];
const defaultBuildStages = [ 'setup', 'analyze', 'generate' ];
const shaderStages = [ ...defaultShaderStages, 'compute' ];
const vectorComponents = [ 'x', 'y', 'z', 'w' ];
