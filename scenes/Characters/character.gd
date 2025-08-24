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

func _ready():
	# Connect the built-in Area2D signal to our targeting function
	# already connected to player_characteR?
	self.input_event.connect(_on_input_event)

# --- Stats & UI initialization from character_data ---

## CALLED ONCE by specific characters for ui setup
## INPUT: data is character_data OR player_data
## [difference is character_data is a static resource and player_data is dynamic save data]
func init_character_battle_stats(data):
	## init PlayerData & CharacterData mutual stats
	max_health = data.max_health
	current_health = max_health
	current_block = data.start_of_encounter_block

func init_character_battle_ui(character_data: CharacterData, battle_ui: CharacterBattleUI):
	"""
	Applies UI placement configuration from CharacterData.
	Called once by the spceific character.
	"""
	
	if sprite and character_data.sprite:
		sprite.texture = character_data.sprite
	
	if not character_data or not sprite:
		push_error("Missing CharacterData or Sprite2D for UI placement!")
		return
	
	# Get the sprite's bounding box in its local coordinate system.
	var sprite_rect = sprite.get_rect()
	var sprite_size = sprite_rect.size
	
	print("Applying UI placement for ", character_data.character_name, " - Sprite size: ", sprite_size)
	
	# Apply CollisionShape configuration
	if collision_shape:
		# Use a manually defined collision shape from the resource.
		collision_shape.shape = character_data.custom_collision_shape
		collision_shape.scale = character_data.collision_scale
		
		# Set the collision shape's position relative to the sprite.
		collision_shape.position = sprite.position + character_data.collision_offset

	# Apply Stats UI placement
	if battle_ui:
		# Get the anchor position relative to the sprite's local coordinates.
		var anchor_pos = character_data.get_anchor_position(character_data.battle_ui_anchor, sprite_rect)
		
		# The battle UI is a child of the character node, so its position is relative to the character.
		# This positioning is correct for a UI node placed as a sibling to the Sprite2D.
		battle_ui.position = anchor_pos + character_data.battle_ui_offset
		battle_ui.scale = character_data.battle_ui_scale
		
		print("battle UI positioned at: ", battle_ui.position, " (anchor: ", character_data.battle_ui_anchor, ")")
	
	# Setup individual UI components within battleUI
	setup_battle_ui_components(character_data, battle_ui)

func setup_battle_ui_components(character_data: CharacterData, battle_ui: CharacterBattleUI):
	"""Position individual components within the battleUI"""
	if not battle_ui:
		return
	
	# Find health bar component
	var health_bar = battle_ui.get_node_or_null("HealthBar")
	if health_bar:
		health_bar.position = character_data.health_bar_local_offset

	# Find block display component
	var block_display = battle_ui.get_node_or_null("BlockDisplay")
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
