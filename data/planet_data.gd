class_name PlanetData
extends Resource
## Phase 5: reusable data definition for a planet. One Resource per archetype;
## presets live in res://data/planets/*.tres and are applied via
## Planet.apply_data(). Physics fields (mass, gravity, rotation_speed) are
## DATA ONLY for now — Phase 6+ (celestial bodies, gravity, orbits) consumes them.

@export var display_name : String = "Planet"
@export var radius : float = 1.0
## Relative mass in Earth masses (consumed by the Phase 7 gravity system).
@export var mass : float = 1.0
## Surface gravity in m/s^2 (data only until Phase 7).
@export var gravity : float = 9.81
## Self-rotation speed in radians/second (data only until later phases).
@export var rotation_speed : float = 0.0
## Mean surface temperature in Kelvin.
@export var temperature : float = 288.0
## Relative atmosphere density (1.0 = Earth-like).
@export var atmosphere_density : float = 1.0
## e.g. "terrestrial", "icy", "volcanic", "gas".
@export var surface_type : String = "terrestrial"
## Short composition string, e.g. "iron/silicate".
@export var composition : String = "iron/silicate"
## Seed for future procedural surface/detail generation.
@export var generation_seed : int = 0
## Visual look applied to the crater shader material.
@export var visual : PlanetVisualSettings