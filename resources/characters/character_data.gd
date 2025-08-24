# CharacterData.gd - Resource that all spawnable entities should inherit from
@tool
class_name CharacterData
extends Resource

## Basic character information
@export var character_name: String = "character"
@export var sprite: Texture2D
@export var max_health: int = 30
@export var start_of_encounter_block: int = 0

## UI Placement Configuration
@export_group("UI Placement")
# Collision shape configuration
@export var custom_collision_shape: Shape2D  # Override default collision shape
@export var collision_offset: Vector2 = Vector2.ZERO  # Offset from sprite center
@export var collision_scale: Vector2 = Vector2.ONE
@export var auto_fit_collision: bool = true  # Auto-size collision to sprite bounds

# battle UI positioning
@export var battle_ui_offset: Vector2 = Vector2(0, -50)  # Relative to sprite center
@export var battle_ui_anchor: String = "top_center"  # Where to anchor the UI
@export var battle_ui_scale: Vector2 = Vector2.ONE

# Individual component offsets (relative to battle_ui)
@export var health_bar_local_offset: Vector2 = Vector2.ZERO 
@export var block_display_local_offset: Vector2 = Vector2(0, 50)


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
