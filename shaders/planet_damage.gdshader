shader_type spatial;

// Phase 4 crater-damage shader (planet surface, Compatibility renderer safe).
// Produces a dark crater core, an emberish rim, and a crack "wrinkle" displacement, driven
// by a persistent damage texture updated at runtime by the damage system.

uniform sampler2D damage_tex : filter_linear_mipmap;
uniform float damage_scale : hint_range(0.0, 8.0) = 1.0;
uniform float wrinkle_strength : hint_range(0.0, 2.0) = 0.35;
// Phase 5: data-driven surface look (defaults keep the Phase 4 warm-rock look).
uniform vec3 base_color = vec3(0.82, 0.76, 0.66);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform vec3 ember_color = vec3(0.9, 0.5, 0.2);
uniform float ember_strength : hint_range(0.0, 4.0) = 0.55;

void fragment() {
	vec3 base = base_color;

	// Darken toward the crater core, brighten a rim ring with an ember hint.
	float factor = texture(damage_tex, UV).r;
	float d = clamp(factor * damage_scale, 0.0, 1.0);
	float shade = 1.0 - 0.78 * smoothstep(0.0, 1.0, d);

	vec3 albedo = base * shade;

	// Ember tint for fresh, heavily damaged craters.
	float ember = smoothstep(0.60, 1.0, d);
	albedo += ember_color * ember * 0.35;

	ALBEDO = albedo;
	ROUGHNESS = roughness;
	EMISSION = ember_color * ember * ember_strength;

	// Crack/wrinkle channel: brighten normal variation near craters for a broken look.
	float w = texture(damage_tex, UV * 4.0).g;
	NORMAL = normalize(NORMAL + vec3(w, w, w) * wrinkle_strength);
}

void vertex() {
	// Crack wrinkle displacement: push surface slightly along the normal where damaged.
	float d = texture(damage_tex, UV).r * damage_scale;
	float rim = texture(damage_tex, UV).b;
	float disp = (d * 0.05 + rim * 0.03) * 0.5;
	VERTEX.xyz += NORMAL * disp;
}