shader_type spatial;
render_mode cull_disabled;
uniform sampler2D _albedo: source_color;
uniform sampler2D _noise;
uniform mat4 slice_plane;
uniform bool inversed;
varying vec3 wvtx;

void vertex() {
	wvtx = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 plane_normal = normalize(-slice_plane[1].xyz);
	if (inversed) plane_normal = normalize(slice_plane[1].xyz);
	float plane_distance = dot(plane_normal, slice_plane[3].xyz);
	float vertex_distance = dot(plane_normal, wvtx);
	float distance = vertex_distance - plane_distance;
	
	vec4 clip_position = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	vec2 uv = clip_position.xy / 10.0;
	uv += TIME * 0.03;
	float noise = texture(_noise, uv).r;
	distance += noise * 0.1;
	
	vec4 border_colour = vec4(1, 1, 1, 1);
	if (distance < 0.0) discard;
	float border_distance = smoothstep(0.0, 0.1, distance);
	vec4 albedo_colour = texture(_albedo, UV);
	ALBEDO = mix(border_colour, albedo_colour, border_distance).rgb;
	EMISSION = mix(border_colour * 7.0, vec4(0.0), border_distance).rgb;
}
