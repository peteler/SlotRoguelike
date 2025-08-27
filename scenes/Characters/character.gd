# Character.gd - abstract class that all characters inherit from, NO EXPORT VAR
class_name Character
extends Area2D # We keep Area2D as the root for the built-in targeting.

var max_health: int:
	set(value):
		max_health = clampi(value, 1, 999)
		current_health = clampi(current_health, 0, max_health)
		Global.character_health_updated.emit(self, current_health, max_health)
		if not is_alive():
			Global.character_died.emit(self)

var current_health: int:
	set(value):
		current_health = clampi(value, 0, max_health)
		Global.character_health_updated.emit(self, current_health, max_health)
		if not is_alive():
			Global.character_died.emit(self)

var current_block: int = 0:
	set(value):
		current_block = clampi(value, 0 , 999)
		Global.character_block_updated.emit(self, current_block)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Connect the built-in Area2D signal to our targeting function
	# already connected to player_characteR?
	self.input_event.connect(_on_input_event)
	Global.battle_state_changed.connect(_on_battle_state_changed)

# --- Stats & UI initialization from character_template ---

## CALLED ONCE by specific characters to initialize character basic stats
## INPUT: data is character_template OR player_data
## [difference is character_template is a static resource and player_data is dynamic save data]
func init_character_basic_battle_stats(data):
	## init PlayerData & CharacterTemplate mutual stats
	max_health = data.max_health
	current_health = max_health
	current_block = data.start_of_encounter_block

func init_character_sprite_and_collision(character_template: CharacterTemplate):
	if sprite and character_template.sprite:
		sprite.texture = character_template.sprite
	
	# Apply CollisionShape configuration
	if collision_shape:
		setup_collision_shape(character_template)

func setup_collision_shape(character_template: CharacterTemplate):
	"""Setup collision shape based on character data"""
	if character_template.auto_fit_collision:
		# Auto-create a collision shape based on sprite
		create_collision_from_sprite(sprite, character_template)
	elif character_template.custom_collision_shape:
		# Use the custom collision shape from the resource
		collision_shape.shape = character_template.custom_collision_shape
		collision_shape.scale = character_template.collision_scale
		collision_shape.position = sprite.position + character_template.collision_offset
	else:
		# Fallback: create a default collision shape
		create_default_collision(sprite, character_template)

func create_collision_from_sprite(sprite_node: Sprite2D, character_template: CharacterTemplate):
	"""Create a collision shape that matches the sprite"""
	var rectangle_shape = RectangleShape2D.new()
	
	# Get the sprite's texture size
	var texture_size = sprite_node.texture.get_size()
	
	# Account for sprite scale
	var scaled_size = texture_size * sprite_node.scale
	
	# Set the rectangle size to match the sprite
	rectangle_shape.size = scaled_size
	
	# Assign the shape to the collision shape
	collision_shape.shape = rectangle_shape
	
	# Position the collision shape to match the sprite's position with offset
	collision_shape.position = sprite_node.position + character_template.collision_offset
	collision_shape.scale = character_template.collision_scale

func create_default_collision(sprite_node: Sprite2D, character_template: CharacterTemplate):
	"""Create a default collision shape as fallback"""
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = Vector2(32, 32)	 # Default size
	
	collision_shape.shape = rectangle_shape
	collision_shape.position = sprite_node.position + character_template.collision_offset
	collision_shape.scale = character_template.collision_scale

# --- Core Combat Functions ---
func take_damage(amount: int):
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

# --- Functions Used by Other classes ---
## ONLY USED BY EFFECT.APPLY !
func modify_property_by_amount(property_name: String, amount: int):
	if property_name in self:
		set(property_name, get(property_name) + amount)
	else:
		push_error("Property '", property_name, "' does not exist on this object.")

func _on_battle_state_changed(state_name: String):
	match state_name:
		"PLAYER_ROLL":
			on_enter_player_roll()
		_:
			return

## @override
func on_enter_player_roll():
	pass

# --- Utility functions ---
func is_alive() -> bool:
	"""Check if character is still alive"""
	return current_health > 0
