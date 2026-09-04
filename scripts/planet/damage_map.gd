class_name DamageMap
extends RefCounted
## Phase 4: a persistent, texture-based damage store for a planet.
## Damage is painted into an Image (planet texture space) and exposed as an ImageTexture that
## the planet's crater shader samples via a single Image -> ImageTexture flow (Godot 4.7).
## This is a plain data object (RefCounted); the scene reads its computed texture.

const SIZE : int = 128
const FORMAT := Image.FORMAT_RGB8
const SEED : int = 1337


var image : Image
var texture : ImageTexture
var _noise : FastNoiseLite
var total_damage : float = 0.0


func _init() -> void:
	image = Image.create(SIZE, SIZE, false, FORMAT)
	image.fill(Color(0.0, 0.0, 0.0, 1.0))
	_noise = FastNoiseLite.new()
	_noise.seed = SEED
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	texture = ImageTexture.create_from_image(image)


## Rebuilds the ImageTexture from the (possibly just-painted) Image. Call after damage changes.
func texture_update() -> void:
	texture = ImageTexture.create_from_image(image)


## Paints a soft-edged damage dapple at texture coordinates `uv` (0..1) whose falloff is
## reshaped by `_noise`, so repeated impacts look organic (craters + irregular cracks)
## instead of perfect circles.
func add_damage(uv : Vector2, radius : float, strength : float) -> void:
	var w : int = image.get_width()
	var h : int = image.get_height()
	if w <= 0 or h <= 0:
		return
	var cx := int(clampf(uv.x, 0.0, 1.0) * float(w - 1))
	var cy := int(clampf(uv.y, 0.0, 1.0) * float(h - 1))
	var r : int = int(maxf(1.0, radius * float(SIZE)))
	var freq : float = 6.0
	var _px : int = cx
	var _py : int = cy
	for oy in range(-r, r + 1):
		for ox in range(-r, r + 1):
			var px : int = cx + ox
			var py : int = cy + oy
			if px < 0 or py < 0 or px >= w or py >= h:
				continue
			var d : float = (float(ox * ox + oy * oy)) / float(r * r)
			if d > 1.0:
				continue
			var nv := _noise.get_noise_2d(float(px) / freq, float(py) / freq) * 0.5 + 0.5
			var amt : float = (1.0 - d) * strength * (nv * 0.6 + 0.4)
			var cur := image.get_pixel(px, py)
			var v : float = clampf(cur.r + amt, 0.0, 1.0)
			# Store accumulated crater intensity in red, and a faint rim marker in blue.
			image.set_pixel(px, py, Color(v, v, clampf(d, 0.0, 1.0), 1.0))
			_px = px
			_py = py
	total_damage += strength