shader_type canvas_item;
// Phase 21: rumput bergoyang ditiup angin + menyibak saat dilewati player (atau anjing).
// Dipakai layer GrassDetail dan Decor (rumput hias). Bekerja per tile 16x16:
//  - bagian atas tile bergeser paling jauh, bagian bawah (pangkal) diam;
//  - geseran dibulatkan ke piksel utuh agar tetap pixel art (maks 1-2 px).

uniform float wind_strength = 0.75;   // besar goyangan angin (piksel di ujung bilah)
uniform float wind_speed = 1.5;
uniform vec2 player_pos = vec2(-9999.0);
uniform vec2 pet_pos = vec2(-9999.0);
uniform float push_radius = 14.0;
uniform float push_strength = 2.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float push_from(vec2 who) {
	vec2 d = world_pos - (who + vec2(0.0, -2.0));
	float k = clamp(1.0 - length(d) / push_radius, 0.0, 1.0);
	return sign(d.x) * k * push_strength;
}

void fragment() {
	float tile_px = 16.0;
	// 0 = atas tile, 1 = bawah tile
	float ly = fract(UV.y / TEXTURE_PIXEL_SIZE.y / tile_px);
	float lean = (1.0 - ly) * (1.0 - ly);
	float t = TIME * wind_speed + world_pos.x * 0.045 + world_pos.y * 0.021;
	float wind = (sin(t) + 0.45 * sin(t * 2.3 + world_pos.y * 0.13)) * wind_strength;
	float bend = wind + push_from(player_pos) + push_from(pet_pos);
	float shift = floor(bend * lean + 0.5);
	COLOR = texture(TEXTURE, UV - vec2(shift * TEXTURE_PIXEL_SIZE.x, 0.0));
}
