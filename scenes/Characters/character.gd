# Character.gd
class_name Character
extends Area2D # We keep Area2D as the root for the built-in targeting.

## A signal to notify other nodes (like the UI) that this character was targeted.
signal targeted(character)

## Signals for UI to listen to, ensuring the UI is decoupled from the logic.
signal health_updated(current_health, max_health)
signal block_updated(block_amount)
signal attack_updated(attack_amount)
signal died

## Signals for BattleManager to listen to
# Character.gd additions
signal turn_started
signal turn_ended

var is_my_turn: bool = false

@export var max_health: int = 100


var current_health: int:
	set(value):
		current_health = clampi(value, 0, max_health)
		emit_signal("health_updated", current_health, max_health)
		if current_health == 0:
			emit_signal("died")

var block: int = 0:
	set(value):
		block = value
		emit_signal("block_updated", block)
		
var attack: int = 0:
	set(value):
		attack = value
		emit_signal("block_updated", attack)

func _ready():
	# Connect the built-in Area2D signal to our targeting function
	self.input_event.connect(_on_input_event)
	# Initialize stats
	self.current_health = max_health
	self.block = 0
	self.attack = 0

# --- Core Combat Functions ---

func take_damage(amount: int):
	if amount <= 0: return

	var damage_to_block = min(block, amount)
	self.block -= damage_to_block

	var remaining_damage = amount - damage_to_block
	self.current_health -= remaining_damage

func add_block(amount: int):
	self.block += amount

func heal(amount: int):
	self.current_health += amount

func modify_health(amount: int):
	if amount > 0:
		heal(amount)
	else:
		take_damage(-amount)

func modify_attack(amount: int):
	self.attack += amount
	emit_signal("attack_updated", self.attack)


func modify_block(amount: int):
	add_block(amount)
	emit_signal("block_updated", self.block)

# --- Targeting Logic (moved from Enemy.gd) ---

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Let any listener (like the BattleManager) know this character was clicked.
		emit_signal("targeted", self)

# --- Start/End turn Logic ---

func start_turn():
	is_my_turn = true
	emit_signal("turn_started")
	# Player: Enable UI, Enemy: Start AI

func end_turn():
	is_my_turn = false
	# Reset temporary resources
	block = 0
	emit_signal("turn_ended")
	
