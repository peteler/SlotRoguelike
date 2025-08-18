# Character.gd - abstract class that all characters inherit from, NO EXPORT VAR
class_name Character
extends Area2D # We keep Area2D as the root for the built-in targeting.

var max_health: int

var current_health: int:
	set(value):
		current_health = clampi(value, 0, max_health)
		print("current health, max health for ", self, " is: ", current_health, max_health)
		Global.character_health_updated.emit(self, current_health, max_health)
		if current_health == 0:
			Global.character_died.emit(self)

var block: int = 0:
	set(value):
		block = value
		Global.character_block_updated.emit(self, block)

var attack: int = 0:
	set(value):
		attack = value
		Global.character_attack_updated.emit(self, attack)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var stats_ui: Control = $StatsUI

func _ready():
	# Connect the built-in Area2D signal to our targeting function
	self.input_event.connect(_on_input_event)

# --- Stats & UI initialization from character_data ---

func initialize_character(character_data: CharacterData):
	"""Initialize character stats from CharacterData resource"""
	if not character_data:
		push_error("character has no CharacterData assigned!")
		return
	
	# init stats
	max_health = character_data.max_health
	current_health = max_health
	block = character_data.base_block
	attack = character_data.base_attack
	print("finished setting up stats for: ", character_data.character_name)
	
	# Set sprite if available
	if sprite and character_data.sprite:
		sprite.texture = character_data.sprite
	
	# Apply CollisionShape and Stats UI configuration
	apply_ui_placement(character_data)

func apply_ui_placement(character_data: CharacterData):
	"""
	Applies UI placement configuration from EnemyData.
	Called once from initialize_from_data().
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
	if stats_ui:
		# Get the correct offset based on sprite size.
		var effective_offset = character_data.get_effective_stats_offset(sprite_size)
		
		# Get the anchor position relative to the sprite's local coordinates.
		var anchor_pos = character_data.get_anchor_position(character_data.stats_ui_anchor, sprite_rect)
		
		# The stats UI is a child of the enemy node, so its position is relative to the enemy.
		# This positioning is correct for a UI node placed as a sibling to the Sprite2D.
		stats_ui.position = anchor_pos + effective_offset
		stats_ui.scale = character_data.stats_ui_scale
		
		print("Stats UI positioned at: ", stats_ui.position, " (anchor: ", character_data.stats_ui_anchor, ")")
	
	# Setup individual UI components within StatsUI
	setup_stats_ui_components(character_data)

func setup_stats_ui_components(character_data: CharacterData):
	"""Position individual components within the StatsUI"""
	if not stats_ui:
		return
	
	# Find health bar component
	var health_bar = stats_ui.get_node_or_null("HealthBar")
	if health_bar:
		health_bar.position = character_data.health_bar_local_offset
	
	# Find attack display component
	var attack_display = stats_ui.get_node_or_null("AttackDisplay")
	if attack_display:
		attack_display.position = character_data.attack_display_local_offset
	
	# Find block display component
	var block_display = stats_ui.get_node_or_null("BlockDisplay")
	if block_display:
		block_display.position = character_data.block_display_local_offset
	
	print("Configured UI components with local offsets")

# --- Core Combat Functions ---

func take_basic_attack_damage(amount: int):
	if amount <= 0: return

	var damage_to_block = min(block, amount)
	self.block -= damage_to_block

	var remaining_damage = amount - damage_to_block
	self.current_health -= remaining_damage

func heal(amount: int):
	if amount > 0:
		current_health += amount

func modify_attack(amount: int):
	attack += amount

func modify_block(amount: int):
	block += amount

# --- Targeting Logic (moved from Enemy.gd) ---

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print("self: ", self)
		# Let any listener (like the BattleManager) know this character was clicked.
		Global.character_targeted.emit(self)
