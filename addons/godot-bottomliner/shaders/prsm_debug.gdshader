shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;

uniform float line_width = 0.7;
vec3 bm_process(vec3 vertex, vec3 dir_to_next, vec2 uv, out mat3 l2n) {
	vec3 uvw = vec3(uv,0.0) * line_width;
	
	l2n = mat3(
		vec3(1.0,0.0,0.0),
		vec3(0.0,1.0,0.0),
		dir_to_next
	);
	
	l2n[0] = normalize(cross(l2n[2],l2n[1]));
	l2n[1] = normalize(cross(l2n[0],l2n[2])); // this seems to not require a normalization
	
	return vertex + (l2n * uvw);
}

void vertex() {
	mat3 yes;
	VERTEX = bm_process(VERTEX,NORMAL,UV,yes);
}

void fragment() {
	METALLIC = 1.0;
	ROUGHNESS = 0.04;
	ALBEDO = vec3(UV,0.0);
	vec3 n0 = dFdx(VERTEX);
	vec3 n1 = dFdy(VERTEX);
	
	vec3 norm = normalize((VERTEX - n0) - (VERTEX - n1));
//	ALBEDO = vec3( norm );
	if (!FRONT_FACING) { ALBEDO = vec3(1.0,0.0,0.0); }
}