shader_type canvas_item;

uniform vec4 first_color : source_color = vec4(1.0);
uniform vec4 second_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment(){
	vec4 tex = texture(TEXTURE, UV);
	COLOR = mix(first_color, second_color, UV.y);
	COLOR.a = tex.a;
}