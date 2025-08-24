# PlayerCharacter.gd - Player character class
class_name PlayerCharacter
extends Character

## parent vars
#var max_health: int
#var current_health: int:
#var current_block: int = 0:
#@onready var sprite: Sprite2D = $Sprite2D
#@onready var collision_shape: CollisionShape2D = $CollisionShape2D
#@onready var stats_ui: Control = $StatsUI

## Player-specific stats
var current_mana: int = 0:
	set(value):
		current_mana = max(0, value)
		Global.player_mana_updated.emit(current_mana)

var turn_attack: int = 0:
	set(value):
		turn_attack = value
		Global.character_attack_updated.emit(self, turn_attack)

## Player character data resource
@export var player_data: PlayerData

@onready var battle_ui: PlayerCharacterBattleUI = $PlayerBattleUI

## battle manager helper fields [should eventually be changed into a function if mechanic will be updated]
var can_attack: bool = false

## functions
func _ready():
	super._ready()  # Call Character._ready()
	
	# Add player to group for easy finding
	add_to_group("player_character")
	
	# Initialize from player data if available
	if player_data:
		initialize_from_player_data(player_data)
	else:
		push_error("Player has no PlayerData assigned!")

func initialize_from_player_data(data: PlayerData):
	"""Initialize player character from PlayerData resource"""
	if not data:
		push_error("PlayerCharacter requires valid PlayerData to initialize!")
		return
	
	self.player_data = data
	
	# init all player character battle ui
	init_battle_ui(data)
	
	# Set player-specific stats
	current_mana = data.current_mana
	
	# Apply any temporary modifiers
	max_health = data.max_health
	current_health = data.current_health
	
	print("Player character initialized: ", data.character_name)

#TODO: add this function
func perform_basic_attack(target: Character):
	target.take_basic_attack_damage(turn_attack)
	can_attack = false

## Override take_basic_attack_damage to add player-specific effects
func take_basic_attack_damage(amount: int):
	super.take_basic_attack_damage(amount)
	
	# Add screen shake, damage effects, etc. here
	add_damage_effect()

func init_start_of_turn():
	can_attack = true
	turn_attack = 0
	current_block = 0

## Art functions
func add_damage_effect():
	"""Add visual/audio effects when player takes damage"""
	# TODO: Add screen shake, damage popup, sound effect
	print("Player took damage!")

# --- PlayerBattleUI ---

func init_battle_ui(data: PlayerData):
	# Find attack display component [ONLY RELEVANT TO PLAYERCHARACTER]
	
	# init base character stats
	init_character_stats(data)
	print("called initialize_character_stats on: ", self)
	
	init_character_ui_from_data(player_data.class_data)
	print("called initialize_character_ui on: ", self)
	
	# initialize player specific battle ui
	var attack_display = battle_ui.get_node_or_null("AttackDisplay")
	if attack_display:
		print("attack_display present")
		battle_ui.attack_display.position = data.attack_display_local_offset


## Player death is handled by the Global.character_died signal in BattleManager
