shader_type canvas_item;

// Hologram look for Kira.
// Works per sprite pixel, so it stays crisp on pixel art.

uniform vec4 holo_tint : source_color = vec4(0.45, 0.9, 1.0, 1.0);
// 0 = Kira's real colors, 1 = fully hologram-blue. Keep some of her real look.
uniform float tint_strength : hint_range(0.0, 1.0) = 0.55;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.8;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_speed = 6.0;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.2;

// Driven by kira_hologram.gd during transitions. Leave at defaults in the editor.
uniform float glitch_amount : hint_range(0.0, 1.0) = 0.0;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	float row = floor(UV.y / TEXTURE_PIXEL_SIZE.y);
	float tick = floor(TIME * 12.0);

	// Glitch: shift some pixel rows sideways by 1-2 whole pixels.
	vec2 uv = UV;
	float glitch_row = step(1.0 - glitch_amount * 0.6, hash(row * 1.7 + tick * 3.3));
	float shift = floor((hash(row + tick) - 0.5) * 4.0);
	uv.x += glitch_row * shift * TEXTURE_PIXEL_SIZE.x;

	vec4 tex = texture(TEXTURE, uv) * COLOR;

	// Tint toward hologram blue while keeping some of her real colors.
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 holo = holo_tint.rgb * (lum * 1.3 + 0.15);
	vec3 col = mix(tex.rgb, holo, tint_strength);

	// Moving scanlines: every third pixel row is dimmer.
	float scan = mod(row + floor(TIME * scanline_speed), 3.0) < 1.0 ? 1.0 - scanline_strength : 1.0;
	col *= scan;

	// Occasional brightness flicker.
	float flick = 1.0 - flicker_strength * step(0.92, hash(floor(TIME * 15.0)));

	// Reveal: pixel rows switch on in a scattered order as reveal goes 0 -> 1.
	float row_on = step(hash(row * 7.31), reveal);

	COLOR = vec4(col, tex.a * base_alpha * flick * row_on);
}