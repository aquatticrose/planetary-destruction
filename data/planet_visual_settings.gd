class_name PlanetVisualSettings
extends Resource
## Phase 5: visual look of a planet surface, applied to the crater shader
## material by the damage system (PlanetDamage.apply_visuals).

@export var base_color : Color = Color(0.82, 0.76, 0.66, 1.0)
@export var roughness : float = 1.0
## Colour of the damage ember/glow tint.
@export var ember_color : Color = Color(0.9, 0.5, 0.2, 1.0)
@export var ember_strength : float = 0.55
## Crack "wrinkle" strength of the surface.
@export var wrinkle_strength : float = 0.35
## Reserved for future atmosphere rendering (data only for now).
@export var atmosphere_color : Color = Color(0.45, 0.65, 0.95, 1.0)