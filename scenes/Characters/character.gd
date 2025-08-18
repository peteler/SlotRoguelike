# Character.gd
class_name Character
extends Area2D # We keep Area2D as the root for the built-in targeting.

@export var max_health: int = 100

var current_health: int:
	set(value):
		current_health = clampi(value, 0, max_health)
		Global.character_health_changed.emit(self, current_health, max_health)
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

func _ready():
	# Connect the built-in Area2D signal to our targeting function
	self.input_event.connect(_on_input_event)
	# Initialize stats
	self.current_health = max_health
	self.block = 0
	self.attack = 0

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
