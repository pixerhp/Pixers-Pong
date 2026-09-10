shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable;

// Code references "Simple Grayscale Shader for CanvasItem" by SimranZenov:
// https://godotshaders.com/shader/simple-grayscale-shader-for-canvasitem/
void fragment() {
	vec4 tex = texture(screen_texture, SCREEN_UV);
	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114)); // luminance weights
	COLOR = vec4(vec3(gray), tex.a);
}
