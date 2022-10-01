shader_type spatial;
//render_mode cull_disabled;
//render_mode unshaded;

float sdCappedCylinder(vec3 p, vec3 a, vec3 b, float r) {
	vec3  ba = b - a;
	vec3  pa = p - a;
	float baba = dot(ba,ba);
	float paba = dot(pa,ba);
	float x = length(pa*baba-ba*paba) - r*baba;
	float y = abs(paba-baba*0.5)-baba*0.5;
	float x2 = x*x;
	float y2 = y*y*baba;
	float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
return sign(d)*sqrt(abs(d))/baba;
}

uniform float line_width = 0.7;
float scene(vec3 p) {
	float m = 1e20;
	m = min( sdCappedCylinder(p.zyx,vec3(0.0),vec3(3.0,0.0,0.0),0.289), m );
	
	return m;
}

vec3 calcNormal_Not_Normalized( vec3 p ) {
	const float h = 0.0001; // replace by an appropriate value
	const vec2 k = vec2(1,-1);
	return ( k.xyy*scene( p + k.xyy*h ) + 
					k.yyx*scene( p + k.yyx*h ) + 
					k.yxy*scene( p + k.yxy*h ) + 
					k.xxx*scene( p + k.xxx*h ) );
}

vec3 bm_process(vec3 vertex) {
	return vertex;
}

varying vec3 cam_pos;
varying vec3 ray_dir;
varying mat3 norm_mat;
void vertex() {
	vec3 uvw = vec3(UV,0.0) * line_width;
	
	// construct local matrix which looks toward next point ("NORMAL" is this direction)
	mat3 yes = mat3(
		vec3(1.0,0.0,0.0),
		// TODO: decide whether to use object-space or view-space up 
		mix(vec3(0.0,1.0,0.0),CAMERA_MATRIX[1].xyz,0.5),
//		CAMERA_MATRIX[1].xyz,
		
		NORMAL);
	
	yes[0] = normalize(cross(yes[2],yes[1]));
	yes[1] = (cross(yes[0],yes[2])); // this seems to not require a normalization
	
	vec3 init_vert = VERTEX;
	VERTEX += yes * uvw;
	
	highp vec3 p1 = TANGENT;
	p1 *= max(COLOR.x * 10.0, max(COLOR.y * 2.5, max(COLOR.z,(COLOR.a * 10.0) - 3.0)));
	
	mat4 to_obj = inverse(WORLD_MATRIX);
	vec3 my_pos = (VERTEX - p1) * yes;
	cam_pos = (((to_obj * CAMERA_MATRIX[3]).xyz) - p1) * yes;
	ray_dir = cam_pos - my_pos;
	
	float inv_lw = 1.0/line_width;
	ray_dir *= inv_lw;
	cam_pos *= inv_lw;
//	cam_pos = mat3(MODELVIEW_MATRIX) * -(init_vert);
//	cam_pos = (MODELVIEW_MATRIX * vec4(uvw,1.0)).xyz;
	norm_mat = mat3(MODELVIEW_MATRIX) * yes;
}

float raymarch(vec3 ro, vec3 rd) {
	float total_dist = 0.0;
	
	for (int i = 0; i < 180; i++) {
		vec3 ray = ro + (rd * total_dist);
		float dist = scene(ray);
		
		if (dist < 0.0001) {
			return total_dist;
		}
		
		total_dist += dist;
	}
	
	return -1.0;
}

void fragment() {
	vec3 ro = cam_pos;
	vec3 rd = -normalize(ray_dir);
	
	
	float yes = raymarch(ro, rd);
	
//	if (yes < 0.0) { discard; }
	
	vec3 ray_hit = ro + (rd * yes);
	NORMAL = normalize(norm_mat * calcNormal_Not_Normalized(ray_hit));
	
	METALLIC = 1.0;
	ROUGHNESS = 0.04;
//	ALBEDO = vec3(UV,0.0);
	vec3 n0 = dFdx(VERTEX);
	vec3 n1 = dFdy(VERTEX);
	
	vec3 norm = normalize((VERTEX - n0) - (VERTEX - n1));
//	ALBEDO = vec3( NORMAL );
//	ALBEDO = vec3( norm );
}