# Character.gd - abstract class that all characters inherit from, NO EXPORT VAR
class_name Character
extends Area2D # We keep Area2D as the root for the built-in targeting.

var max_health: int

var current_health: int:
	set(value):
		current_health = clampi(value, 0, max_health)
		print("current health, max health for ", self, " is: ", current_health, max_health)
		Global.character_health_updated.emit(self, current_health, max_health)
		if not is_alive():
			Global.character_died.emit(self)

var current_block: int = 0:
	set(value):
		current_block = value
		Global.character_block_updated.emit(self, current_block)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var character_battle_ui: Control = $CharacterBattleUI

func _ready():
	# Connect the built-in Area2D signal to our targeting function
	# already connected to player_characteR?
	self.input_event.connect(_on_input_event)

# --- Stats & UI initialization from character_data ---

## INPUT: character_data OR player_data
## [difference is character_data is a static resource and player_data is dynamic save data]
func init_character_stats(character_data):
	if not character_data:
		push_error("character has no CharacterData/PlayerData assigned!")
		return
	
	# init stats
	max_health = character_data.max_health
	current_health = max_health
	current_block = character_data.starting_block

	print("finished setting up stats for: ", character_data.character_name)

func init_character_ui_from_data(character_data: CharacterData):
	# Set sprite if available
	if sprite and character_data.sprite:
		sprite.texture = character_data.sprite
	
	# Apply CollisionShape and Battle UI configuration
	apply_character_battle_ui_placement(character_data)

func apply_character_battle_ui_placement(character_data: CharacterData):
	"""
	Applies UI placement configuration from CharacterData.
	Called once from initialize_character_ui_from_data.
	"""
	if not character_data or not sprite:
		push_error("Missing CharacterData or Sprite2D for UI placement!")
		return
	
	# Get the sprite's bounding box in its local coordinate system.
	var sprite_rect = sprite.get_rect()
	var sprite_size = sprite_rect.size
	
	print("Applying UI placement for ", character_data.character_name, " - Sprite size: ", sprite_size)
	
	# Apply CollisionShape configuration
	if collision_shape:
		if character_data.auto_fit_collision:
			# Auto-fit the collision shape to the sprite's size and scale.
			collision_shape.shape = character_data.create_auto_collision_shape(sprite_size)
			collision_shape.scale = character_data.get_effective_collision_scale(sprite_size)
		elif character_data.custom_collision_shape:
			# Use a manually defined collision shape from the resource.
			collision_shape.shape = character_data.custom_collision_shape
			collision_shape.scale = character_data.collision_scale
		
		# Set the collision shape's position relative to the sprite.
		collision_shape.position = sprite.position + character_data.collision_offset

	# Apply Stats UI placement
	if character_battle_ui:
		# Get the correct offset based on sprite size.
		var effective_offset = character_data.get_effective_stats_offset(sprite_size)
		
		# Get the anchor position relative to the sprite's local coordinates.
		var anchor_pos = character_data.get_anchor_position(character_data.stats_ui_anchor, sprite_rect)
		
		# The stats UI is a child of the enemy node, so its position is relative to the enemy.
		# This positioning is correct for a UI node placed as a sibling to the Sprite2D.
		character_battle_ui.position = anchor_pos + effective_offset
		character_battle_ui.scale = character_data.stats_ui_scale
		
		print("Stats UI positioned at: ", character_battle_ui.position, " (anchor: ", character_data.stats_ui_anchor, ")")
	
	# Setup individual UI components within StatsUI
	setup_battle_ui_components(character_data)

func setup_battle_ui_components(character_data: CharacterData):
	"""Position individual components within the StatsUI"""
	if not character_battle_ui:
		return
	
	# Find health bar component
	var health_bar = character_battle_ui.get_node_or_null("HealthBar")
	if health_bar:
		health_bar.position = character_data.health_bar_local_offset

	# Find block display component
	var block_display = character_battle_ui.get_node_or_null("BlockDisplay")
	if block_display:
		block_display.position = character_data.block_display_local_offset
	
	print("Configured UI components with local offsets")

# --- Core Combat Functions ---

func take_basic_attack_damage(amount: int):
	if amount <= 0: return

	var damage_to_block = min(current_block, amount)
	current_block -= damage_to_block

	var remaining_damage = amount - damage_to_block
	current_health -= remaining_damage

# --- Targeting Logic (moved from Enemy.gd) ---

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print("self: ", self)
		# Let any listener (like the BattleManager) know this character was clicked.
		Global.character_targeted.emit(self)

# --- Utility functions ---
func is_alive() -> bool:
	"""Check if character is still alive"""
	return current_health > 0
