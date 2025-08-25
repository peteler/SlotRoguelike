# PlayerCharacter.gd 
class_name PlayerCharacter
extends Character

## parent vars
#@onready var sprite: Sprite2D = $Sprite2D
#@onready var collision_shape: CollisionShape2D = $CollisionShape2D
#@onready var stats_ui: Control = $StatsUI
#var max_health: int
#var current_health: int:
#var current_block: int = 0:

## Player-specific stats
var current_mana: int = 0:
	set(value):
		current_mana = max(0, value)
		Global.player_mana_updated.emit(current_mana)

var turn_attack: int = 0:
	set(value):
		turn_attack = value
		Global.player_character_attack_updated.emit(self, turn_attack)

## Player character data resource
@export var player_data: PlayerData

@onready var battle_ui: PlayerCharacterBattleUI = $PlayerCharacterBattleUI

## battle manager helper fields [should eventually be changed into a function if mechanic will be updated]
var can_attack: bool = false

## functions
func _ready():
	super._ready()  # Call Character._ready()
	
	# Add player to group for easy finding
	add_to_group("player_character")
	
	# Initialize from player data if available
	if player_data:
		initialize_from_player_data()
	else:
		push_error("Player has no PlayerData assigned!")

func initialize_from_player_data():
	"""Initialize player character from PlayerData resource"""
	# init base character stats
	init_character_battle_stats(player_data)
	# init battle_ui based on CharacterData
	init_character_battle_ui(player_data.class_data, battle_ui)
	
	# initialize player-specific battle ui
	var attack_display = battle_ui.get_node_or_null("AttackDisplay")
	if attack_display:
		print("attack_display present")
		battle_ui.attack_display.position = player_data.class_data.attack_display_local_offset
	
	# initialize player-specific stats
	current_mana = player_data.current_mana
	
	print("Player character initialized: ", player_data.character_name)

func perform_basic_attack(target: Character):
	target.take_basic_attack_damage(turn_attack)
	can_attack = false

## Override take_basic_attack_damage to add player-specific effects
func take_basic_attack_damage(amount: int):
	super.take_basic_attack_damage(amount)
	# Add screen shake, damage effects, etc. here
	add_damage_effect()

func call_on_start_of_player_turn():
	can_attack = true
	turn_attack = 0
	current_block = 0

## Art functions
func add_damage_effect():
	"""Add visual/audio effects when player takes damage"""
	# TODO: Add screen shake, damage popup, sound effect
	print("Player took damage!")
