# CharacterData.gd - Resource for character configuration
@tool
class_name CharacterData
extends Resource

## Basic enemy information
@export var character_name: String = "character"
@export var sprite: Texture2D
@export var max_health: int = 30
@export var base_attack: int = 5
@export var base_block: int = 0

## UI Placement Configuration
@export_group("UI Placement")
# Collision shape configuration
@export var custom_collision_shape: Shape2D  # Override default collision shape
@export var collision_offset: Vector2 = Vector2.ZERO  # Offset from sprite center
@export var collision_scale: Vector2 = Vector2.ONE
@export var auto_fit_collision: bool = true  # Auto-size collision to sprite bounds

# Stats UI positioning
@export var stats_ui_offset: Vector2 = Vector2(0, -50)  # Relative to sprite center
@export var stats_ui_anchor: String = "top_center"  # Where to anchor the UI
@export var stats_ui_scale: Vector2 = Vector2.ONE

# Individual component offsets (relative to stats_ui)
@export var health_bar_local_offset: Vector2 = Vector2.ZERO
@export var attack_display_local_offset: Vector2 = Vector2(0, 25)
@export var block_display_local_offset: Vector2 = Vector2(0, 50)

# Sprite-size-based auto adjustments
@export_group("Auto Placement")
@export var enable_auto_placement: bool = true
@export var ui_padding: float = 15.0  # Minimum distance from sprite edge
@export var large_sprite_threshold: float = 100.0  # Pixels - what counts as "large"
@export var small_sprite_threshold: float = 50.0   # Pixels - what counts as "small"

# Size-specific overrides
@export_subgroup("Large Sprite Overrides")
@export var large_sprite_stats_offset: Vector2 = Vector2(0, -70)
@export var large_sprite_collision_scale: Vector2 = Vector2(1.2, 1.2)

@export_subgroup("Small Sprite Overrides") 
@export var small_sprite_stats_offset: Vector2 = Vector2(0, -30)
@export var small_sprite_collision_scale: Vector2 = Vector2(0.8, 0.8)


## helper functions for placement
func get_anchor_position(anchor: String, sprite_rect: Rect2) -> Vector2:
	"""Convert anchor string to actual position within sprite bounds"""
	match anchor:
		"top_left":
			return Vector2(sprite_rect.position.x, sprite_rect.position.y)
		"top_center":
			return Vector2(sprite_rect.get_center().x, sprite_rect.position.y)
		"top_right":
			return Vector2(sprite_rect.position.x + sprite_rect.size.x, sprite_rect.position.y)
		"center_left":
			return Vector2(sprite_rect.position.x, sprite_rect.get_center().y)
		"center":
			return sprite_rect.get_center()
		"center_right":
			return Vector2(sprite_rect.position.x + sprite_rect.size.x, sprite_rect.get_center().y)
		"bottom_left":
			return Vector2(sprite_rect.position.x, sprite_rect.position.y + sprite_rect.size.y)
		"bottom_center":
			return Vector2(sprite_rect.get_center().x, sprite_rect.position.y + sprite_rect.size.y)
		"bottom_right":
			return sprite_rect.position + sprite_rect.size
		_:
			return sprite_rect.get_center()  # Default to center

func get_effective_stats_offset(sprite_size: Vector2) -> Vector2:
	"""Get the stats UI offset, considering sprite size overrides"""
	if not enable_auto_placement:
		return stats_ui_offset
	
	var max_dimension = max(sprite_size.x, sprite_size.y)
	
	if max_dimension >= large_sprite_threshold:
		return large_sprite_stats_offset
	elif max_dimension <= small_sprite_threshold:
		return small_sprite_stats_offset
	else:
		return stats_ui_offset

func get_effective_collision_scale(sprite_size: Vector2) -> Vector2:
	"""Get the collision scale, considering sprite size overrides"""
	if not enable_auto_placement:
		return collision_scale
	
	var max_dimension = max(sprite_size.x, sprite_size.y)
	
	if max_dimension >= large_sprite_threshold:
		return large_sprite_collision_scale
	elif max_dimension <= small_sprite_threshold:
		return small_sprite_collision_scale
	else:
		return collision_scale

func create_auto_collision_shape(sprite_size: Vector2) -> Shape2D:	
	"""Create an appropriate collision shape for the sprite size"""
	var shape = RectangleShape2D.new()
	shape.size = sprite_size * 0.8  # Slightly smaller than sprite
	return shape
