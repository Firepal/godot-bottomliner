shader_type spatial;
//render_mode cull_disabled;
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

varying vec3 cam_pos;
varying vec3 ray_dir;
varying vec3 p1;
varying mat3 norm_mat;
void vertex() {
	mat3 yes;
	VERTEX = bm_process(VERTEX,NORMAL,UV,yes);
	
	p1 = TANGENT;
	p1 *= max(COLOR.x * 10.0, max(COLOR.y * 2.5, max(COLOR.z,(COLOR.a * 10.0) - 3.0)));
	
	vec3 my_pos = (VERTEX - p1) * yes;
	cam_pos = (inverse(MODELVIEW_MATRIX)[3].xyz - p1) * yes;
	ray_dir = cam_pos - my_pos;
	
	float inv_lw = 1.0/line_width;
	ray_dir *= inv_lw;
	cam_pos *= inv_lw;
	
	norm_mat = mat3(MODELVIEW_MATRIX) * yes;
}

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

float scene(vec3 p) {
	float m = 1e20;
	m = min( sdCappedCylinder(p.zyx,vec3(0.0),vec3(3.0,0.0,0.0),0.289), m );
	
	return m;
}

vec3 calcNormal_Not_Normalized( vec3 p ) {
	const float h = 0.0001; // replace by an appropriate value
	const vec2 k = vec2(1,-1);
	return (k.xyy*scene( p + k.xyy*h ) + 
			k.yyx*scene( p + k.yyx*h ) + 
			k.yxy*scene( p + k.yxy*h ) + 
			k.xxx*scene( p + k.xxx*h ) );
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
	ALBEDO = vec3( normalize(p1) );
}